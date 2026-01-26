import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class BirdAudioService {
  static const String _baseUrl = 'https://xeno-canto.org/api/3/recordings';
  // Load API key from .env - users can get one from https://xeno-canto.org/account
  static String get _apiKey => dotenv.env['XENOCANTO_API_KEY'] ?? '';

  /// Fetch the first available bird call audio URL by scientific name
  static Future<String?> fetchBirdCall(String scientificName) async {
    // Check if API key is available
    if (_apiKey.isEmpty) {
      print('⚠️ Xeno-Canto API key not found in .env file');
      print('💡 Get your free API key from https://xeno-canto.org/account');
      print('💡 Add XENOCANTO_API_KEY=your_key to your .env file');
      return null;
    }
    
    try {
      // Xeno-Canto API v3 requires search tags and quotes for multi-word terms
      // Format: ?query=sp:"scientific name"&key=API_KEY
      final query = scientificName.trim();
      // Quote the scientific name for multi-word species
      final quotedQuery = 'sp:"$query"';
      final url = Uri.parse('$_baseUrl?query=$quotedQuery&key=$_apiKey');

      print('🔍 Fetching bird call for: $scientificName');
      print('🌐 API URL: $url');

      final response = await http.get(url);

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        print('📦 Response keys: ${data.keys.toList()}');
        print('🎵 Number of recordings: ${data['numRecordings']}');

        if (data['recordings'] != null && data['recordings'].isNotEmpty) {
          final firstRecording = data['recordings'][0];
          // The 'file' field contains the full URL to the MP3
          final audioUrl = firstRecording['file'];
          print('✅ Found bird call URL: $audioUrl');
          print('📝 Recording info: ${firstRecording['en']} - ${firstRecording['type']}');
          return audioUrl;
        } else {
          print('❌ No recordings found for: $scientificName');
          // Try with just genus name if full scientific name fails
          if (scientificName.contains(' ')) {
            final genus = scientificName.split(' ')[0];
            print('🔄 Retrying with genus only: $genus');
            return await _fetchByGenus(genus);
          }
          return null;
        }
      } else {
        print('⚠️ Failed to fetch audio: ${response.statusCode}');
        print('📄 Response body: ${response.body}');
        throw Exception('Failed to fetch audio: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching bird call: $e');
      return null;
    }
  }

  /// Fallback method to search by genus only
  static Future<String?> _fetchByGenus(String genus) async {
    try {
      final url = Uri.parse('$_baseUrl?query=gen:"$genus"&key=$_apiKey');
      print('🌐 Genus API URL: $url');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('🎵 Genus search - Number of recordings: ${data['numRecordings']}');

        if (data['recordings'] != null && data['recordings'].isNotEmpty) {
          final audioUrl = data['recordings'][0]['file'];
          print('✅ Found bird call (genus search): $audioUrl');
          return audioUrl;
        }
      }
      return null;
    } catch (e) {
      print('❌ Error in genus search: $e');
      return null;
    }
  }
}
