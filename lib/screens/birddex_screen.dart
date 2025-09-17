import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'result_screen.dart';

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

class BirdDexScreen extends StatefulWidget {
  const BirdDexScreen({Key? key}) : super(key: key);

  @override
  _BirdDexScreenState createState() => _BirdDexScreenState();
}

class _BirdDexScreenState extends State<BirdDexScreen> {
  final Box birddexBox = Hive.box('birddex');

  String searchQuery = "";
  String filter = "All"; // All, Collected, Uncollected
  String sortOption = "Alphabetical"; // Alphabetical, Date Collected

  @override
  Widget build(BuildContext context) {
    // Merge static birds + collected data
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
        'dateIdentified': savedBird?['dateIdentified'],
      };
    }).toList();

    // 1️⃣ Filter by search
    List<Map<String, dynamic>> filteredBirds = mergedBirds.where((bird) {
      final searchLower = searchQuery.toLowerCase();
      return bird['commonName'].toLowerCase().contains(searchLower) ||
          bird['scientificName'].toLowerCase().contains(searchLower);
    }).toList();

    // 2️⃣ Filter by collected state
    if (filter == "Collected") {
      filteredBirds = filteredBirds
          .where((bird) => bird['collected'] == true)
          .toList();
    } else if (filter == "Uncollected") {
      filteredBirds = filteredBirds
          .where((bird) => bird['collected'] == false)
          .toList();
    }

    // 3️⃣ Sort the list
    if (sortOption == "Alphabetical") {
      filteredBirds.sort(
        (a, b) => a['commonName'].toLowerCase().compareTo(
          b['commonName'].toLowerCase(),
        ),
      );
    } else if (sortOption == "Date Collected") {
      filteredBirds.sort((a, b) {
        final dateA = a['dateIdentified'] != null
            ? DateTime.tryParse(a['dateIdentified'])
            : DateTime(1900);
        final dateB = b['dateIdentified'] != null
            ? DateTime.tryParse(b['dateIdentified'])
            : DateTime(1900);
        return dateB!.compareTo(dateA!);
      });
    }

    final collectedCount = mergedBirds
        .where((bird) => bird['collected'])
        .length;
    final totalCount = mergedBirds.length;

    return Scaffold(
      appBar: AppBar(title: const Text("BirdDex"), centerTitle: true),
      body: Column(
        children: [
          // Progress section
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                Text(
                  "$collectedCount / $totalCount collected",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: totalCount > 0 ? collectedCount / totalCount : 0,
                  backgroundColor: Colors.grey[300],
                  color: Colors.green,
                  minHeight: 8,
                ),
              ],
            ),
          ),

          // Search and Filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                // Search Bar
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Search birds...",
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),

                // Filter Dropdown
                DropdownButton<String>(
                  value: filter,
                  items: const [
                    DropdownMenuItem(value: "All", child: Text("All")),
                    DropdownMenuItem(
                      value: "Collected",
                      child: Text("Collected"),
                    ),
                    DropdownMenuItem(
                      value: "Uncollected",
                      child: Text("Uncollected"),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      filter = value!;
                    });
                  },
                ),
                const SizedBox(width: 8),

                // Sort Dropdown
                DropdownButton<String>(
                  value: sortOption,
                  items: const [
                    DropdownMenuItem(value: "Alphabetical", child: Text("A-Z")),
                    DropdownMenuItem(
                      value: "Date Collected",
                      child: Text("By Date"),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      sortOption = value!;
                    });
                  },
                ),
              ],
            ),
          ),

          // Grid of birds
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: filteredBirds.length,
              itemBuilder: (context, index) {
                final bird = filteredBirds[index];
                final collected = bird['collected'] as bool;

                return GestureDetector(
                  onTap: collected
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ResultScreen(
                                image: File(''),
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
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              const Icon(
                                                Icons.broken_image,
                                                size: 50,
                                              ),
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
          ),
        ],
      ),
    );
  }
}
