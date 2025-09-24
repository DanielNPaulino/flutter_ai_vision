import 'dart:convert';
import 'package:http/http.dart' as http;

class BirdAudioService {
  static const String _baseUrl = 'https://www.xeno-canto.org/api/2/recordings';

  /// Fetch the first available bird call audio URL by scientific name
  static Future<String?> fetchBirdCall(String scientificName) async {
    try {
      final query = Uri.encodeComponent(scientificName);
      final url = Uri.parse('$_baseUrl?query=$query');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['recordings'] != null && data['recordings'].isNotEmpty) {
          return data['recordings'][0]['file'];
        } else {
          return null; // No recordings found
        }
      } else {
        throw Exception('Failed to fetch audio: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching bird call: $e');
      return null;
    }
  }
}
