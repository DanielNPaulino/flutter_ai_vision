import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import 'result_screen.dart';
import 'birdDex_screen.dart';
import 'package:hive/hive.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File? _image;
  final ImagePicker _picker = ImagePicker();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  void _showCollectedAnimation(BuildContext context, String birdName) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.celebration, color: Colors.amber, size: 80),
              const SizedBox(height: 8),
              Text(
                "New Bird Collected!",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(birdName, style: TextStyle(fontSize: 18)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile == null) return;

      setState(() {
        _image = File(pickedFile.path);
        _isLoading = true;
      });

      final result = await _apiService.identifyBird(_image!);

      // Save to BirdDex
      final birddexBox = Hive.box('birddex');
      final birdKey = result['common_name'];

      // Save only if not already collected
      if (!birddexBox.containsKey(birdKey)) {
        birddexBox.put(birdKey, {
          'commonName': result['common_name'],
          'scientificName': result['scientific_name'],
          'imageUrl': result['imageUrl'], // Wikipedia URL if exists
          'localImagePath': _image!.path, // Local photo path
          'description': result['description'],
          'habitat': result['habitat'],
          'diet': result['diet'],
          'conservationStatus': result['conservation_status'],
          'confidence': result['confidence'],
          'collected': true,
          'dateIdentified': DateTime.now().toIso8601String(),
          'size': result['size'] ?? 'Unknown', // <-- Added
          'weight': result['weight'] ?? 'Unknown', // <-- Added
        });
      }

      // Show the animation for new bird
      _showCollectedAnimation(context, result['common_name']);

      setState(() {
        _isLoading = false;
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(
            image: _image!,
            birdImageUrl: result['imageUrl'],
            commonName: result['common_name'],
            scientificName: result['scientific_name'],
            confidence: result['confidence'],
            description: result['description'],
            habitat: result['habitat'],
            diet: result['diet'],
            conservationStatus: result['conservation_status'],
            size: result['size'], // <-- Added
            weight: result['weight'], // <-- Added
          ),
        ),
      );
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog(error.toString());
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Bird Identifier"), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: _isLoading
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text("Identifying bird..."),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_image != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                _image!,
                                height: 200,
                                fit: BoxFit.cover,
                              ),
                            )
                          else
                            const Text(
                              "No bird photo selected",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _actionButton(
                                icon: Icons.camera_alt,
                                label: "Take Photo",
                                onPressed: () => _pickImage(ImageSource.camera),
                              ),
                              const SizedBox(width: 16),
                              _actionButton(
                                icon: Icons.photo_library,
                                label: "Gallery",
                                onPressed: () =>
                                    _pickImage(ImageSource.gallery),
                              ),
                            ],
                          ),
                        ],
                      ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => BirdDexScreen()),
                );
              },
              icon: const Icon(Icons.book),
              label: const Text("BirdDex"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
