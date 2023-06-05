import 'package:flutter/material.dart';

ThemeData theme = ThemeData(
  primarySwatch: Colors.red,
  scaffoldBackgroundColor: Colors.white,

  // appBarTheme
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.red,
    elevation: 0,
    iconTheme: IconThemeData(color: Colors.red),
    titleTextStyle: TextStyle(fontSize: 45, fontWeight: FontWeight.w900),
  ),

  // textTheme
  textTheme: const TextTheme(
    titleLarge: TextStyle(
      fontSize: 45,
      fontWeight: FontWeight.w900,
      color: Colors.white,
    ),
    titleSmall: TextStyle(
      fontSize: 15,
      color: Colors.white,
    ),
  ),
);
