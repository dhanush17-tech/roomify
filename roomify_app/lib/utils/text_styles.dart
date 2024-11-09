import 'package:flutter/material.dart';

class AppTextStyles {
  static TextStyle title({
    Color color = Colors.black,
    FontWeight fontWeight = FontWeight.bold,
    double fontSize = 24,
  }) {
    return TextStyle(
      color: color,
      fontWeight: fontWeight,
      fontSize: fontSize,
    );
  }

  static TextStyle subtitle({
    Color color = Colors.black87,
    FontWeight fontWeight = FontWeight.w600,
    double fontSize = 18,
  }) {
    return TextStyle(
      color: color,
      fontWeight: fontWeight,
      fontSize: fontSize,
    );
  }

  static TextStyle body({
    Color color = Colors.black54,
    FontWeight fontWeight = FontWeight.normal,
    double fontSize = 16,
  }) {
    return TextStyle(
      color: color,
      fontWeight: fontWeight,
      fontSize: fontSize,
    );
  }

  static TextStyle caption({
    Color color = Colors.grey,
    FontWeight fontWeight = FontWeight.normal,
    double fontSize = 14,
  }) {
    return TextStyle(
      color: color,
      fontWeight: fontWeight,
      fontSize: fontSize,
    );
  }

  static TextStyle button({
    Color color = Colors.white,
    FontWeight fontWeight = FontWeight.bold,
    double fontSize = 20,
  }) {
    return TextStyle(
      color: color,
      fontWeight: fontWeight,
      fontSize: fontSize, // For better readability on buttons
    );
  }

  static TextStyle small({
    Color color = Colors.black45,
    FontWeight fontWeight = FontWeight.bold,
    double fontSize = 12,
  }) {
    return TextStyle(
      color: color,
      fontWeight: fontWeight,
      fontSize: fontSize,
    );
  }
}
