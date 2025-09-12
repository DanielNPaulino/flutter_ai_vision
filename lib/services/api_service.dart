import 'dart:io';

class ApiService {
  // Simulated AI call (replace with real API/TFLite later)
  Future<Map<String, dynamic>> identifyFeather(File image) async {
    await Future.delayed(
      Duration(seconds: 2),
    ); // simulate network or processing delay

    // This is dummy data for testing
    return {
      "species": "Carduelis carduelis",
      "confidence": 0.92,
      "description":
          "European Goldfinch, a small colorful finch found in Europe.",
    };
  }
}
