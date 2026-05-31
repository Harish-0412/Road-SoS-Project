import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: AppTheme.charcoalNight,
      ),
      body: ListView(
        children: [
          _buildSectionHeader("Emergency Configuration"),
          _buildSettingTile(Icons.contacts, "Emergency Contacts", "Manage who to notify in SOS"),
          _buildSettingTile(Icons.medical_information, "My Medical Info", "Blood group, allergies, etc."),
          
          _buildSectionHeader("Offline Data Management"),
          _buildSettingTile(Icons.map, "Download Maps", "1.2 GB cached for offline use"),
          _buildSettingTile(Icons.storage, "Hospital & Mechanic Database", "Last updated: 2 days ago"),
          
          _buildSectionHeader("AI Preferences"),
          _buildSettingTile(Icons.psychology, "SLM Model Selection", "Current: Gemma-3 1B (Quantized)"),
          
          const SizedBox(height: 30),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              "RoadSoS v1.0.0-beta\nIIT Madras Road Safety Hackathon Edition",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(color: AppTheme.tacticalRed, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildSettingTile(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: () {},
    );
  }
}
