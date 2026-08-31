import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/onboarding/onboarding_screen_one.dart';
import 'theme/app_colors.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Draw behind the system bars so the white hero and the blue glow run to the
  // physical edges. This has to happen before runApp, and the Android theme
  // must also declare transparent bars (see android/.../styles.xml) — Dart
  // alone cannot override an opaque window theme.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
    systemNavigationBarContrastEnforced: false,
  ));

  runApp(const LayoverApp());
}

class LayoverApp extends StatelessWidget {
  const LayoverApp({super.key});

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      title: 'Layover',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'InterTight',
        scaffoldBackgroundColor: AppColors.paper,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.accent,
          surface: AppColors.surface,
        ),
      ),
      home: const OnboardingScreenOne(),
    );
  }
}
