import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  final String _apiKey =
      "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"; // Replace with your key

  Future<Map<String, dynamic>> identifyFeather(File imageFile) async {
    final url = Uri.parse("https://api.openai.com/v1/chat/completions");

    final imageBytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(imageBytes);

    final headers = {
      "Content-Type": "application/json",
      "Authorization": "Bearer $_apiKey",
    };

    final body = jsonEncode({
      "model": "gpt-4o-mini",
      "messages": [
        {
          "role": "system",
          "content":
              "You are an expert ornithologist AI that identifies birds from feather photos. "
              "You must ONLY respond in valid JSON with this exact format:\n\n"
              "{\n"
              "  \"species\": \"<name of species>\",\n"
              "  \"confidence\": <number between 0 and 1>,\n"
              "  \"description\": \"<short description of the species>\"\n"
              "}\n\nNo extra text or explanation.",
        },
        {
          "role": "user",
          "content": [
            {
              "type": "text",
              "text":
                  "Identify this bird species from its feather and provide confidence level and description.",
            },
            {
              "type": "image_url",
              "image_url": {"url": "data:image/jpeg;base64,$base64Image"},
            },
          ],
        },
      ],
    });

    final response = await http.post(url, headers: headers, body: body);

    final data = jsonDecode(response.body);

    // ✅ Handle errors
    if (data['error'] != null) {
      final errorMessage = data['error']['message'] ?? "Unknown API error";
      throw Exception(
        "OpenAI API error: ${response.statusCode} - $errorMessage",
      );
    }

    if (data['choices'] == null || data['choices'].isEmpty) {
      throw Exception("No choices returned from OpenAI API.");
    }

    final String? aiText = data['choices'][0]['message']?['content'];

    // ✅ Add debugging print here
    print("Raw AI response: $aiText");

    if (aiText == null || aiText.isEmpty) {
      throw Exception("Empty content returned from OpenAI API.");
    }

    // ✅ Parse JSON safely
    try {
      final parsedJson = jsonDecode(aiText);

      return {
        "species": parsedJson["species"] ?? "Unknown",
        "confidence": (parsedJson["confidence"] ?? 0.0).toDouble(),
        "description": parsedJson["description"] ?? "No description available",
      };
    } catch (e) {
      print("Failed to parse JSON: $aiText");
      throw Exception("Invalid JSON format returned by AI");
    }
  }

  String _extractField(String text, String fieldName) {
    final regex = RegExp("$fieldName:\\s*(.*)", caseSensitive: false);
    final match = regex.firstMatch(text);
    return match != null ? match.group(1)!.trim() : "Unknown";
  }
}
