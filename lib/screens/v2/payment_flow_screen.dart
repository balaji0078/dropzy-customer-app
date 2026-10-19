import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api_client.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../core_api/action_key.dart';
import '../../core_api/format.dart';
import '../../core_api/labels.dart';
import '../../core_api/models.dart';
import '../../core_api/payment_coordinator.dart';
import '../../core_api/poller.dart';
import '../../widgets/scenery.dart';
import '../../widgets/v2/core_widgets.dart';
import 'booking_confirmation_screen.dart';
import 'core_app.dart';

enum _Phase { checkout, verifying, failed, refunded }

/// Polling schedule for C10: every 3 s for the first 2 minutes, then 10 s.
Duration paymentPollInterval(Duration sinceVerifyingStarted) =>
    sinceVerifyingStarted < const Duration(minutes: 2) ? const Duration(seconds: 3) : const Duration(seconds: 10);

/// Opens the hosted checkout `{apiOrigin}{checkoutPath}`.
Future<bool> openCheckout(PaymentIntent intent) async {
  final path = intent.checkoutPath;
  if (path == null || path.isEmpty) return false;
  final uri = Uri.parse(path.startsWith('http') ? path : '${AppConfig.apiOrigin}$path');
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}

/// C9 (checkout) → C10 (verifying) in one route. Success is decided only by
/// `GET /payments/intents/{id}` (status SUCCEEDED) — never by the checkout
/// page, the return deep link or the user coming back to the app.
class PaymentFlowScreen extends StatefulWidget {
  const PaymentFlowScreen.checkout({super.key, required PaymentIntent this.intent, this.purpose, this.shipmentId})
      : intentId = null;

  /// Entered from `dropzy://payments/return` without an open flow.
  const PaymentFlowScreen.verifying({super.key, required String this.intentId, this.purpose, this.shipmentId})
      : intent = null;

  final PaymentIntent? intent;
  final String? intentId;
  final PaymentPurpose? purpose;
  final String? shipmentId;

  @override
  State<PaymentFlowScreen> createState() => _PaymentFlowScreenState();
}

class _PaymentFlowScreenState extends State<PaymentFlowScreen> with WidgetsBindingObserver {
  late final CoreServices _svc = context.read<CoreServices>();
  PaymentIntent? _intent;
  late _Phase _phase;
  DateTime _verifyingSince = DateTime.now();
  Poller? _poller;
  bool _leftApp = false;
  bool _refreshing = false;
  bool _retrying = false;
  Object? _loadError;
  final _refreshKey = ActionKey();
  final _retryKey = ActionKey();

  String get _intentId => _intent?.id ?? widget.intentId!;

  bool get _isBaseFare {
    final kind = _intent?.invoiceKind;
    if (kind != null) return kind == 'BASE_FARE';
    return widget.purpose != PaymentPurpose.surcharge;
  }

  String? get _shipmentId => _intent?.shipmentId ?? widget.shipmentId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _svc.payments.attach(_onReturn);
    _intent = widget.intent;
    if (widget.intent != null) {
      _phase = _Phase.checkout;
      _remember();
      WidgetsBinding.instance.addPostFrameCallback((_) => _launch());
    } else {
      _phase = _Phase.verifying;
      _startVerifying();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _svc.payments.detach(_onReturn);
    _poller?.stop();
    super.dispose();
  }

  void _remember() {
    final i = _intent;
    if (i == null) return;
    _svc.payments.pending = PendingPayment(
      intentId: i.id,
      purpose: _isBaseFare ? PaymentPurpose.baseFare : PaymentPurpose.surcharge,
      shipmentId: _shipmentId,
    );
  }

  /// Deep link `dropzy://payments/return[?intentId=]`.
  bool _onReturn(String? intentId) {
    if (intentId != null && _intent != null && intentId != _intent!.id) return false;
    if (_phase == _Phase.checkout) _startVerifying();
    return true;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      if (_phase == _Phase.checkout) _leftApp = true;
    } else if (state == AppLifecycleState.resumed && _phase == _Phase.checkout && _leftApp) {
      // App-resume fallback: back from checkout without a deep link →
      // re-check the pending intent with the server.
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted && _phase == _Phase.checkout) _startVerifying();
      });
    }
  }

  Future<void> _launch() async {
    final i = _intent;
    if (i == null) return;
    _leftApp = false;
    final ok = await openCheckout(i);
    if (!ok && mounted) {
      showToast(context, 'Could not open the payment page. Tap "Open payment page" to try again.');
    }
  }

  void _startVerifying() {
    _phase = _Phase.verifying;
    _verifyingSince = DateTime.now();
    if (mounted) setState(() {});
    _poller?.stop();
    _poller = Poller(
      task: _fetch,
      interval: () => paymentPollInterval(DateTime.now().difference(_verifyingSince)),
    )..start();
  }

  Future<void> _fetch() async {
    try {
      final i = await _svc.api.paymentIntent(_intentId);
      if (!mounted) return;
      setState(() {
        _intent = i;
        _loadError = null;
      });
      _apply(i);
    } catch (e) {
      if (mounted) setState(() => _loadError = e);
      rethrow;
    }
  }

  void _apply(PaymentIntent i) {
    if (i.status == 'SUCCEEDED') {
      _poller?.stop();
      _svc.payments.pending = null;
      if (_isBaseFare && _shipmentId != null) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => BookingConfirmationScreen(shipmentId: _shipmentId!),
        ));
      } else {
        showToast(context, 'Payment verified.');
        Navigator.of(context).pop(true);
      }
    } else if (intentFailedStatuses.contains(i.status)) {
      _poller?.stop();
      setState(() => _phase = _Phase.failed);
    } else if (intentRefundStatuses.contains(i.status)) {
      _poller?.stop();
      setState(() => _phase = _Phase.refunded);
    }
  }

  /// "I have paid" → ask the server to query the provider now.
  Future<void> _iHavePaid() async {
    setState(() => _refreshing = true);
    try {
      final i = await _refreshKey.run((k) => _svc.api.refreshPaymentIntent(_intentId, idempotencyKey: k));
      if (!mounted) return;
      setState(() => _intent = i);
      _apply(i);
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  /// "Try again" → a new intent for the same invoice (new user action → new key).
  Future<void> _tryAgain() async {
    final invoiceId = _intent?.invoiceId;
    if (invoiceId == null) return;
    setState(() => _retrying = true);
    try {
      final i = await _retryKey.run((k) => _svc.api.createPaymentIntent(invoiceId, idempotencyKey: k));
      if (!mounted) return;
      setState(() {
        _intent = i;
        _phase = _Phase.checkout;
      });
      _remember();
      await _launch();
    } on ApiException catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _retrying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final i = _intent;
    final pendingAtProvider = i != null && (i.status == 'REQUIRES_ACTION' || i.status == 'PENDING_PROVIDER');
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          DropzyHero(
            title: _phase == _Phase.checkout ? 'Secure payment' : 'Payment status',
            subtitle: i == null ? null : 'Amount ${formatInr(i.amountPaise)}',
            height: 170,
            overlay: IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.close_rounded, color: Colors.white),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              ..._body(i, pendingAtProvider),
            ]),
          ),
        ],
      ),
    );
  }

  List<Widget> _body(PaymentIntent? i, bool pendingAtProvider) {
    switch (_phase) {
      case _Phase.checkout:
        return [
          const _BigIcon(icon: Icons.lock_rounded, color: DropzyColors.primary),
          const SizedBox(height: 16),
          const Text('Complete payment in the secure page.',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text('Come back to Dropzy when you are done — we will check the payment with the bank.',
              textAlign: TextAlign.center, style: TextStyle(color: DropzyColors.inkSoft, height: 1.4)),
          const SizedBox(height: 24),
          BusyButton(label: 'Open payment page', icon: Icons.open_in_new_rounded, onPressed: _launch),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: _startVerifying,
            style: OutlinedButton.styleFrom(
              foregroundColor: DropzyColors.primary,
              side: const BorderSide(color: DropzyColors.primary),
              minimumSize: const Size.fromHeight(52),
            ),
            child: const Text('I have paid'),
          ),
        ];
      case _Phase.verifying:
        return [
          const SizedBox(height: 8),
          const Center(child: SizedBox(width: 56, height: 56, child: CircularProgressIndicator(color: DropzyColors.primary, strokeWidth: 4))),
          const SizedBox(height: 22),
          const Text(
            'Verifying your payment with the bank… This can take up to a minute. Do not pay again.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, height: 1.4),
          ),
          if (_loadError != null) ...[
            const SizedBox(height: 12),
            Text('${(_loadError is ApiException) ? (_loadError as ApiException).message : 'Connection problem.'} Retrying…',
                textAlign: TextAlign.center, style: const TextStyle(color: DropzyColors.warning, fontSize: 12.5)),
          ],
          const SizedBox(height: 24),
          BusyButton(label: 'I have paid', busy: _refreshing, onPressed: _iHavePaid),
          if (pendingAtProvider) ...[
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => openCheckout(i!),
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text('Open payment page'),
              style: OutlinedButton.styleFrom(
                foregroundColor: DropzyColors.primary,
                side: const BorderSide(color: DropzyColors.primary),
                minimumSize: const Size.fromHeight(52),
              ),
            ),
          ],
        ];
      case _Phase.failed:
        return [
          const _BigIcon(icon: Icons.error_outline_rounded, color: DropzyColors.danger),
          const SizedBox(height: 16),
          const Text('Payment not completed. You have not been charged.',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, height: 1.35)),
          if (i?.failureMessage != null) ...[
            const SizedBox(height: 8),
            Text(i!.failureMessage!, textAlign: TextAlign.center, style: const TextStyle(color: DropzyColors.inkSoft)),
          ],
          const SizedBox(height: 24),
          BusyButton(
            label: 'Try again',
            busy: _retrying,
            // Disabled while the provider may still complete the payment.
            onPressed: pendingAtProvider ? null : _tryAgain,
          ),
          TextButton(onPressed: () => Navigator.of(context).maybePop(), child: const Text('Back')),
        ];
      case _Phase.refunded:
        return [
          const _BigIcon(icon: Icons.undo_rounded, color: DropzyColors.info),
          const SizedBox(height: 16),
          const Text('This payment is being refunded to your original payment method.',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, height: 1.35)),
          const SizedBox(height: 24),
          BusyButton(label: 'Back', onPressed: () => Navigator.of(context).maybePop()),
        ];
    }
  }
}

class _BigIcon extends StatelessWidget {
  const _BigIcon({required this.icon, required this.color});
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.16), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 36),
        ),
      );
}
