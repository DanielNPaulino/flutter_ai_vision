import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import 'result_screen.dart';
import 'birddex_screen.dart'; // Import the BirdDex screen
import 'package:hive/hive.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File? _image;
  final ImagePicker _picker = ImagePicker();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile == null) return;

      setState(() {
        _image = File(pickedFile.path);
        _isLoading = true;
      });

      // Call AI + Wikipedia
      final result = await _apiService.identifyBird(_image!);

      // Inside _pickImage after AI result is received
      final birddexBox = Hive.box('birddex');
      final birdKey = result['common_name'];

      // Save only if not already collected
      if (!birddexBox.containsKey(birdKey)) {
        birddexBox.put(birdKey, {
          'commonName': result['common_name'],
          'scientificName': result['scientific_name'],
          'imageUrl': result['imageUrl'], // Wikipedia or local file
          'description': result['description'], // add description
          'habitat': result['habitat'], // add habitat
          'diet': result['diet'], // add diet
          'conservationStatus': result['conservation_status'], // add status
          'dateIdentified': DateTime.now().toIso8601String(),
          'collected': true,
          'confidence': result['confidence'], // store confidence too
        });
      }

      setState(() {
        _isLoading = false;
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultScreen(
            image: _image!,
            commonName: result['common_name'],
            scientificName: result['scientific_name'],
            confidence: result['confidence'],
            description: result['description'],
            habitat: result['habitat'],
            diet: result['diet'],
            conservationStatus: result['conservation_status'],
            birdImageUrl: result['imageUrl'],
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
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bird Identifier"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: 'Open BirdDex',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => BirdDexScreen()),
              );
            },
          ),
        ],
      ),
      body: Center(
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
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text("Take Bird Photo"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text("Choose from Gallery"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
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
}
