import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:opinion_app/app.dart';
import 'package:opinion_app/core/providers/supabase_provider.dart';

void main() {
  testWidgets('App renders splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWithValue(null),
          authStateProvider.overrideWith((ref) => Stream.value(
            AuthState(AuthChangeEvent.signedOut, null),
          )),
        ],
        child: const OpinionApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('0pinion'), findsOneWidget);
    expect(find.text('Debate, Not Doomscroll.'), findsOneWidget);
  });
}
