import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  final String _apiKey =
      "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"; // TODO: Replace with env key later

  /// Identify the bird species based on feather image
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

    // ✅ Debugging
    print("Raw AI response: $aiText");

    if (aiText == null || aiText.isEmpty) {
      throw Exception("Empty content returned from OpenAI API.");
    }

    // ✅ Parse AI JSON response safely
    Map<String, dynamic> parsedJson;
    try {
      parsedJson = jsonDecode(aiText);
    } catch (e) {
      print("Failed to parse JSON: $aiText");
      throw Exception("Invalid JSON format returned by AI.");
    }

    final speciesName = parsedJson["species"] ?? "Unknown";

    // ✅ Get Wikipedia image
    final wikiImageUrl = await _fetchWikipediaImage(speciesName);

    return {
      "species": speciesName,
      "confidence": (parsedJson["confidence"] ?? 0.0).toDouble(),
      "description": parsedJson["description"] ?? "No description available",
      "imageUrl": wikiImageUrl,
    };
  }

  /// Fetch an image URL of the species from Wikipedia
  Future<String?> _fetchWikipediaImage(String species) async {
    if (species == "Unknown") return null;

    final query = Uri.encodeComponent(species);
    final url = Uri.parse(
      "https://en.wikipedia.org/w/api.php?action=query&titles=$query&prop=pageimages&format=json&pithumbsize=500",
    );

    try {
      final response = await http.get(url);
      final data = jsonDecode(response.body);

      final pages = data['query']?['pages'];
      if (pages == null) return null;

      // Extract the first page key dynamically
      final pageKey = pages.keys.first;
      final page = pages[pageKey];

      final thumbnail = page['thumbnail'];
      if (thumbnail != null && thumbnail['source'] != null) {
        return thumbnail['source'];
      } else {
        return null;
      }
    } catch (e) {
      print("Wikipedia image fetch error: $e");
      return null;
    }
  }
}
