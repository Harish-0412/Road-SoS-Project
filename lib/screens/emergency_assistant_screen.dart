import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/ai_service.dart';

class EmergencyAssistantScreen extends StatefulWidget {
  const EmergencyAssistantScreen({super.key});

  @override
  State<EmergencyAssistantScreen> createState() => _EmergencyAssistantScreenState();
}

class _EmergencyAssistantScreenState extends State<EmergencyAssistantScreen> {
  final List<Map<String, String>> _messages = [];
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;

  void _sendQuery(String query) async {
    if (query.trim().isEmpty) return;

    setState(() {
      _messages.add({"role": "user", "content": query});
      _isLoading = true;
    });
    _controller.clear();

    try {
      final response = await AIService.getAIResponse(query);
      setState(() {
        _messages.add({"role": "ai", "content": response});
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add({"role": "ai", "content": "Error: Could not reach AI service. Please check your connection or try again later."});
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Emergency AI Assistant"),
        backgroundColor: AppTheme.charcoalNight,
        actions: const [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Icon(Icons.bolt, color: AppTheme.amberWarning),
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 4),
            color: AppTheme.amberWarning.withOpacity(0.2),
            child: const Center(
              child: Text(
                "Hybrid AI: Groq/Gemini (Cloud) + Local SLM Fallback",
                style: TextStyle(fontSize: 10, color: AppTheme.amberWarning),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg["role"] == "user";
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isUser ? AppTheme.tacticalRed : Colors.grey[900],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                    child: Text(
                      msg["content"]!,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(color: AppTheme.tacticalRed),
            ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Ask about first-aid or breakdown...",
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey[900],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    onSubmitted: _sendQuery,
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: AppTheme.tacticalRed,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: () => _sendQuery(_controller.text),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
