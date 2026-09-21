import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:hive/hive.dart';
import '../utils/weight_parser.dart';
import 'result_screen.dart';

class BirdDexScreen extends StatefulWidget {
  const BirdDexScreen({Key? key}) : super(key: key);

  @override
  _BirdDexScreenState createState() => _BirdDexScreenState();
}

class _BirdDexScreenState extends State<BirdDexScreen>
    with SingleTickerProviderStateMixin {
  final Box birddexBox = Hive.box('birddex');
  final Box favoritesBox = Hive.box('favorites');

  List<dynamic> allBirds = [];
  String searchQuery = "";
  String filter = "All"; // All, Collected, Uncollected
  String sortOption = "Alphabetical"; // Alphabetical, Date Collected, Weight
  String sizeFilter = "All"; // All, Small, Medium, Large

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

    /// Merge JSON birds with collected Hive data
    final mergedBirds = [
      ...allBirds.map((bird) {
        final collected = birddexBox.containsKey(bird['commonName']);
        final savedBird = collected ? birddexBox.get(bird['commonName']) : null;
        final isFavorite = favoritesBox.get(bird['scientificName'], defaultValue: false);

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
          'isFavorite': isFavorite,
        };
      }),
      ...hiveBirds
          .where(
            (bird) =>
                !allBirds.any((b) => b['commonName'] == bird['commonName']),
          )
          .map(
            (bird) {
              final isFavorite = favoritesBox.get(bird['scientificName'], defaultValue: false);
              return {
                'commonName': bird['commonName'] ?? 'Unknown',
                'scientificName': bird['scientificName'] ?? 'Unknown',
                'imageUrl': bird['imageUrl'] ?? bird['localImagePath'] ?? '',
                'size': (bird['size'] is String && bird['size']!.isNotEmpty)
                    ? bird['size']
                    : 'Unknown',
                'weight': (bird['weight'] is String && bird['weight']!.isNotEmpty)
                    ? bird['weight']
                    : 'Unknown',
                'localImagePath': bird['localImagePath'],
                'collected': true,
                'confidence': bird['confidence'] ?? 0.0,
                'description': bird['description'] ?? '',
                'habitat': bird['habitat'] ?? '',
                'diet': bird['diet'] ?? '',
                'conservationStatus': bird['conservationStatus'] ?? '',
                'dateIdentified': bird['dateIdentified'],
                'isFavorite': isFavorite,
              };
            },
          ),
    ];

    // Filter by search
    List<Map<String, dynamic>> filteredBirds = mergedBirds.where((bird) {
      final searchLower = searchQuery.toLowerCase();
      return bird['commonName'].toLowerCase().contains(searchLower) ||
          bird['scientificName'].toLowerCase().contains(searchLower);
    }).toList();

    // Filter by collected state
    if (filter == "Collected") {
      filteredBirds = filteredBirds
          .where((bird) => bird['collected'] == true)
          .toList();
    } else if (filter == "Uncollected") {
      filteredBirds = filteredBirds
          .where((bird) => bird['collected'] == false)
          .toList();
    } else if (filter == 'Favorites') {
      filteredBirds = filteredBirds.where((bird) => bird['isFavorite'] == true).toList();
    }

    // Filter by size
    if (sizeFilter != "All") {
      filteredBirds = filteredBirds
          .where((bird) => bird['size'] == sizeFilter)
          .toList();
    }

    // Sorting
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
    } else if (sortOption == "Weight") {
      filteredBirds.sort((a, b) {
        final weightA = parseWeightKg(a['weight']);
        final weightB = parseWeightKg(b['weight']);
        return weightB.compareTo(weightA);
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

          // Filters and Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Bar
                TextField(
                  decoration: InputDecoration(
                    hintText: "Search birds...",
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 0,
                      horizontal: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                    });
                  },
                ),

                const SizedBox(height: 12),

                // Collected Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(
                        "All",
                        filter == "All",
                        () => setState(() => filter = "All"),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        "Collected",
                        filter == "Collected",
                        () => setState(() => filter = "Collected"),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        "Uncollected",
                        filter == "Uncollected",
                        () => setState(() => filter = "Uncollected"),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        "Favorites",
                        filter == "Favorites",
                        () => setState(() => filter = filter == "Favorites" ? "All" : "Favorites"),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Size Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(
                        "All Sizes",
                        sizeFilter == "All",
                        () => setState(() => sizeFilter = "All"),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        "Small",
                        sizeFilter == "Small",
                        () => setState(() => sizeFilter = "Small"),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        "Medium",
                        sizeFilter == "Medium",
                        () => setState(() => sizeFilter = "Medium"),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        "Large",
                        sizeFilter == "Large",
                        () => setState(() => sizeFilter = "Large"),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Sort Option Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildSortChip(
                        "A-Z",
                        sortOption == "Alphabetical",
                        () => setState(() => sortOption = "Alphabetical"),
                      ),
                      const SizedBox(width: 8),
                      _buildSortChip(
                        "Date",
                        sortOption == "Date Collected",
                        () => setState(() => sortOption = "Date Collected"),
                      ),
                      const SizedBox(width: 8),
                      _buildSortChip(
                        "Weight",
                        sortOption == "Weight",
                        () => setState(() => sortOption = "Weight"),
                      ),
                    ],
                  ),
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
                                size: bird['size'] ?? 'Unknown',
                                weight: bird['weight'] ?? 'Unknown',
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
                      child: Stack(
                        children: [
                          Column(
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
                          if (bird['isFavorite'] == true)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Icon(Icons.favorite, color: Colors.redAccent, size: 24),
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

  /// --- Helper Widgets for Chips ---
  Widget _buildFilterChip(
    String label,
    bool isSelected,
    VoidCallback onSelected,
  ) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: Colors.green[400],
      backgroundColor: Colors.grey[200],
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black,
        fontWeight: FontWeight.bold,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildSortChip(
    String label,
    bool isSelected,
    VoidCallback onSelected,
  ) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: Colors.blue[400],
      backgroundColor: Colors.grey[200],
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black,
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}
