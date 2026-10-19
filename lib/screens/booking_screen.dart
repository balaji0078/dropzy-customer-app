import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../state/services.dart';
import '../widgets/city_field.dart';
import 'shipment_detail_screen.dart';

const _packageTypes = ['PARCEL', 'DOCUMENT', 'ELECTRONICS', 'FRAGILE', 'CLOTHING'];

/// 6-step booking stepper matching the official app:
/// Sender → Receiver → Shipment → Route → Fare → Payment → POST /shipments.
class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key, this.prefillFrom, this.prefillTo});
  final String? prefillFrom;
  final String? prefillTo;

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  int _step = 0;
  bool _submitting = false;

  final _senderName = TextEditingController();
  final _senderMobile = TextEditingController();
  final _receiverName = TextEditingController();
  final _receiverMobile = TextEditingController();
  final _weight = TextEditingController(text: '1');
  final _quantity = TextEditingController(text: '1');
  late final _from = TextEditingController(text: widget.prefillFrom ?? '');
  late final _to = TextEditingController(text: widget.prefillTo ?? '');
  String _packageType = 'PARCEL';
  String _payment = 'COD';
  bool _fragile = false;
  XFile? _photo;

  Future<void> _capturePhoto() async {
    try {
      final img = await ImagePicker().pickImage(
        source: ImageSource.camera,
        maxWidth: 1280,
        imageQuality: 70,
      );
      if (img != null) setState(() => _photo = img);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open camera.')),
        );
      }
    }
  }

  @override
  void dispose() {
    for (final c in [
      _senderName, _senderMobile, _receiverName, _receiverMobile,
      _weight, _quantity, _from, _to,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  double get _fare {
    final w = double.tryParse(_weight.text) ?? 1;
    final base = 49 + w * 30;
    final gst = base * 0.18;
    return (base + gst).roundToDouble();
  }

  bool _stepValid(int s) {
    switch (s) {
      case 0:
        return _senderName.text.trim().isNotEmpty && _senderMobile.text.trim().length == 10;
      case 1:
        return _receiverName.text.trim().isNotEmpty && _receiverMobile.text.trim().length == 10;
      case 2:
        return (double.tryParse(_weight.text) ?? 0) > 0;
      case 3:
        return _from.text.trim().isNotEmpty && _to.text.trim().isNotEmpty;
      default:
        return true;
    }
  }

  void _next() {
    if (!_stepValid(_step)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete this step')),
      );
      return;
    }
    if (_step < 5) {
      setState(() => _step++);
    } else {
      _submit();
    }
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final body = {
      'sender_name': _senderName.text.trim(),
      'sender_mobile': _senderMobile.text.trim(),
      'receiver_name': _receiverName.text.trim(),
      'receiver_mobile': _receiverMobile.text.trim(),
      'package_type': _packageType,
      'weight_kg': double.tryParse(_weight.text) ?? 1,
      'declared_kg': double.tryParse(_weight.text) ?? 1,
      'quantity': int.tryParse(_quantity.text) ?? 1,
      'fragile': _fragile,
      'has_photo': _photo != null,
      'from_city': _from.text.trim(),
      'to_city': _to.text.trim(),
      'payment_method': _payment,
      'amount': _fare,
    };
    try {
      final shipment = await context.read<Services>().shipments.create(body);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Parcel booked successfully!')),
      );
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => ShipmentDetailScreen(shipment: shipment)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Booking failed: ${e.toString().replaceFirst('Exception: ', '')}')),
      );
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Book a parcel')),
      body: Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(primary: DropzyColors.primary),
        ),
        child: Stepper(
          currentStep: _step,
          type: StepperType.vertical,
          onStepTapped: (i) => setState(() => _step = i),
          onStepContinue: _next,
          onStepCancel: _step == 0 ? null : () => setState(() => _step--),
          controlsBuilder: (context, details) => Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _submitting ? null : details.onStepContinue,
                    child: _submitting && _step == 5
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                        : Text(_step == 5 ? 'Confirm & Pay' : 'Continue'),
                  ),
                ),
                if (_step > 0) ...[
                  const SizedBox(width: 12),
                  TextButton(onPressed: details.onStepCancel, child: const Text('Back')),
                ],
              ],
            ),
          ),
          steps: [
            _s('Sender', 0, [
              _field(_senderName, 'Sender name', cap: true),
              _field(_senderMobile, 'Sender mobile', phone: true),
            ]),
            _s('Receiver', 1, [
              _field(_receiverName, 'Receiver name', cap: true),
              _field(_receiverMobile, 'Receiver mobile', phone: true),
            ]),
            _s('Shipment', 2, [
              DropdownButtonFormField<String>(
                initialValue: _packageType,
                decoration: const InputDecoration(labelText: 'Package category'),
                items: _packageTypes
                    .map((t) => DropdownMenuItem(value: t, child: Text(t[0] + t.substring(1).toLowerCase())))
                    .toList(),
                onChanged: (v) => setState(() => _packageType = v ?? 'PARCEL'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _field(_weight, 'Weight (kg)', number: true)),
                  const SizedBox(width: 12),
                  Expanded(child: _field(_quantity, 'Quantity', number: true)),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeThumbColor: DropzyColors.primary,
                title: const Text('Fragile', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Handle with care', style: TextStyle(fontSize: 12)),
                value: _fragile,
                onChanged: (v) => setState(() => _fragile = v),
              ),
              const SizedBox(height: 4),
              _photoField(),
            ]),
            _s('Route', 3, [
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: CityField(controller: _from, hint: 'From city', prefixIcon: Icons.my_location_rounded),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: CityField(controller: _to, hint: 'To city', prefixIcon: Icons.place_outlined),
              ),
            ]),
            _s('Fare', 4, [
              _fareRow('Base + handling', '₹${(49 + (double.tryParse(_weight.text) ?? 1) * 30).round()}'),
              _fareRow('GST (18%)', 'incl.'),
              const Divider(height: 22),
              _fareRow('Total fare', '₹${_fare.round()}', bold: true),
            ]),
            _s('Payment', 5, [
              _payOption('COD', 'Cash on delivery', Icons.payments_outlined),
              const SizedBox(height: 10),
              _payOption('ONLINE', 'Pay online', Icons.credit_card_rounded),
            ]),
          ],
        ),
      ),
    );
  }

  Step _s(String title, int i, List<Widget> children) => Step(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        isActive: _step >= i,
        state: _step > i ? StepState.complete : StepState.indexed,
        content: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
      );

  Widget _field(TextEditingController c, String label,
      {bool cap = false, bool phone = false, bool number = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        keyboardType: phone
            ? TextInputType.phone
            : number
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.text,
        textCapitalization: cap ? TextCapitalization.words : TextCapitalization.none,
        inputFormatters: phone
            ? [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)]
            : number
                ? [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))]
                : null,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  Widget _photoField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Parcel photo', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        const SizedBox(height: 8),
        if (_photo == null)
          GestureDetector(
            onTap: _capturePhoto,
            child: Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: DropzyColors.bg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: DropzyColors.line, width: 1.5),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.photo_camera_rounded, color: DropzyColors.primary, size: 30),
                  SizedBox(height: 8),
                  Text('Take a photo of your parcel',
                      style: TextStyle(color: DropzyColors.inkSoft, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          )
        else
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.file(File(_photo!.path),
                    height: 160, width: double.infinity, fit: BoxFit.cover),
              ),
              Positioned(
                top: 8, right: 8,
                child: Material(
                  color: Colors.black54,
                  shape: const CircleBorder(),
                  child: IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
                    onPressed: _capturePhoto,
                    tooltip: 'Retake',
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _fareRow(String k, String v, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Text(k, style: TextStyle(color: bold ? DropzyColors.ink : DropzyColors.inkSoft, fontWeight: bold ? FontWeight.w800 : FontWeight.w400)),
            const Spacer(),
            Text(v, style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w600, color: bold ? DropzyColors.primary : DropzyColors.ink, fontSize: bold ? 18 : 14)),
          ],
        ),
      );

  Widget _payOption(String value, String label, IconData icon) {
    final sel = _payment == value;
    return GestureDetector(
      onTap: () => setState(() => _payment = value),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: sel ? DropzyColors.primaryTint : DropzyColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: sel ? DropzyColors.primary : DropzyColors.line),
        ),
        child: Row(
          children: [
            Icon(icon, color: sel ? DropzyColors.primary : DropzyColors.inkSoft),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: sel ? DropzyColors.primary : DropzyColors.ink)),
            const Spacer(),
            if (sel) const Icon(Icons.check_circle_rounded, color: DropzyColors.primary, size: 20),
          ],
        ),
      ),
    );
  }
}
