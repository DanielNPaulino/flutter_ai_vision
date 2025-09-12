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
      "model": "gpt-4o-mini", // Vision-capable model
      "messages": [
        {
          "role": "system",
          "content":
              "You are an expert ornithologist. Identify the bird species based on a feather photo and provide a brief description.",
        },
        {
          "role": "user",
          "content": [
            {
              "type": "text",
              "text":
                  "Identify this bird species from its feather and provide confidence level (0-1).",
            },
            {
              "type": "image",
              "image_url": "data:image/jpeg;base64,$base64Image",
            },
          ],
        },
      ],
    });

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // Extract relevant text from the response
      final String aiText = data['choices'][0]['message']['content'];

      // We'll assume AI responds in a structured way, like:
      // "Species: European Goldfinch\nConfidence: 0.85\nDescription: ..."
      final species = _extractField(aiText, "Species");
      final confidence =
          double.tryParse(_extractField(aiText, "Confidence")) ?? 0.0;
      final description = _extractField(aiText, "Description");

      return {
        "species": species,
        "confidence": confidence,
        "description": description,
      };
    } else {
      throw Exception(
        "OpenAI API error: ${response.statusCode} - ${response.body}",
      );
    }
  }

  String _extractField(String text, String fieldName) {
    final regex = RegExp("$fieldName:\\s*(.*)", caseSensitive: false);
    final match = regex.firstMatch(text);
    return match != null ? match.group(1)!.trim() : "Unknown";
  }
}
