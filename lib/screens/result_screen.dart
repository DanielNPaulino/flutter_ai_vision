import 'dart:io';
import 'package:flutter/material.dart';

class ResultScreen extends StatefulWidget {
  final File image;
  final String commonName;
  final String scientificName;
  final double confidence;
  final String description;
  final String habitat;
  final String diet;
  final String conservationStatus;
  final String? birdImageUrl;

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
  }) : super(key: key);

  @override
  _ResultScreenState createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _infoCard(String title, String value) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: RichText(
            text: TextSpan(
              style: TextStyle(color: Colors.black87, fontSize: 16),
              children: [
                TextSpan(
                  text: "$title: ",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Bird Identification')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (widget.birdImageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(widget.birdImageUrl!),
              ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(widget.image, height: 250, fit: BoxFit.cover),
            ),
            const SizedBox(height: 16),
            _infoCard("Common Name", widget.commonName),
            _infoCard("Scientific Name", widget.scientificName),
            _infoCard(
              "Confidence",
              "${(widget.confidence * 100).toStringAsFixed(1)}%",
            ),
            _infoCard("Description", widget.description),
            _infoCard("Habitat", widget.habitat),
            _infoCard("Diet", widget.diet),
            _infoCard("Conservation Status", widget.conservationStatus),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Back'),
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
