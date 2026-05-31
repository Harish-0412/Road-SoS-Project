import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class FacilitiesScreen extends StatelessWidget {
  const FacilitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nearby Facilities"),
        backgroundColor: AppTheme.charcoalNight,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildFacilityCategory(context, "Hospitals", Icons.local_hospital, Colors.red),
          _buildFacilityCategory(context, "Police Stations", Icons.security, Colors.blue),
          _buildFacilityCategory(context, "Mechanics & Towing", Icons.build, Colors.orange),
          _buildFacilityCategory(context, "Fuel Stations", Icons.local_gas_station, Colors.green),
        ],
      ),
    );
  }

  Widget _buildFacilityCategory(BuildContext context, String title, IconData icon, Color color) {
    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: Icon(icon, color: color, size: 30),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: const Text("Search for nearest offline locations", style: TextStyle(color: Colors.grey)),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
        onTap: () {
          // Navigate to specific facility list
        },
      ),
    );
  }
}
