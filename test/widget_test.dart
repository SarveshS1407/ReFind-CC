import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finders_keepers/main.dart';
import 'package:finders_keepers/core/services/local_storage_service.dart';
import 'package:finders_keepers/providers/app_providers.dart';

void main() {
  testWidgets(
    'Finders Keepers Unauthenticated Welcome & Auth Gate Smoke Test',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = LocalStorageService(prefs);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [localStorageServiceProvider.overrideWithValue(storage)],
          child: const FindersKeepersApp(),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Verify App Title and Campus Branding
      expect(find.text('Finders Keepers?'), findsWidgets);
      expect(
        find.text('Campus Lost & Found Verification Network'),
        findsOneWidget,
      );

      // 2. Verify Authentication Form tabs & Help Center link
      expect(find.text('Sign In'), findsWidgets);
      expect(find.text('Register'), findsOneWidget);
      expect(
        find.text('Help & How It Works (Read User Guide)'),
        findsOneWidget,
      );

      // 3. Verify Evaluator Demonstration Personas
      expect(find.text('Aarav Sharma'), findsOneWidget);
      expect(find.text('Diya Patel'), findsOneWidget);
      expect(find.textContaining('Prof. R. Verma'), findsOneWidget);

      // 4. Test opening Help Center from Welcome Screen without sign-in
      final helpBtnFinder = find.text('Help & How It Works (Read User Guide)');
      await tester.ensureVisible(helpBtnFinder);
      await tester.tap(helpBtnFinder);
      await tester.pumpAndSettle();

      expect(find.text('Help Center & User Guide'), findsOneWidget);
      expect(find.text('A. Welcome to Finders Keepers?'), findsOneWidget);
      expect(
        find.text('E. Ownership Verification & 6-Digit Handover OTP'),
        findsOneWidget,
      );

      // Return back to Welcome Screen
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(find.text('Finders Keepers?'), findsWidgets);
    },
  );

  testWidgets('Finders Keepers Authenticated Session & Main Feed Test', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storage = LocalStorageService(prefs);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [localStorageServiceProvider.overrideWithValue(storage)],
        child: const FindersKeepersApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Scroll until Evaluator Persona "Aarav Sharma" is visible and tap
    final aaravFinder = find.text('Aarav Sharma');
    await tester.ensureVisible(aaravFinder);
    await tester.pumpAndSettle();
    await tester.tap(aaravFinder);
    await tester.pumpAndSettle();

    // Verify Main Screen Feed
    expect(find.text('Finders Keepers?'), findsWidgets);
    expect(find.text('VIT Campus Lost & Found'), findsOneWidget);

    // Verify Navigation destinations
    expect(find.text('Feed'), findsOneWidget);
    expect(find.text('Map'), findsOneWidget);
    expect(find.text('Activity'), findsOneWidget);
    expect(find.text('Help'), findsOneWidget);

    // Verify Filter Chips render
    expect(find.text('All Items'), findsOneWidget);
    expect(find.text('Lost Items'), findsOneWidget);
    expect(find.text('Found Items'), findsOneWidget);

    // Verify Floating Action Button to Report Item
    expect(find.text('Report Item'), findsOneWidget);
  });
}
