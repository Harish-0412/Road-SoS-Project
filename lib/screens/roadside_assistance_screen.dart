import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/incident_service.dart';

class RoadsideAssistanceScreen extends StatefulWidget {
  const RoadsideAssistanceScreen({super.key});

  @override
  State<RoadsideAssistanceScreen> createState() => _RoadsideAssistanceScreenState();
}

class _RoadsideAssistanceScreenState extends State<RoadsideAssistanceScreen> {
  String? _selectedIssue;
  final List<String> _issues = [
    "Battery Failure",
    "Engine Failure",
    "Tire Puncture",
    "Fuel Exhaustion",
    "Overheating"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Roadside Assistance"),
        backgroundColor: AppTheme.charcoalNight,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "What seems to be the problem?",
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _issues.length,
              itemBuilder: (context, index) {
                final issue = _issues[index];
                final isSelected = _selectedIssue == issue;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIssue = issue),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.tacticalRed.withOpacity(0.2) : Colors.grey[900],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppTheme.tacticalRed : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getIconForIssue(issue),
                          color: isSelected ? AppTheme.tacticalRed : Colors.white,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          issue,
                          style: TextStyle(
                            color: isSelected ? AppTheme.tacticalRed : Colors.white,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        const Spacer(),
                        if (isSelected)
                          const Icon(Icons.check_circle, color: AppTheme.tacticalRed),
                      ],
                    ),
                  ),
                );
              },
            ),
            if (_selectedIssue != null) ...[
              const SizedBox(height: 30),
              _buildGuidedTroubleshooting(),
              const SizedBox(height: 30),
              _buildActionButtons(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGuidedTroubleshooting() {
    final steps = IncidentService.getTroubleshootingSteps(_selectedIssue!);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb, color: AppTheme.amberWarning),
              SizedBox(width: 10),
              Text(
                "AI GUIDED TROUBLESHOOTING",
                style: TextStyle(color: AppTheme.amberWarning, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(color: Colors.grey, height: 25),
          ...steps.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${entry.key + 1}. ",
                    style: const TextStyle(color: AppTheme.tacticalRed, fontWeight: FontWeight.bold),
                  ),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: const TextStyle(color: Colors.white, height: 1.4),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              // Navigate to Facilities with Mechanic filter
            },
            icon: const Icon(Icons.location_on),
            label: const Text("FIND NEAREST MECHANIC"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[800],
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              IncidentService.dispatchEmergency(
                type: "Breakdown",
                severity: "Medium",
                description: "Vehicle breakdown: $_selectedIssue",
                recommendation: "Requesting roadside assistance and towing.",
              );
            },
            icon: const Icon(Icons.emergency),
            label: const Text("REQUEST TOW TRUCK (SOS)"),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.tacticalRed,
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
          ),
        ),
      ],
    );
  }

  IconData _getIconForIssue(String issue) {
    switch (issue.toLowerCase()) {
      case 'battery failure':
        return Icons.battery_alert;
      case 'engine failure':
        return Icons.settings_input_component;
      case 'tire puncture':
        return Icons.tire_repair;
      case 'fuel exhaustion':
        return Icons.local_gas_station;
      case 'overheating':
        return Icons.thermostat;
      default:
        return Icons.help_outline;
    }
  }
}
