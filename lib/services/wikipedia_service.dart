import 'dart:convert';
import 'package:http/http.dart' as http;

class WikipediaService {
  Future<String?> fetchBirdImage(String speciesName) async {
    // Replace spaces with underscores for Wikipedia URLs
    final formattedName = speciesName.replaceAll(' ', '_');
    final url = Uri.parse(
      'https://en.wikipedia.org/api/rest_v1/page/summary/$formattedName',
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // Check if thumbnail exists
      if (data['thumbnail'] != null && data['thumbnail']['source'] != null) {
        return data['thumbnail']['source'];
      } else {
        return null; // No image found
      }
    } else {
      print('Wikipedia API error: ${response.statusCode}');
      return null;
    }
  }
}
