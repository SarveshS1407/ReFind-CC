import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_theme.dart';
import 'core/services/local_storage_service.dart';
import 'providers/app_providers.dart';
import 'ui/screens/home_feed_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize persistent local storage service
  final localStorageService = await LocalStorageService.init();

  runApp(
    ProviderScope(
      overrides: [
        localStorageServiceProvider.overrideWithValue(localStorageService),
      ],
      child: const FindersKeepersApp(),
    ),
  );
}

class FindersKeepersApp extends StatelessWidget {
  const FindersKeepersApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finders Keepers? - Campus Lost & Found',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const HomeFeedScreen(),
    );
  }
}
