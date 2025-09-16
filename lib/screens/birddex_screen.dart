import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'result_screen.dart';
import 'dart:io';

class BirdDexScreen extends StatelessWidget {
  final Box birddexBox = Hive.box('birddex');

  BirdDexScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final birdKeys = birddexBox.keys.toList();

    return Scaffold(
      appBar: AppBar(title: const Text("BirdDex")),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.8,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: birdKeys.length,
        itemBuilder: (context, index) {
          final key = birdKeys[index];
          final bird = birddexBox.get(key);
          final collected = bird['collected'] as bool? ?? false;

          return GestureDetector(
            onTap: collected
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ResultScreen(
                          image: File(''), // empty if using Wikipedia image
                          commonName: bird['commonName'],
                          scientificName: bird['scientificName'],
                          confidence: bird['confidence'],
                          description: bird['description'],
                          habitat: bird['habitat'],
                          diet: bird['diet'],
                          conservationStatus: bird['conservationStatus'],
                          birdImageUrl: bird['imageUrl'],
                        ),
                      ),
                    );
                  }
                : null,
            child: Container(
              decoration: BoxDecoration(
                color: collected ? Colors.white : Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
                boxShadow: collected
                    ? [BoxShadow(color: Colors.black26, blurRadius: 4)]
                    : [],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  collected && bird['imageUrl'] != null
                      ? Image.network(
                          bird['imageUrl'],
                          height: 100,
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.help_outline, size: 80),
                  const SizedBox(height: 8),
                  Text(
                    bird['commonName'],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: collected ? Colors.black : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
