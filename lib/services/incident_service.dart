import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

class IncidentService {
  /// Simulates or sends a priority dispatch via SMS/Data
  static Future<bool> dispatchEmergency({
    required String type,
    required String severity,
    required String description,
    required String recommendation,
  }) async {
    try {
      Position position = await Geolocator.getCurrentPosition();
      
      // Construct the emergency message
      final String message = """
🚨 ROAD EMERGENCY DISPATCH 🚨
TYPE: $type
SEVERITY: $severity
LOC: https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}
DESC: $description
AI REC: $recommendation
""";

      // In a real scenario, we'd use a dedicated SMS plugin for background sending.
      // For the hackathon demo, we'll use url_launcher to open the SMS app with the pre-filled message.
      final Uri smsUri = Uri(
        scheme: 'sms',
        path: '112', // Standard emergency number
        queryParameters: <String, String>{
          'body': message,
        },
      );

      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Specialized breakdown assistance logic
  static List<String> getTroubleshootingSteps(String issue) {
    switch (issue.toLowerCase()) {
      case 'battery failure':
        return [
          "Check for loose or corroded battery terminals.",
          "Try jump-starting if another vehicle is available.",
          "Check if headlights are dim (indicates low charge)."
        ];
      case 'engine failure':
        return [
          "Check fuel level indicator.",
          "Look for smoke or unusual smells.",
          "Do not attempt to restart if you hear loud knocking."
        ];
      case 'tire puncture':
        return [
          "Park on a flat surface away from traffic.",
          "Engage the parking brake.",
          "Use the jack and spare tire from the trunk."
        ];
      default:
        return ["Stay in your vehicle and wait for professional assistance."];
    }
  }
}
