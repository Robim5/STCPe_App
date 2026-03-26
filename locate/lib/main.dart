import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';

/// global theme notifier to switch between light/dark mode
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const LocaTeApp());
}

class LocaTeApp extends StatelessWidget {
  const LocaTeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, child) {
        return MaterialApp(
          title: 'LocaTe',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: mode,
          home: const SplashScreen(),
        );
      },
    );
  }
}
