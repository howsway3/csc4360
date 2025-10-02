import 'package:flutter/material.dart';
import 'home_screen.dart';

void main() {
  runApp(const RecipeBookApp());
}

class RecipeBookApp extends StatelessWidget {
  const RecipeBookApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Recipe Book',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        scaffoldBackgroundColor: Colors.grey[50],
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
        ),
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
