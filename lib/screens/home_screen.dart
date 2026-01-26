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

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 85);
    if (picked != null) {
      setState(() {
        _image = File(picked.path);
        _isLoading = true;
      });

      try {
        print('🔍 Starting bird identification...');
        final result = await _apiService.identifyBird(_image!);
        print('✅ Bird identified successfully: ${result['common_name']}');
        
        setState(() => _isLoading = false);
        if (!mounted) return;

        // --- Save to Hive BirdDex ---
        final birddexBox = Hive.box('birddex');
        final birdKey = result['common_name'];
        birddexBox.put(birdKey, {
          'commonName': result['common_name'],
          'portugueseName': result['portuguese_name'] ?? '',
          'scientificName': result['scientific_name'],
          'imageUrl': result['imageUrl'],
          'localImagePath': _image!.path,
          'description': result['description'],
          'habitat': result['habitat'],
          'diet': result['diet'],
          'conservationStatus': result['conservation_status'],
          'confidence': result['confidence'],
          'collected': true,
          'dateIdentified': DateTime.now().toIso8601String(),
          'size': result['size'] ?? 'Unknown',
          'weight': result['weight'] ?? 'Unknown',
          'latitude': result['latitude'] ?? 0.0,
          'longitude': result['longitude'] ?? 0.0,
          'gltfModelUrl': result['gltfModelUrl'] ?? '',
        });
        // --- End save to Hive ---

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
              size: result['size'] ?? 'Unknown',
              weight: result['weight'] ?? 'Unknown',
            ),
          ),
        );
      } catch (e) {
        print('❌ Error identifying bird: $e');
        setState(() => _isLoading = false);
        if (!mounted) return;

        // Show error dialog to user
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Identification Failed'),
            content: Text(
              'Failed to identify the bird. Please check your internet connection and API key.\n\nError: $e',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter AI Vision'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFe0eafc), Color(0xFFcfdef3)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App logo or illustration
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: CircleAvatar(
                      radius: 56,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.camera_alt,
                        size: 56,
                        color: theme.primaryColor,
                      ),
                    ),
                  ),
                  Text(
                    "Welcome to Bird AI Vision",
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Identify birds instantly using AI, explore your BirdDex, and learn more about your sightings.",
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 32),
                  // Action cards
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 24,
                        horizontal: 16,
                      ),
                      child: Column(
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.camera_alt),
                            label: const Text("Identify from Camera"),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              textStyle: const TextStyle(fontSize: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _isLoading
                                ? null
                                : () => _pickImage(ImageSource.camera),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.photo_library),
                            label: const Text("Identify from Gallery"),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              textStyle: const TextStyle(fontSize: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _isLoading
                                ? null
                                : () => _pickImage(ImageSource.gallery),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.menu_book),
                            label: const Text("Open BirdDex"),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              textStyle: const TextStyle(fontSize: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: _isLoading
                                ? null
                                : () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const BirdDexScreen(),
                                      ),
                                    );
                                  },
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_isLoading) ...[
                    const SizedBox(height: 32),
                    const CircularProgressIndicator(),
                    const SizedBox(height: 8),
                    const Text("Identifying bird..."),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
