import 'package:flutter_test/flutter_test.dart';
import 'package:crash_lens/main.dart';

void main() {
  testWidgets('CrashLensApp renders main UI smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const CrashLensApp());
    await tester.pumpAndSettle();

    // Verify CrashLens AI title text appears
    expect(find.text('Crash'), findsOneWidget);
    expect(find.text('Lens'), findsOneWidget);
    expect(find.text('Import Crash Log'), findsOneWidget);
  });
}

