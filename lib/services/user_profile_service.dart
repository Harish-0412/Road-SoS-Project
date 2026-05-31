import 'package:shared_preferences/shared_preferences.dart';

class UserProfileService {
  static const String _keyName = 'user_name';
  static const String _keyPhone = 'user_phone';
  static const String _keyVehicle = 'user_vehicle';

  static Future<void> saveProfile({
    required String name,
    required String phone,
    required String vehicle,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyName, name);
    await prefs.setString(_keyPhone, phone);
    await prefs.setString(_keyVehicle, vehicle);
  }

  static Future<Map<String, String>> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString(_keyName) ?? '',
      'phone': prefs.getString(_keyPhone) ?? '',
      'vehicle': prefs.getString(_keyVehicle) ?? '',
    };
  }

  static Future<bool> isProfileComplete() async {
    final profile = await getProfile();
    return profile['name']!.isNotEmpty && profile['phone']!.isNotEmpty;
  }
}
