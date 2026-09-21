import 'package:flutter_ai_vision/models/bird.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final json = {
    'commonName': 'Bald Eagle',
    'scientificName': 'Haliaeetus leucocephalus',
    'imageUrl': 'https://example.com/eagle.jpg',
    'size': 'Large',
    'habitat': 'Near rivers and large lakes',
    'diet': 'Fish, birds, mammals',
    'conservationStatus': 'Least Concern',
  };

  test('fromJson defaults collected to false', () {
    final bird = Bird.fromJson(json);
    expect(bird.commonName, 'Bald Eagle');
    expect(bird.collected, isFalse);
  });

  test('toJson round-trips through fromJson', () {
    final bird = Bird.fromJson({...json, 'collected': true});
    final copy = Bird.fromJson(bird.toJson());
    expect(copy.toJson(), bird.toJson());
    expect(copy.collected, isTrue);
  });
}
