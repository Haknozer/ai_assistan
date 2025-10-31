import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ai_asisstan/main.dart';

void main() {
  testWidgets('AI Assistant app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: AIAssistantApp(),
      ),
    );

    // Verify that splash screen appears
    expect(find.text('AI Asistan'), findsOneWidget);
    expect(find.text('Akıllı kişisel yardımcınız'), findsOneWidget);
  });
}
