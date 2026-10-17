import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_theme.dart';
import 'core/services/local_storage_service.dart';
import 'providers/app_providers.dart';
import 'ui/screens/welcome_auth_screen.dart';
import 'ui/screens/responsive_main_screen.dart';

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

class FindersKeepersApp extends ConsumerWidget {
  const FindersKeepersApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);

    return MaterialApp(
      title: 'Finders Keepers? - Campus Lost & Found',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      // Authentication-First Entry Flow
      home: currentUser == null
          ? const WelcomeAuthScreen()
          : const ResponsiveMainScreen(),
    );
  }
}
