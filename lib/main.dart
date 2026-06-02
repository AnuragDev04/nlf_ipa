import 'package:flutter/material.dart';
import 'package:nlf/pages/splash.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NLF Solutions',
      theme: ThemeData(
        primarySwatch: Colors.red,
        useMaterial3: false,
        // textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      home: SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
