import 'package:flutter/material.dart';

import 'home_page.dart';

void main() => runApp(const AwtrixApp());

class AwtrixApp extends StatelessWidget {
  const AwtrixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AWTRIX NG Remote',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.amber,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.amber,
        brightness: Brightness.dark,
      ),
      home: const HomePage(),
    );
  }
}
