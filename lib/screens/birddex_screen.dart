import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:hive/hive.dart';
import 'result_screen.dart';

class BirdDexScreen extends StatefulWidget {
  const BirdDexScreen({Key? key}) : super(key: key);

  @override
  _BirdDexScreenState createState() => _BirdDexScreenState();
}

class _BirdDexScreenState extends State<BirdDexScreen> {
  final Box birddexBox = Hive.box('birddex');

  List<dynamic> allBirds = [];
  String searchQuery = "";
  String filter = "All"; // All, Collected, Uncollected
  String sortOption = "Alphabetical"; // Alphabetical, Date Collected
  String sizeFilter = "All"; // All, Small, Medium, Large
  String weightFilter = "All"; // All, Custom

  @override
  void initState() {
    super.initState();
    loadBirds();
  }

  Future<void> loadBirds() async {
    final jsonString = await rootBundle.loadString('assets/data/birds.json');
    setState(() {
      allBirds = jsonDecode(jsonString);
    });
  }

  @override
  Widget build(BuildContext context) {
    final hiveBirds = birddexBox.toMap().values.toList();

    final mergedBirds = [
      ...allBirds.map((bird) {
        final collected = birddexBox.containsKey(bird['commonName']);
        final savedBird = collected ? birddexBox.get(bird['commonName']) : null;

        return {
          'commonName': bird['commonName'],
          'scientificName': bird['scientificName'],
          'imageUrl': bird['imageUrl'],
          'size': bird['size'],
          'weight': bird['weight'],
          'localImagePath': savedBird?['localImagePath'],
          'collected': collected,
          'confidence': savedBird?['confidence'] ?? 0.0,
          'description': savedBird?['description'] ?? '',
          'habitat': savedBird?['habitat'] ?? bird['habitat'] ?? '',
          'diet': savedBird?['diet'] ?? bird['diet'] ?? '',
          'conservationStatus':
              savedBird?['conservationStatus'] ??
              bird['conservationStatus'] ??
              '',
          'dateIdentified': savedBird?['dateIdentified'],
        };
      }),
      ...hiveBirds
          .where(
            (bird) =>
                !allBirds.any((b) => b['commonName'] == bird['commonName']),
          )
          .map(
            (bird) => {
              'commonName': bird['commonName'],
              'scientificName': bird['scientificName'],
              'imageUrl': bird['imageUrl'] ?? bird['localImagePath'],
              'size': bird['size'] ?? '',
              'weight': bird['weight'] ?? '',
              'localImagePath': bird['localImagePath'],
              'collected': true,
              'confidence': bird['confidence'] ?? 0.0,
              'description': bird['description'] ?? '',
              'habitat': bird['habitat'] ?? '',
              'diet': bird['diet'] ?? '',
              'conservationStatus': bird['conservationStatus'] ?? '',
              'dateIdentified': bird['dateIdentified'],
            },
          ),
    ];

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

    // 3️⃣ Filter by size
    if (sizeFilter != "All") {
      filteredBirds = filteredBirds
          .where((bird) => bird['size'] == sizeFilter)
          .toList();
    }

    // 4️⃣ Filter by weight (example: show only birds heavier than 1kg)
    if (weightFilter == "Heavy (>1kg)") {
      filteredBirds = filteredBirds.where((bird) {
        final weightStr = bird['weight'] ?? '';
        // crude check: if weight contains "kg" and first number > 1
        final match = RegExp(r'(\d+(\.\d+)?)\s*kg').firstMatch(weightStr);
        if (match != null) {
          final weightVal = double.tryParse(match.group(1) ?? '0') ?? 0;
          return weightVal > 1.0;
        }
        return false;
      }).toList();
    }

    // 5️⃣ Sort the list
    if (sortOption == "Alphabetical") {
      filteredBirds.sort(
        (a, b) => a['commonName'].toLowerCase().compareTo(
          b['commonName'].toLowerCase(),
        ),
      );
    } else if (sortOption == "Date Collected") {
      filteredBirds.sort((a, b) {
        final dateA = a['dateIdentified'] != null
            ? DateTime.tryParse(a['dateIdentified']) ?? DateTime(1900)
            : DateTime(1900);
        final dateB = b['dateIdentified'] != null
            ? DateTime.tryParse(b['dateIdentified']) ?? DateTime(1900)
            : DateTime(1900);
        return dateB.compareTo(dateA);
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

          // --- Add filter dropdowns ---
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DropdownButton<String>(
                value: sizeFilter,
                items: ["All", "Small", "Medium", "Large"]
                    .map(
                      (s) =>
                          DropdownMenuItem(value: s, child: Text("Size: $s")),
                    )
                    .toList(),
                onChanged: (val) => setState(() => sizeFilter = val ?? "All"),
              ),
              DropdownButton<String>(
                value: weightFilter,
                items: ["All", "Heavy (>1kg)"]
                    .map(
                      (w) =>
                          DropdownMenuItem(value: w, child: Text("Weight: $w")),
                    )
                    .toList(),
                onChanged: (val) => setState(() => weightFilter = val ?? "All"),
              ),
            ],
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
                                size: bird['size'] ?? 'Unknown', // <-- Added
                                weight:
                                    bird['weight'] ?? 'Unknown', // <-- Added
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
                            child: Column(
                              children: [
                                Text(
                                  collected ? bird['commonName'] : "???",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: collected
                                        ? Colors.black
                                        : Colors.grey,
                                  ),
                                ),
                                if (collected) ...[
                                  Text(
                                    "Size: ${bird['size'] ?? 'Unknown'}",
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  Text(
                                    "Weight: ${bird['weight'] ?? 'Unknown'}",
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              ],
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
