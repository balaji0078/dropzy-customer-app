import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/shipment.dart';
import '../state/services.dart';
import '../widgets/scenery.dart';
import '../widgets/shipment_tracking_view.dart';

/// Track tab — DCN search with the result card + timeline shown inline,
/// matching the official app's "Track shipment" page.
class TrackScreen extends StatefulWidget {
  const TrackScreen({super.key});
  @override
  State<TrackScreen> createState() => _TrackScreenState();
}

class _TrackScreenState extends State<TrackScreen> {
  final _controller = TextEditingController();
  bool _loading = false;
  String? _error;
  Shipment? _result;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _track() async {
    final id = _controller.text.trim();
    if (id.isEmpty) {
      setState(() => _error = 'Enter a shipment / DCN');
      return;
    }
    setState(() { _loading = true; _error = null; });
    FocusScope.of(context).unfocus();
    try {
      final s = await context.read<Services>().shipments.trackByDcn(id);
      if (s == null) {
        setState(() { _result = null; _error = 'No shipment found for “$id”.'; });
      } else {
        setState(() => _result = s);
      }
    } catch (_) {
      setState(() { _result = null; _error = 'No shipment found for “$id”.'; });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        top: false,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DropzyHero(
                title: 'Track shipment',
                subtitle: 'Where’s your parcel right now?',
                height: 170),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(children: [
            TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _track(),
              decoration: InputDecoration(
                hintText: 'Enter DCN e.g. DCN-CHE-BLR-2026-000123',
                prefixIcon: const Icon(Icons.search_rounded),
                errorText: _error,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loading ? null : _track,
              child: _loading
                  ? const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                  : const Text('Track'),
            ),
            if (_result != null) ...[
              const SizedBox(height: 24),
              ShipmentTrackingView(key: ValueKey(_result!.id), shipment: _result!),
            ],
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
