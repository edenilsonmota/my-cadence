import 'package:flutter/material.dart';

const Color _seed = Color(0xFF00796B);

ThemeData buildTheme(Brightness brightness) {
  return ThemeData(colorSchemeSeed: _seed, brightness: brightness);
}
