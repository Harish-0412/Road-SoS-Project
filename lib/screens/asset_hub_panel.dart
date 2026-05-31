import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AssetHubPanel extends StatelessWidget {
  const AssetHubPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.15,
      minChildSize: 0.15,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black54)],
          ),
          child: ListView(
            controller: scrollController,
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  "Nearby Emergency Assets",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 12),

              // Quick-Filter Chip Row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildFilterChip("🏥 Hospitals"),
                    _buildFilterChip("🚨 Police"),
                    _buildFilterChip("🛞 Towing"),
                    _buildFilterChip("🔧 Mechanics"),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Resource Cards (k-d Tree Output)
              _buildResourceCard(
                "City General Hospital",
                "0.8 km",
                "PTS: 9.8 (Critical Care)",
                Icons.local_hospital,
              ),
              _buildResourceCard(
                "Highway Patrol - Sector 4",
                "1.2 km",
                "PTS: 8.5 (Rapid Response)",
                Icons.security,
              ),
              _buildResourceCard(
                "24/7 Roadside Rescue",
                "2.5 km",
                "PTS: 7.2 (Mechanic)",
                Icons.build,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String label) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        onSelected: (bool selected) {},
        backgroundColor: Colors.grey[900],
        selectedColor: AppTheme.tacticalRed.withOpacity(0.3),
        labelStyle: const TextStyle(fontSize: 14),
      ),
    );
  }

  Widget _buildResourceCard(String title, String distance, String pts, IconData icon) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, color: AppTheme.tacticalRed, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text("$distance • $pts", style: const TextStyle(color: Colors.grey, fontSize: 14)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.map_outlined),
                    label: const Text("SHOW PATH"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white10,
                      minimumSize: const Size(0, 50),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.phone),
                    label: const Text("CALL"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      minimumSize: const Size(0, 50),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
