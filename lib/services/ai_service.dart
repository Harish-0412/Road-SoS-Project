import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  // Replace with actual API keys or move to a secure config file
  static const String _groqApiKey = 'YOUR_GROQ_API_KEY';
  static const String _geminiApiKey = 'YOUR_GEMINI_API_KEY';

  static const String _groqUrl = 'https://api.groq.com/openai/v1/chat/completions';
  static const String _geminiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

  /// Emergency Chat Assistant - Handles general queries and breakdown scenarios
  static Future<String> getAIResponse(String query) async {
    try {
      return await _callGroq(query);
    } catch (e) {
      print('Groq failed, trying Gemini...');
      try {
        return await _callGemini(query);
      } catch (e2) {
        print('Both APIs failed. Error 1: $e. Error 2: $e2');
        return _getLocalFallback(query);
      }
    }
  }

  /// Emergency Decision Engine & Severity Prediction
  /// Analyzes incident description and predicts severity + recommends action
  static Future<Map<String, dynamic>> analyzeIncident(String description) async {
    final prompt = """
    Analyze the following road incident description and provide a JSON response with:
    1. severity: (Low, Medium, High, Critical)
    2. confidence: (0-100)
    3. recommendation: (Immediate Action)
    4. hospital_type: (General, Trauma Center, Cardiac Center)

    Description: "$description"
    """;

    try {
      final response = await getAIResponse(prompt);
      // Attempt to parse JSON from response if possible, otherwise return structured fallback
      return _parseAIResponse(response);
    } catch (e) {
      return {
        'severity': 'Medium',
        'confidence': 50,
        'recommendation': 'Stay calm and wait for help.',
        'hospital_type': 'General'
      };
    }
  }

  static Future<String> _callGroq(String query) async {
    if (_groqApiKey == 'YOUR_GROQ_API_KEY') throw Exception('API key not set');

    print('Calling Groq API...');
    try {
      final response = await http.post(
        Uri.parse(_groqUrl),
        headers: {
          'Authorization': 'Bearer $_groqApiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'llama-3.1-70b-versatile',
          'messages': [
            {'role': 'system', 'content': 'You are a road safety and emergency intervention AI. Be concise and professional.'},
            {'role': 'user', 'content': query}
          ],
        }),
      ).timeout(const Duration(seconds: 10));

      print('Groq Response Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      }
      throw Exception('Groq API Error: ${response.statusCode} - ${response.body}');
    } catch (e) {
      print('Groq API Exception: $e');
      rethrow;
    }
  }

  static Future<String> _callGemini(String query) async {
    if (_geminiApiKey == 'YOUR_GEMINI_API_KEY') throw Exception('API key not set');

    print('Calling Gemini API...');
    try {
      final url = '$_geminiUrl?key=$_geminiApiKey';
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [{'text': query}]
            }
          ],
        }),
      ).timeout(const Duration(seconds: 10));

      print('Gemini Response Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates'][0]['content']['parts'][0]['text'];
      }
      throw Exception('Gemini API Error: ${response.statusCode} - ${response.body}');
    } catch (e) {
      print('Gemini API Exception: $e');
      rethrow;
    }
  }

  static String _getLocalFallback(String query) {
    query = query.toLowerCase();
    if (query.contains('bleeding')) {
      return "FIRST AID: Apply direct pressure to the wound with a clean cloth. Keep the limb elevated. Do not remove the cloth if it becomes soaked; add another on top.";
    } else if (query.contains('start')) {
      return "BREAKDOWN: Check if dashboard lights turn on. If yes, it might be the starter or fuel. If no, check battery terminals.";
    } else if (query.contains('accident')) {
      return "EMERGENCY: Check for consciousness. Do not move victims unless there is immediate danger (fire/explosion). Call 112/108.";
    }
    return "I am currently offline. Please check for nearby facilities or use the SOS button if this is a life-threatening emergency.";
  }

  static Map<String, dynamic> _parseAIResponse(String response) {
    try {
      // Basic regex to extract JSON-like structure if the AI didn't return pure JSON
      final jsonMatch = RegExp(r'\{.*\}', dotAll: true).stringMatch(response);
      if (jsonMatch != null) {
        return jsonDecode(jsonMatch);
      }
    } catch (_) {}
    
    // Default fallback if parsing fails
    return {
      'severity': 'Unknown',
      'confidence': 0,
      'recommendation': response,
      'hospital_type': 'General'
    };
  }
}
