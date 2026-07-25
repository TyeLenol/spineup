import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/navigation_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SpineUpApp());
}

class SpineUpApp extends StatefulWidget {
  const SpineUpApp({super.key});

  @override
  State<SpineUpApp> createState() => _SpineUpAppState();
}

class _SpineUpAppState extends State<SpineUpApp> {
  bool _showSplash = true;

  void _onSplashFinished() {
    if (mounted && _showSplash) {
      setState(() {
        _showSplash = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SpineUp',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: _showSplash
          ? SplashScreen(onFinish: _onSplashFinished)
          : const NavigationShell(),
    );
  }
}
