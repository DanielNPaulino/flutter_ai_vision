import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'result_screen.dart';
import 'dart:io';

final allBirds = [
  {
    'commonName': 'Great Egret',
    'scientificName': 'Ardea alba',
    'imageUrl':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/2/26/Great_Egret_%28Ardea_alba%29_in_Breeding_Plumage%2C_Cape_May_County%2C_New_Jersey%2C_USA.png/1280px-Great_Egret_%28Ardea_alba%29_in_Breeding_Plumage%2C_Cape_May_County%2C_New_Jersey%2C_USA.png',
  },
  {
    'commonName': 'Golden Eagle',
    'scientificName': 'Aquila chrysaetos',
    'imageUrl':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/c/cc/015_Wild_Golden_Eagle_in_flight_at_Pfyn-Finges_%28Switzerland%29_Photo_by_Giles_Laurent.jpg/800px-015_Wild_Golden_Eagle_in_flight_at_Pfyn-Finges_%28Switzerland%29_Photo_by_Giles_Laurent.jpg',
  },
  {
    'commonName': 'Bald Eagle',
    'scientificName': 'Haliaeetus leucocephalus',
    'imageUrl':
        'https://upload.wikimedia.org/wikipedia/commons/1/1e/Bald_Eagle_Portrait.jpg',
  },
  {
    'commonName': 'Budgerigar',
    'scientificName': 'Melopsittacus undulatus',
    'imageUrl':
        'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4a/Budgerigar-male-strzelecki-qld.jpg/1280px-Budgerigar-male-strzelecki-qld.jpg',
  },
];

class BirdDexScreen extends StatelessWidget {
  final Box birddexBox = Hive.box('birddex');

  BirdDexScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mergedBirds = allBirds.map((bird) {
      final collected = birddexBox.containsKey(bird['commonName']);
      final savedBird = collected ? birddexBox.get(bird['commonName']) : null;

      return {
        'commonName': bird['commonName'],
        'scientificName': bird['scientificName'],
        'imageUrl': bird['imageUrl'],
        'localImagePath': savedBird?['localImagePath'],
        'collected': collected,
        'confidence': savedBird?['confidence'] ?? 0.0,
        'description': savedBird?['description'] ?? '',
        'habitat': savedBird?['habitat'] ?? '',
        'diet': savedBird?['diet'] ?? '',
        'conservationStatus': savedBird?['conservationStatus'] ?? '',
      };
    }).toList();

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
        itemCount: mergedBirds.length,
        itemBuilder: (context, index) {
          final bird = mergedBirds[index];
          final collected = bird['collected'] as bool;

          return GestureDetector(
            onTap: collected
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ResultScreen(
                          image: File(''), // will use localImagePath or network
                          commonName: bird['commonName'],
                          scientificName: bird['scientificName'],
                          confidence: bird['confidence'],
                          description: bird['description'],
                          habitat: bird['habitat'],
                          diet: bird['diet'],
                          conservationStatus: bird['conservationStatus'],
                          birdImageUrl: bird['imageUrl'],
                          localImagePath: bird['localImagePath'],
                        ),
                      ),
                    );
                  }
                : null,
            child: Opacity(
              opacity: collected ? 1.0 : 0.4,
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                child: Column(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        child: collected && bird['localImagePath'] != null
                            ? Image.file(
                                File(bird['localImagePath']),
                                fit: BoxFit.cover,
                              )
                            : Image.network(
                                bird['imageUrl'],
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        collected ? bird['commonName'] : "???",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: collected ? Colors.black : Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
