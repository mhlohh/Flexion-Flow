import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/main.dart'; // Ensure this import is correct based on your package name

void main() {
  testWidgets('TherapySessionScreen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the scoreboard is present.
    expect(find.text('Score: 0'), findsOneWidget);

    // Verify that the instruction text is present.
    expect(find.text('Step 1:'), findsOneWidget);
    expect(find.textContaining('Raise your arm slowly'), findsOneWidget);

    // Verify buttons are present
    expect(find.text('Prev'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
  });
}
