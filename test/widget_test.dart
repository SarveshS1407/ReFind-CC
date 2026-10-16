import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finders_keepers/main.dart';
import 'package:finders_keepers/core/services/local_storage_service.dart';
import 'package:finders_keepers/providers/app_providers.dart';

void main() {
  testWidgets('Finders Keepers Home Feed Smoke Test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storage = LocalStorageService(prefs);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageServiceProvider.overrideWithValue(storage),
        ],
        child: const FindersKeepersApp(),
      ),
    );

    // Initial settle
    await tester.pumpAndSettle();

    // Verify App Title renders
    expect(find.text('Finders Keepers?'), findsOneWidget);
    expect(find.text('VIT Campus Lost & Found'), findsOneWidget);

    // Verify Search Bar and Navigation Bar render
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Feed'), findsOneWidget);
    expect(find.text('Map'), findsOneWidget);
    expect(find.text('Activity'), findsOneWidget);

    // Verify Filter Chips render
    expect(find.text('All Items'), findsOneWidget);
    expect(find.text('Lost Items'), findsOneWidget);
    expect(find.text('Found Items'), findsOneWidget);

    // Verify Floating Action Button to Report Item
    expect(find.text('Report Item'), findsOneWidget);
  });
}
