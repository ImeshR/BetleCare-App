import 'package:flutter/material.dart';

class AuthStyles {
  static const Color primaryColor = Color(0xFF205D43);
  static const Color backgroundColor = Colors.white;
  static const Color textColor = Colors.black87;

  static InputDecoration inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: primaryColor),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: primaryColor, width: 2.0),
        borderRadius: BorderRadius.circular(8.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide:
            BorderSide(color: primaryColor.withOpacity(0.5), width: 1.0),
        borderRadius: BorderRadius.circular(8.0),
      ),
      filled: true,
      fillColor: Colors.grey[100],
    );
  }

  static ButtonStyle elevatedButtonStyle = ElevatedButton.styleFrom(
    foregroundColor: Colors.white,
    backgroundColor: primaryColor,
    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  );

  static TextStyle linkTextStyle = TextStyle(
    color: primaryColor,
    fontWeight: FontWeight.bold,
  );
}
