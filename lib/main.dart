import 'package:flutter/material.dart';
import 'package:topik_khusus/loginpage.dart';
import 'package:topik_khusus/splashscreen.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(

        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 255, 174, 0)),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
