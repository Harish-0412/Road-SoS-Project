class LocationLog {
  final int? id;
  final double latitude;
  final double longitude;
  final double speed;
  final double heading;
  final double altitude;
  final double accuracy;
  final DateTime timestamp;

  LocationLog({
    this.id,
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.heading,
    required this.altitude,
    required this.accuracy,
    required this.timestamp,
  });

  // Convert a LocationLog into a Map to store in SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'speed': speed,
      'heading': heading,
      'altitude': altitude,
      'accuracy': accuracy,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  // Convert a Map from SQLite back into a LocationLog
  factory LocationLog.fromMap(Map<String, dynamic> map) {
    return LocationLog(
      id: map['id'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      speed: map['speed'],
      heading: map['heading'],
      altitude: map['altitude'],
      accuracy: map['accuracy'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}
