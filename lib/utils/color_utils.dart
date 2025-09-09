// lib/utils/color_utils.dart
import 'package:flutter/material.dart';

const List<Color> kLecturePalette = [
  Color(0xFF6C8AE4), // indigo
  Color(0xFF9A7FD1), // purple
  Color(0xFF52B9C9), // teal
  Color(0xFFDB6E7E), // rose
  Color(0xFF64B5F6), // light blue
  Color(0xFF9575CD), // violet
  Color(0xFFF06292), // pink
  Color(0xFF4DB6AC), // turquoise
  Color(0xFFEBA04D), // orange
  Color(0xFF6C92D4), // custom blue
  Color(0xFF81A1C1), // gray-blue
  Color(0xFFB48EAD), // soft purple
];

Color lectureColor(String title) {
  final h = title.hashCode;
  return kLecturePalette[h.abs() % kLecturePalette.length];
}
