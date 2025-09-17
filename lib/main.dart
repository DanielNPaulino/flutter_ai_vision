import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('birddex');

  // Detect first launch
  final prefs = await SharedPreferences.getInstance();
  final firstLaunch = prefs.getBool('first_launch') ?? true;

  if (firstLaunch) {
    final box = Hive.box('birddex');
    await box.clear(); // wipe old data
    await prefs.setBool('first_launch', false);
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'BirdDex', home: HomeScreen());
  }
}
