import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import 'result_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File? _image;
  final ImagePicker _picker = ImagePicker();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _isLoading = true;
      });

      // Call AI service
      final result = await _apiService.identifyFeather(_image!);

      setState(() {
        _isLoading = false;
      });

      // Navigate to result screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultScreen(
            image: _image!,
            species: result['species'],
            confidence: result['confidence'],
            description: result['description'],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Bird Feather Identifier")),
      body: Center(
        child: _isLoading
            ? CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _image != null
                      ? Image.file(_image!, height: 200)
                      : Text("No image selected"),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => _pickImage(ImageSource.camera),
                    child: Text("Take Photo"),
                  ),
                  ElevatedButton(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    child: Text("Choose from Gallery"),
                  ),
                ],
              ),
      ),
    );
  }
}
