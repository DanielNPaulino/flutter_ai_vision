import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import '../models/bird.dart';

class BirdLoader {
  static Future<void> loadInitialBirds() async {
    final box = Hive.box('birddex');

    if (box.isEmpty) {
      print("BirdDex is empty. Loading birds from JSON...");

      final String jsonString = await rootBundle.loadString(
        'assets/data/birds.json',
      );
      final List<dynamic> jsonData = json.decode(jsonString);

      print("Found ${jsonData.length} birds in JSON");

      for (var birdData in jsonData) {
        final commonName = birdData['commonName'];
        print("Adding bird: $commonName");
        box.put(commonName, birdData);
      }

      print("Total birds in Hive after load: ${box.length}");
    } else {
      print("BirdDex already loaded. Total birds: ${box.length}");
    }
  }
}
