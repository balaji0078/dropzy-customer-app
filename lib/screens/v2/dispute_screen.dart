import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../core_api/action_key.dart';
import '../../core_api/labels.dart';
import '../../widgets/scenery.dart';
import '../../widgets/v2/core_widgets.dart';
import '../../widgets/v2/photo_picker.dart';
import 'core_app.dart';

/// Success copy for C13.
String disputeCreatedCopy(String? caseNumber, String quoteStatus) {
  final ref = caseNumber ?? 'case';
  if (quoteStatus == 'PAID') {
    return 'Dispute $ref created. We will review and refund any excess to your original payment method.';
  }
  return 'Dispute $ref created. Your parcel stays on hold until we review it; you can still pay to avoid delay.';
}

/// C13 — dispute an extra weight charge.
class DisputeScreen extends StatefulWidget {
  const DisputeScreen({super.key, required this.shipmentId, required this.quoteId, required this.quoteStatus, this.dcn});
  final String shipmentId;
  final String quoteId;
  final String quoteStatus;
  final String? dcn;
  @override
  State<DisputeScreen> createState() => _DisputeScreenState();
}

class _DisputeScreenState extends State<DisputeScreen> {
  static const _maxPhotos = 5;
  late final CoreServices _svc = context.read<CoreServices>();
  final _description = TextEditingController();
  final _submitKey = ActionKey();
  final List<PickedPhoto> _photos = [];
  String? _reason;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _description.addListener(() {
      _submitKey.reset();
      setState(() {});
    });
  }

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  bool get _valid => _reason != null && _description.text.trim().length >= 10;

  Future<void> _addPhoto() async {
    final p = await pickPhoto(context);
    if (p == null || !mounted) return;
    setState(() {
      _photos.add(p);
      _submitKey.reset();
    });
  }

  Future<void> _submit() async {
    if (!_valid || _submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      for (final p in _photos) {
        if (p.evidenceId != null) continue;
        final ev = await _svc.api.uploadEvidence(
          bytes: p.bytes,
          filename: p.filename,
          contentType: p.contentType,
          kind: 'DISPUTE_ATTACHMENT',
          shipmentId: widget.shipmentId,
          capturedAt: p.capturedAt,
          idempotencyKey: p.uploadKey,
        );
        p.evidenceId = ev.id;
      }
      final dispute = await _submitKey.run((k) => _svc.api.openDispute(
            widget.shipmentId,
            quoteId: widget.quoteId,
            reasonCode: _reason!,
            description: _description.text.trim(),
            evidenceIds: _photos.map((p) => p.evidenceId!).toList(),
            idempotencyKey: k,
          ));
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Dispute created'),
          content: Text(disputeCreatedCopy(dispute.caseNumber, widget.quoteStatus)),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
        ),
      );
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final len = _description.text.trim().length;
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          DropzyHero(
            title: 'Dispute this charge',
            subtitle: widget.dcn,
            height: 160,
            overlay: IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.close_rounded, color: Colors.white),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const SectionTitle('What is wrong?'),
              RadioGroup<String>(
                groupValue: _reason,
                onChanged: (v) => setState(() {
                  _reason = v;
                  _submitKey.reset();
                }),
                child: Column(children: [
                  for (final r in disputeReasons)
                    RadioListTile<String>(
                      value: r.$1,
                      title: Text(r.$2),
                      contentPadding: EdgeInsets.zero,
                      activeColor: DropzyColors.primary,
                    ),
                ]),
              ),
              const SizedBox(height: 12),
              const SectionTitle('Tell us more'),
              TextField(
                controller: _description,
                minLines: 4,
                maxLines: 8,
                inputFormatters: [LengthLimitingTextInputFormatter(2000)],
                decoration: InputDecoration(
                  hintText: 'Describe the problem (at least 10 characters)',
                  helperText: len < 10 ? '${10 - len} more characters needed' : '$len / 2000',
                ),
              ),
              const SizedBox(height: 20),
              SectionTitle('Photos (optional, up to $_maxPhotos)'),
              PhotoStrip(
                photos: _photos,
                max: _maxPhotos,
                onAdd: _submitting ? null : _addPhoto,
                onRemove: _submitting
                    ? null
                    : (i) => setState(() {
                          _photos.removeAt(i);
                          _submitKey.reset();
                        }),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                TintCard(color: DropzyColors.danger, child: Text(_error!)),
              ],
              const SizedBox(height: 24),
              BusyButton(label: 'Submit dispute', busy: _submitting, onPressed: _valid ? _submit : null),
            ]),
          ),
        ],
      ),
    );
  }
}
