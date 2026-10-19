import 'package:latlong2/latlong.dart';

/// One event in a parcel's journey (status history).
class TrackingEvent {
  final String status;
  final String? label;
  final String? location;
  final DateTime? time;

  TrackingEvent({required this.status, this.label, this.location, this.time});

  factory TrackingEvent.fromJson(Map<String, dynamic> j) => TrackingEvent(
        status: '${j['status'] ?? ''}',
        label: j['label'] ?? j['description'] ?? j['message'],
        location: j['location'] ?? j['city'],
        time: DateTime.tryParse('${j['timestamp'] ?? j['time'] ?? j['created_at'] ?? ''}'),
      );
}

/// Full tracking payload: current live position + event history.
class TrackingInfo {
  final String status;
  final LatLng? current;
  final LatLng? origin;
  final LatLng? destination;
  final List<TrackingEvent> events;
  final String? etaText;

  TrackingInfo({
    required this.status,
    this.current,
    this.origin,
    this.destination,
    this.events = const [],
    this.etaText,
  });

  factory TrackingInfo.fromJson(Map<String, dynamic> j) {
    LatLng? pt(dynamic v) {
      if (v is Map) {
        final lat = double.tryParse('${v['lat'] ?? v['latitude']}');
        final lng = double.tryParse('${v['lng'] ?? v['longitude']}');
        if (lat != null && lng != null) return LatLng(lat, lng);
      }
      return null;
    }

    final rawEvents = (j['events'] ?? j['history'] ?? j['timeline'] ?? []) as List? ?? [];
    return TrackingInfo(
      status: '${j['status'] ?? 'in_transit'}',
      current: pt(j['current_location'] ?? j['current'] ?? j['location']),
      origin: pt(j['origin'] ?? j['pickup']),
      destination: pt(j['destination'] ?? j['drop']),
      etaText: j['eta'] ?? j['eta_text'] ?? j['estimated_delivery'],
      events: rawEvents
          .whereType<Map>()
          .map((e) => TrackingEvent.fromJson(e.cast<String, dynamic>()))
          .toList(),
    );
  }
}
