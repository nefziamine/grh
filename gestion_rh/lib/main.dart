import 'package:flutter/material.dart';
import 'theme/stb_theme.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GestionRHApp());
}

class GestionRHApp extends StatelessWidget {
  const GestionRHApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'STB Gestion RH',
      debugShowCheckedModeBanner: false,
      theme: STBTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
