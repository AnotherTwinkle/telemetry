class TelemetryData {
  final int? id;
  final double? latitude;
  final double? longitude;
  final DateTime timestamp;
  final String? additionalData;

  TelemetryData({
    this.id,
    this.latitude,
    this.longitude,
    required this.timestamp,
    this.additionalData,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'additionalData': additionalData,
    };
  }

  factory TelemetryData.fromMap(Map<String, dynamic> map) {
    return TelemetryData(
      id: map['id'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      additionalData: map['additionalData'],
    );
  }
} 