import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ApiService {
  final String _apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';

  /// Identify bird species with enriched data
  Future<Map<String, dynamic>> identifyBird(File imageFile) async {
    // Validate API key
    if (_apiKey.isEmpty) {
      print('❌ ERROR: OpenAI API key is empty!');
      throw Exception('OpenAI API key not found. Please check your .env file.');
    }
    
    print('📸 Processing image: ${imageFile.path}');
    
    final url = Uri.parse("https://api.openai.com/v1/chat/completions");

    final imageBytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(imageBytes);
    
    print('📦 Image encoded, size: ${imageBytes.length} bytes');

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
              "You are an expert ornithologist AI. Identify birds from photos. "
              "Respond ONLY in valid JSON:\n\n"
              "{\n"
              "  \"common_name\": \"<common name>\",\n"
              "  \"scientific_name\": \"<scientific name>\",\n"
              "  \"confidence\": <0-1>,\n"
              "  \"description\": \"<short description>\",\n"
              "  \"habitat\": \"<primary habitat>\",\n"
              "  \"diet\": \"<diet info>\",\n"
              "  \"conservation_status\": \"<IUCN status>\",\n"
              "  \"size\": \"<size: Small/Medium/Large>\",\n"
              "  \"weight\": \"<weight range, e.g. 70-100 g or 3-6.7 kg>\"\n"
              "}\n\nNo extra text.",
        },
        {
          "role": "user",
          "content": [
            {
              "type": "text",
              "text": "Identify this bird and provide enriched data as JSON.",
            },
            {
              "type": "image_url",
              "image_url": {"url": "data:image/jpeg;base64,$base64Image"},
            },
          ],
        },
      ],
    });

    print('🌐 Sending request to OpenAI API...');
    final response = await http.post(url, headers: headers, body: body);
    print('📡 Response received! Status: ${response.statusCode}');
    
    final data = jsonDecode(response.body);

    if (data['error'] != null) {
      final errorMessage = data['error']['message'] ?? "Unknown API error";
      print('❌ OpenAI API Error: $errorMessage');
      throw Exception(
        "OpenAI API error: ${response.statusCode} - $errorMessage",
      );
    }
    
    print('✅ API response parsed successfully');

    final String? aiText = data['choices'][0]['message']?['content'];
    if (aiText == null || aiText.isEmpty) {
      throw Exception("Empty content returned from OpenAI API.");
    }

    Map<String, dynamic> parsedJson;
    try {
      parsedJson = jsonDecode(aiText);
    } catch (e) {
      print("Failed to parse AI JSON: $aiText");
      throw Exception("Invalid JSON format returned by AI.");
    }

    final commonName = parsedJson["common_name"] ?? "Unknown";

    final wikiImageUrl = await _fetchWikipediaImage(commonName);

    return {
      "common_name": commonName,
      "scientific_name": parsedJson["scientific_name"] ?? "Unknown",
      "confidence": (parsedJson["confidence"] ?? 0.0).toDouble(),
      "description": parsedJson["description"] ?? "No description",
      "habitat": parsedJson["habitat"] ?? "Unknown",
      "diet": parsedJson["diet"] ?? "Unknown",
      "conservation_status": parsedJson["conservation_status"] ?? "Unknown",
      "size": parsedJson["size"] ?? "Unknown",
      "weight": parsedJson["weight"] ?? "Unknown",
      "imageUrl": wikiImageUrl,
    };
  }

  /// Wikipedia image fetch using search API
  Future<String?> _fetchWikipediaImage(String species) async {
    if (species == "Unknown") return null;

    try {
      final searchQuery = Uri.encodeComponent(species);
      final searchUrl = Uri.parse(
        "https://en.wikipedia.org/w/api.php?action=query&list=search&srsearch=$searchQuery&format=json",
      );

      final searchResponse = await http.get(searchUrl);
      final searchData = jsonDecode(searchResponse.body);

      final searchResults = searchData['query']?['search'];
      if (searchResults == null || searchResults.isEmpty) return null;

      final pageTitle = searchResults[0]['title'];
      if (pageTitle == null) return null;

      final titleQuery = Uri.encodeComponent(pageTitle);
      final imageUrl = Uri.parse(
        "https://en.wikipedia.org/w/api.php?action=query&titles=$titleQuery&prop=pageimages&format=json&pithumbsize=500",
      );

      final imageResponse = await http.get(imageUrl);
      final imageData = jsonDecode(imageResponse.body);
      final pages = imageData['query']?['pages'];
      if (pages == null) return null;

      final pageKey = pages.keys.first;
      final page = pages[pageKey];

      final thumbnail = page['thumbnail'];
      return (thumbnail != null && thumbnail['source'] != null)
          ? thumbnail['source']
          : null;
    } catch (e) {
      print("Wikipedia image fetch error: $e");
      return null;
    }
  }
}
