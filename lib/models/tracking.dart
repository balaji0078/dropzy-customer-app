class TrackingUpdate {
  final String id;
  final String parcelId;
  final String status;
  final String location;
  final double lat;
  final double lng;
  final DateTime timestamp;
  final String description;

  TrackingUpdate({
    required this.id,
    required this.parcelId,
    required this.status,
    required this.location,
    required this.lat,
    required this.lng,
    required this.timestamp,
    required this.description,
  });

  factory TrackingUpdate.fromJson(Map<String, dynamic> json) {
    return TrackingUpdate(
      id: json['id'] as String? ?? '',
      parcelId: json['parcelId'] as String? ?? '',
      status: json['status'] as String? ?? '',
      location: json['location'] as String? ?? '',
      lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0.0,
      timestamp: json['timestamp'] is String
          ? DateTime.parse(json['timestamp'] as String)
          : (json['timestamp'] as DateTime?) ?? DateTime.now(),
      description: json['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'parcelId': parcelId,
      'status': status,
      'location': location,
      'lat': lat,
      'lng': lng,
      'timestamp': timestamp.toIso8601String(),
      'description': description,
    };
  }

  TrackingUpdate copyWith({
    String? id,
    String? parcelId,
    String? status,
    String? location,
    double? lat,
    double? lng,
    DateTime? timestamp,
    String? description,
  }) {
    return TrackingUpdate(
      id: id ?? this.id,
      parcelId: parcelId ?? this.parcelId,
      status: status ?? this.status,
      location: location ?? this.location,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      timestamp: timestamp ?? this.timestamp,
      description: description ?? this.description,
    );
  }
}
