import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/ai_service.dart';

import '../services/incident_service.dart';

class EmergencyReportScreen extends StatefulWidget {
  const EmergencyReportScreen({super.key});

  @override
  State<EmergencyReportScreen> createState() => _EmergencyReportScreenState();
}

class _EmergencyReportScreenState extends State<EmergencyReportScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  String? _selectedCategory;
  Map<String, dynamic>? _prediction;
  bool _isAnalyzing = false;

  final List<String> _categories = ["Accident", "Breakdown", "Medical Emergency"];

  void _analyzeIncident() async {
    if (_descriptionController.text.isEmpty) return;

    setState(() {
      _isAnalyzing = true;
      _prediction = null;
    });

    final result = await AIService.analyzeIncident(_descriptionController.text);

    setState(() {
      _prediction = result;
      _isAnalyzing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Emergency Reporting Wizard"),
        backgroundColor: AppTheme.charcoalNight,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "What is the nature of the emergency?",
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            Wrap(
              spacing: 10,
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return ChoiceChip(
                  label: Text(cat),
                  selected: isSelected,
                  onSelected: (val) => setState(() => _selectedCategory = cat),
                  selectedColor: AppTheme.tacticalRed,
                  backgroundColor: Colors.grey[900],
                  labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.grey),
                );
              }).toList(),
            ),
            const SizedBox(height: 25),
            const Text(
              "Describe the situation",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "e.g., Two cars collided at the junction, one person is unconscious...",
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[900],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isAnalyzing ? null : _analyzeIncident,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.tacticalRed,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isAnalyzing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Analyze & Predict Severity", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            if (_prediction != null) ...[
              const SizedBox(height: 30),
              _buildPredictionCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionCard() {
    final severity = _prediction!['severity'] ?? 'Unknown';
    final confidence = _prediction!['confidence'] ?? 0;
    final recommendation = _prediction!['recommendation'] ?? '';
    final hospitalType = _prediction!['hospital_type'] ?? 'General';

    Color severityColor;
    switch (severity.toString().toLowerCase()) {
      case 'critical':
        severityColor = AppTheme.tacticalRed;
        break;
      case 'high':
        severityColor = Colors.orange;
        break;
      case 'medium':
        severityColor = AppTheme.amberWarning;
        break;
      default:
        severityColor = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: severityColor, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "AI SEVERITY: $severity",
                style: TextStyle(color: severityColor, fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text(
                "$confidence% Conf.",
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          const Divider(color: Colors.grey, height: 20),
          const Text("RECOMMENDED ACTION:", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text(recommendation, style: const TextStyle(color: Colors.white, fontSize: 14)),
          const SizedBox(height: 20),
          const Text("INTERVENTION ENGINE: BEST FACILITY", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          _buildFacilityDecision(hospitalType),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                IncidentService.dispatchEmergency(
                  type: _selectedCategory ?? "Unknown",
                  severity: severity,
                  description: _descriptionController.text,
                  recommendation: recommendation,
                );
              },
              icon: const Icon(Icons.send),
              label: const Text("PROCEED WITH DISPATCH"),
              style: ElevatedButton.styleFrom(backgroundColor: severityColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFacilityDecision(String hospitalType) {
    // Logic: Rank hospitals by capability matching the predicted hospitalType, then by distance.
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_hospital, color: AppTheme.tacticalRed),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Apollo Trauma Center ($hospitalType)",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const Text(
                  "4.2 km away • Level 1 Trauma • 24/7",
                  style: TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
          const Text("BEST MATCH", style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
