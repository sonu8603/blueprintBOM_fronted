import 'package:bmapp/screens/nav_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(
    const ProviderScope(
      child: IsoDrgApp(),
    ),
  );
}

class IsoDrgApp extends StatelessWidget {
  const IsoDrgApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ISO DRG GET ALL DETAILS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3B82F6),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF1F5F9),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3B82F6),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0A0F1E),
      ),
      themeMode: ThemeMode.system,
      home: const MainShell(),
    );
  }
}