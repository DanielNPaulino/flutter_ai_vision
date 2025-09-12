import 'dart:io';
import 'package:flutter/material.dart';

class ResultScreen extends StatelessWidget {
  final File image;
  final String species;
  final double confidence;
  final String description;

  const ResultScreen({
    Key? key,
    required this.image,
    required this.species,
    required this.confidence,
    required this.description,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Identification Result')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Image.file(image, height: 250),
            SizedBox(height: 20),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Species: $species',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Confidence: ${(confidence * 100).toStringAsFixed(1)}%',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Description: $description',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            Spacer(),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Back'),
            ),
          ],
        ),
      ),
    );
  }
}
