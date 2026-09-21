import 'package:flutter_ai_vision/main.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Home screen shows the three main actions', (tester) async {
    // ApiService reads its key from dotenv, so it must be initialised.
    dotenv.loadFromString(envString: 'OPENAI_API_KEY=test');

    await tester.pumpWidget(const MyApp());

    expect(find.text('Welcome to Bird AI Vision'), findsOneWidget);
    expect(find.text('Identify from Camera'), findsOneWidget);
    expect(find.text('Identify from Gallery'), findsOneWidget);
    expect(find.text('Open BirdDex'), findsOneWidget);
  });
}
