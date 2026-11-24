import 'package:flutter/material.dart';

const colorWrctech = Color(0xFF0F766E);

ThemeData wrctechTema() {
  final esquema = ColorScheme.fromSeed(seedColor: colorWrctech);
  return ThemeData(
    colorScheme: esquema,
    useMaterial3: true,
    appBarTheme: AppBarTheme(
      backgroundColor: esquema.primary,
      foregroundColor: esquema.onPrimary,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
      ),
    ),
  );
}
