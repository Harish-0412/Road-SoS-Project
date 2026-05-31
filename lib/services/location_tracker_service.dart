import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'location_db_service.dart';
import '../models/location_log.dart';

class LocationTrackerService {
  StreamSubscription<Position>? _positionSubscription;
  final _locationController = StreamController<LocationLog>.broadcast();

  // Expose location update stream to UI widgets (speedometers, map indicators, etc.)
  Stream<LocationLog> get locationStream => _locationController.stream;

  bool get isTracking => _positionSubscription != null;

  // Start continuous location tracking
  Future<void> startTracking({
    int intervalSeconds = 3,       // Trigger frequency in seconds
    int distanceFilterMeters = 2,  // Trigger distance threshold in meters
  }) async {
    if (isTracking) return;

    // Verify location service is enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception("Location services are disabled on this device.");
    }

    // Check location permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception("Location permissions are denied.");
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception("Location permissions are permanently denied.");
    }

    // Configure Location Stream Settings
    final locationSettings = AndroidSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: distanceFilterMeters,
      intervalDuration: Duration(seconds: intervalSeconds),
      foregroundNotificationConfig: const ForegroundNotificationConfig(
        notificationText: "Road Safety SOS is tracking your telemetry in real-time.",
        notificationTitle: "Real-Time Tracking Active",
      ),
    );

    // Subscribe to Geolocator position stream
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) async {
      final log = LocationLog(
        latitude: position.latitude,
        longitude: position.longitude,
        speed: position.speed,          // meters per second
        heading: position.heading,      // degrees (true north)
        altitude: position.altitude,    // meters above sea level
        accuracy: position.accuracy,    // meters
        timestamp: position.timestamp,
      );

      // Auto-insert telemetry point into the local SQLite database
      await LocationDbService.instance.insertLocation(log);

      // Broadcast log to UI listeners
      _locationController.add(log);
    }, onError: (e) {
      _locationController.addError(e);
    });
  }

  // Stop tracking
  void stopTracking() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  void dispose() {
    stopTracking();
    _locationController.close();
  }
}
