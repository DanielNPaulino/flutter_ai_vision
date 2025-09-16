import 'dart:io';
import 'package:flutter/material.dart';

class ResultScreen extends StatelessWidget {
  final File image;
  final String commonName;
  final String scientificName;
  final double confidence;
  final String description;
  final String habitat;
  final String diet;
  final String conservationStatus;
  final String? birdImageUrl;
  final String? localImagePath;

  const ResultScreen({
    Key? key,
    required this.image,
    required this.commonName,
    required this.scientificName,
    required this.confidence,
    required this.description,
    required this.habitat,
    required this.diet,
    required this.conservationStatus,
    this.birdImageUrl,
    this.localImagePath,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget birdImage;

    if (localImagePath != null && localImagePath!.isNotEmpty) {
      birdImage = Image.file(File(localImagePath!), fit: BoxFit.cover);
    } else if (birdImageUrl != null && birdImageUrl!.isNotEmpty) {
      birdImage = Image.network(
        birdImageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.broken_image, size: 150, color: Colors.grey),
      );
    } else {
      birdImage = const Icon(Icons.help_outline, size: 150, color: Colors.grey);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Bird Identification')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 250,
                width: double.infinity,
                child: birdImage,
              ),
            ),
            const SizedBox(height: 16),
            _infoCard("Common Name", commonName),
            _infoCard("Scientific Name", scientificName),
            _infoCard(
              "Confidence",
              "${(confidence * 100).toStringAsFixed(1)}%",
            ),
            _infoCard("Description", description),
            _infoCard("Habitat", habitat),
            _infoCard("Diet", diet),
            _infoCard("Conservation Status", conservationStatus),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(String title, String value) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: RichText(
          text: TextSpan(
            style: const TextStyle(color: Colors.black87, fontSize: 16),
            children: [
              TextSpan(
                text: "$title: ",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(text: value),
            ],
          ),
        ),
      ),
    );
  }
}
