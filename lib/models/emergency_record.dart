class EmergencyRecord {
  final String emergencyId;
  final String userId;
  final double? latitude;
  final double? longitude;
  final double? accuracy;
  final int timestamp;
  final String alertType;
  final String? readableAddress;
  final String emergencyStatus; // 'DISPATCHED' | 'LOCATION_UNAVAILABLE' | 'RESOLVED'
  final String? googleMapsUrl;
  final int createdAt;

  EmergencyRecord({
    required this.emergencyId,
    required this.userId,
    this.latitude,
    this.longitude,
    this.accuracy,
    required this.timestamp,
    required this.alertType,
    this.readableAddress,
    required this.emergencyStatus,
    this.googleMapsUrl,
    required this.createdAt,
  });

  factory EmergencyRecord.fromJson(Map<String, dynamic> json) {
    return EmergencyRecord(
      emergencyId: json['emergency_id'] as String? ?? json['emergencyId'] as String? ?? '',
      userId: json['user_id'] as String? ?? json['userId'] as String? ?? 'user_default',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      accuracy: (json['accuracy'] as num?)?.toDouble(),
      timestamp: json['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      alertType: json['alert_type'] as String? ?? json['alertType'] as String? ?? 'POLICE',
      readableAddress: json['readable_address'] as String? ?? json['readableAddress'] as String?,
      emergencyStatus: json['emergency_status'] as String? ?? json['emergencyStatus'] as String? ?? 'DISPATCHED',
      googleMapsUrl: json['google_maps_url'] as String? ?? json['googleMapsUrl'] as String?,
      createdAt: json['created_at'] as int? ?? json['createdAt'] as int? ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'emergency_id': emergencyId,
      'user_id': userId,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'timestamp': timestamp,
      'alert_type': alertType,
      'readable_address': readableAddress,
      'emergency_status': emergencyStatus,
      'google_maps_url': googleMapsUrl,
      'created_at': createdAt,
    };
  }

  EmergencyRecord copyWith({
    String? readableAddress,
    String? emergencyStatus,
  }) {
    return EmergencyRecord(
      emergencyId: emergencyId,
      userId: userId,
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      timestamp: timestamp,
      alertType: alertType,
      readableAddress: readableAddress ?? this.readableAddress,
      emergencyStatus: emergencyStatus ?? this.emergencyStatus,
      googleMapsUrl: googleMapsUrl,
      createdAt: createdAt,
    );
  }
}
