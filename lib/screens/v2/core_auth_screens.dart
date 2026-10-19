import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../core_api/action_key.dart';
import '../../core_api/format.dart';
import '../../core_api/models.dart';
import '../../core_api/session.dart';
import '../../widgets/common.dart';
import '../../widgets/v2/core_widgets.dart';

/// C1 — splash while the session is restored (`GET /me`).
class CoreSplashScreen extends StatelessWidget {
  const CoreSplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<CoreSession>();
    final error = session.bootstrapError;
    return Scaffold(
      backgroundColor: DropzyColors.bg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const DropzyIconTile(size: 84),
              const SizedBox(height: 20),
              const Text('Dropzy', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: DropzyColors.ink)),
              const SizedBox(height: 6),
              const Text(AppConfig.tagline, style: TextStyle(color: DropzyColors.inkSoft)),
              const SizedBox(height: 36),
              if (error == null)
                const CircularProgressIndicator(color: DropzyColors.primary)
              else ...[
                Text(error, textAlign: TextAlign.center, style: const TextStyle(color: DropzyColors.inkSoft)),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => context.read<CoreSession>().bootstrap(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try again'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: DropzyColors.primary,
                    side: const BorderSide(color: DropzyColors.primary),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// C2 — phone login (`POST /auth/otp/request`).
class CoreLoginScreen extends StatefulWidget {
  const CoreLoginScreen({super.key});
  @override
  State<CoreLoginScreen> createState() => _CoreLoginScreenState();
}

class _CoreLoginScreenState extends State<CoreLoginScreen> {
  final _phone = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _notice;

  @override
  void initState() {
    super.initState();
    _phone.addListener(() => setState(() => _error = null));
    _notice = context.read<CoreSession>().takeNotice();
  }

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  bool get _valid => isValidPhone(_phone.text);

  Future<void> _getOtp() async {
    if (!_valid || _loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    FocusScope.of(context).unfocus();
    final phone = _phone.text;
    try {
      final challenge = await context.read<CoreSession>().requestOtp(phone);
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => CoreOtpScreen(phone: phone, challenge: challenge),
      ));
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const DropzyIconTile(size: 72),
              const SizedBox(height: 28),
              const Text('Welcome to Dropzy',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: DropzyColors.ink)),
              const SizedBox(height: 8),
              const Text('Send parcels across cities', style: TextStyle(fontSize: 16, color: DropzyColors.inkSoft)),
              if (_notice != null) ...[
                const SizedBox(height: 20),
                TintCard(
                  color: DropzyColors.warning,
                  padding: const EdgeInsets.all(12),
                  child: Row(children: [
                    const Icon(Icons.lock_clock_rounded, color: DropzyColors.warning, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_notice!, style: const TextStyle(fontWeight: FontWeight.w600))),
                  ]),
                ),
              ],
              const SizedBox(height: 40),
              const Text('Mobile number',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: DropzyColors.ink)),
              const SizedBox(height: 10),
              TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _getOtp(),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(left: 18, right: 8),
                    child: Text('+91',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: DropzyColors.ink)),
                  ),
                  prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                  hintText: '10-digit mobile number',
                  errorText: _error,
                  errorMaxLines: 3,
                ),
              ),
              const SizedBox(height: 20),
              BusyButton(label: 'Get OTP', busy: _loading, onPressed: _valid ? _getOtp : null),
              const SizedBox(height: 40),
              const Center(
                child: Text('By continuing you agree to our Terms & Privacy Policy',
                    textAlign: TextAlign.center, style: TextStyle(color: DropzyColors.inkSoft, fontSize: 13)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// C3 — OTP verification with `codeLength` boxes and resend countdown.
class CoreOtpScreen extends StatefulWidget {
  const CoreOtpScreen({super.key, required this.phone, required this.challenge});
  final String phone;
  final OtpChallenge challenge;
  @override
  State<CoreOtpScreen> createState() => _CoreOtpScreenState();
}

class _CoreOtpScreenState extends State<CoreOtpScreen> {
  final _otp = TextEditingController();
  final _focus = FocusNode();
  late OtpChallenge _challenge = widget.challenge;
  bool _loading = false;
  bool _resending = false;
  String? _error;
  int _resendIn = 0;
  Timer? _timer;

  int get _len => _challenge.codeLength;

  @override
  void initState() {
    super.initState();
    _otp.addListener(() {
      setState(() {});
      if (_otp.text.length == _len && !_loading) _verify();
    });
    _startCountdown();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  void _startCountdown() {
    _timer?.cancel();
    _resendIn = _challenge.resendAfterSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _resendIn = _resendIn > 0 ? _resendIn - 1 : 0);
      if (_resendIn == 0) t.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otp.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_otp.text.length != _len || _loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<CoreSession>().verifyOtp(challenge: _challenge, phone: widget.phone, code: _otp.text);
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
      _otp.clear();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    setState(() {
      _resending = true;
      _error = null;
    });
    try {
      final c = await context.read<CoreSession>().requestOtp(widget.phone);
      if (!mounted) return;
      setState(() => _challenge = c);
      _otp.clear();
      _startCountdown();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final target = _challenge.phoneMasked ?? '+91 ${widget.phone}';
    return Scaffold(
      appBar: AppBar(title: const Text('Verify OTP')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Enter the $_len-digit code sent to $target',
                style: const TextStyle(fontSize: 16, color: DropzyColors.inkSoft)),
            const SizedBox(height: 28),
            Stack(children: [
              Opacity(
                opacity: 0,
                child: TextField(
                  controller: _otp,
                  focusNode: _focus,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(_len)],
                ),
              ),
              GestureDetector(
                onTap: () => _focus.requestFocus(),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_len, (i) {
                    final ch = i < _otp.text.length ? _otp.text[i] : '';
                    final active = i == _otp.text.length;
                    return Container(
                      key: ValueKey('otp-box-$i'),
                      width: _len > 4 ? 46 : 56,
                      height: 60,
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: DropzyColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: active ? DropzyColors.primary : DropzyColors.line, width: active ? 1.8 : 1),
                      ),
                      child: Text(ch, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                    );
                  }),
                ),
              ),
            ]),
            if (_error != null) ...[
              const SizedBox(height: 14),
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: DropzyColors.danger)),
            ],
            const SizedBox(height: 24),
            BusyButton(
              label: 'Verify & Continue',
              busy: _loading,
              onPressed: _otp.text.length == _len ? _verify : null,
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: (_resendIn > 0 || _resending || _loading) ? null : _resend,
                child: Text(_resendIn > 0 ? 'Resend OTP in $_resendIn s' : 'Resend OTP'),
              ),
            ),
            if (AppConfig.demoMode && _challenge.devCode != null)
              Center(
                child: Text('Demo: use code ${_challenge.devCode}',
                    style: const TextStyle(color: DropzyColors.inkSoft, fontSize: 12)),
              ),
          ],
        ),
      ),
    );
  }
}

/// First login (`isNewUser`) — ask for a name (`PATCH /me`).
class NamePromptScreen extends StatefulWidget {
  const NamePromptScreen({super.key});
  @override
  State<NamePromptScreen> createState() => _NamePromptScreenState();
}

class _NamePromptScreenState extends State<NamePromptScreen> {
  final _name = TextEditingController();
  final _key = ActionKey();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name.addListener(() {
      _key.reset();
      setState(() {});
    });
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    setState(() => _saving = true);
    try {
      await _key.run((k) => context.read<CoreSession>().saveName(name, idempotencyKey: k));
    } catch (e) {
      if (mounted) showApiError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const DropzyIconTile(size: 64),
              const SizedBox(height: 24),
              const Text('What should we call you?', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text('Your name is shown to drivers and on your bookings.',
                  style: TextStyle(color: DropzyColors.inkSoft)),
              const SizedBox(height: 28),
              TextField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                inputFormatters: [LengthLimitingTextInputFormatter(120)],
                decoration: const InputDecoration(hintText: 'Full name'),
                onSubmitted: (_) => _save(),
              ),
              const SizedBox(height: 20),
              BusyButton(label: 'Continue', busy: _saving, onPressed: _name.text.trim().isEmpty ? null : _save),
              TextButton(
                onPressed: _saving ? null : () => context.read<CoreSession>().skipNamePrompt(),
                child: const Text('Skip for now'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
