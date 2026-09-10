import 'package:flutter_test/flutter_test.dart';
import 'package:notezy/main.dart';

void main() {
  testWidgets('Notesy app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const NotesyApp());

    expect(find.text('Notesy'), findsWidgets);
  });
}
