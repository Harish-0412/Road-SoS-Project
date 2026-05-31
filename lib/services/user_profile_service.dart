import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class UserProfileService {
  static const String _keyName = 'user_name';
  static const String _keyPhone = 'user_phone';
  static const String _keyVehicle = 'user_vehicle';
  static const String _keyEmergencyContacts = 'emergency_contacts';
  static const String _keyTheme = 'user_theme';

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

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // Emergency Contacts Logic
  static Future<void> saveEmergencyContacts(List<EmergencyContact> contacts) async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = jsonEncode(contacts.map((e) => e.toJson()).toList());
    await prefs.setString(_keyEmergencyContacts, encodedData);
  }

  static Future<List<EmergencyContact>> getEmergencyContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final String? encodedData = prefs.getString(_keyEmergencyContacts);
    if (encodedData == null) return [];
    
    final List<dynamic> decodedData = jsonDecode(encodedData);
    return decodedData.map((e) => EmergencyContact.fromJson(e)).toList();
  }

  static Future<void> saveTheme(String theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTheme, theme);
  }

  static Future<String> getTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyTheme) ?? 'dark';
  }
}

class EmergencyContact {
  final String name;
  final String phone;
  final int priority; // 1, 2, or 3

  EmergencyContact({required this.name, required this.phone, required this.priority});

  Map<String, dynamic> toJson() => {
    'name': name,
    'phone': phone,
    'priority': priority,
  };

  factory EmergencyContact.fromJson(Map<String, dynamic> json) => EmergencyContact(
    name: json['name'],
    phone: json['phone'],
    priority: json['priority'],
  );
}
