import 'package:flutter/material.dart';
import 'screens/home/home_screen.dart';

class MyBestApp extends StatelessWidget {
  const MyBestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Best',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF006994),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
