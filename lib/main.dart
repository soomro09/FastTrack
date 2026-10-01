import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'core/theme/app_theme.dart';
import 'core/notifications/notification_service.dart';
import 'providers/theme_provider.dart';
import 'ui/screens/main_screen.dart';
import 'ui/screens/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // sqflite talks to the OS's native SQLite via platform channels on
  // Android/iOS, but desktop has none — it needs the FFI-backed factory.
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // Notifications are a nice-to-have, not launch-critical — never let a
  // hung or failing plugin channel block the app from ever reaching
  // runApp() (that shows as an infinite native splash screen with no
  // error, since there's no Flutter UI up yet to report one).
  try {
    await NotificationService.instance.init().timeout(const Duration(seconds: 5));
  } catch (_) {
    // Ignored — notification features will simply no-op if this failed.
  }

  final prefs = await SharedPreferences.getInstance();
  final hasCompletedOnboarding = prefs.getBool('has_completed_onboarding') ?? false;

  runApp(
    ProviderScope(
      child: FastingTrackerApp(hasCompletedOnboarding: hasCompletedOnboarding),
    ),
  );
}

class FastingTrackerApp extends ConsumerWidget {
  final bool hasCompletedOnboarding;

  const FastingTrackerApp({
    super.key,
    this.hasCompletedOnboarding = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'FastTrack',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: hasCompletedOnboarding ? const MainScreen() : const OnboardingScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

