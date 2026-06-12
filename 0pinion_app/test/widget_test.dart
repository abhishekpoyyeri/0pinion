import 'package:flutter_test/flutter_test.dart';
import 'package:opinion_app/app.dart';

void main() {
  testWidgets('App renders splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const OpinionApp());
    expect(find.text('0pinion'), findsOneWidget);
    expect(find.text('Debate, Not Doomscroll.'), findsOneWidget);
  });
}
