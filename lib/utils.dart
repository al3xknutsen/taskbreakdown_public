import 'package:flutter/material.dart';

Color getBackgroundColor(int level, double hue) {
  final double lightness = 0.9 - (level * 0.05);
  return HSLColor.fromAHSL(1.0, hue, 0.6, lightness).toColor();
}
