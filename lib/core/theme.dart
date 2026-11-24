import 'package:flutter/material.dart';

/// WhatsApp-like teal green. Change it and the whole app follows.
const brand = Color(0xFF128C7E);

/// Color of the "read" double tick.
const readTick = Color(0xFF53BDEB);

ThemeData buildTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(seedColor: brand, brightness: brightness);
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
    ),
  );
}
