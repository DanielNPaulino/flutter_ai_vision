import 'package:flutter_ai_vision/services/bird_audio_service.dart';

void main() async {
  // Test with a common bird that should have recordings
  print('Testing Xeno-Canto API...\n');
  
  // Test 1: House Sparrow (very common, should have many recordings)
  print('Test 1: Passer domesticus (House Sparrow)');
  final url1 = await BirdAudioService.fetchBirdCall('Passer domesticus');
  print('Result: ${url1 ?? "No recording found"}\n');
  
  // Test 2: American Robin
  print('Test 2: Turdus migratorius (American Robin)');
  final url2 = await BirdAudioService.fetchBirdCall('Turdus migratorius');
  print('Result: ${url2 ?? "No recording found"}\n');
  
  // Test 3: European Robin
  print('Test 3: Erithacus rubecula (European Robin)');
  final url3 = await BirdAudioService.fetchBirdCall('Erithacus rubecula');
  print('Result: ${url3 ?? "No recording found"}\n');
}
