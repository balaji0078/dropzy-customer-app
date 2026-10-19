import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/api_client.dart';
import '../../widgets/scenery.dart';
import '../../widgets/v2/core_widgets.dart';
import 'core_app.dart';
import 'shipment_detail_v2.dart';

final RegExp dcnPattern = RegExp(r'^DCN-[A-Z]{3}-[A-Z]{3}-[0-9]{4}-[0-9]{6,}$');

/// Track tab — find one of my shipments by DCN (`GET /shipments/by-dcn/{dcn}`).
class CoreTrackScreen extends StatefulWidget {
  const CoreTrackScreen({super.key});
  @override
  State<CoreTrackScreen> createState() => _CoreTrackScreenState();
}

class _CoreTrackScreenState extends State<CoreTrackScreen> {
  final _controller = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _track() async {
    final dcn = _controller.text.trim().toUpperCase();
    if (!dcnPattern.hasMatch(dcn)) {
      setState(() => _error = 'Enter a DCN like DCN-MAA-BLR-2026-000123');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    FocusScope.of(context).unfocus();
    try {
      final s = await context.read<CoreServices>().api.shipmentByDcn(dcn);
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => ShipmentDetailV2(shipmentId: s.id)));
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _error = e.statusCode == 404 ? 'No shipment of yours found for “$dcn”.' : e.message);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DropzyHero(title: 'Track shipment', subtitle: 'Where’s your parcel right now?', height: 170),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              TextField(
                controller: _controller,
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _track(),
                decoration: InputDecoration(
                  hintText: 'Enter DCN e.g. DCN-MAA-BLR-2026-000123',
                  prefixIcon: const Icon(Icons.search_rounded),
                  errorText: _error,
                ),
              ),
              const SizedBox(height: 16),
              BusyButton(label: 'Track', busy: _loading, onPressed: _track),
            ]),
          ),
        ],
      ),
    );
  }
}
