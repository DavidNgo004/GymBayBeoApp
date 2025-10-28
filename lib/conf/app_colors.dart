import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF57564F);
  static const primaryGradient = Color.fromARGB(255, 183, 183, 180);
  static const secondary = Color(0xFFFF6600);
  static const background = Colors.white;
  static const textPrimary = Colors.white;
  static const textBtn = Colors.white;
  static const textField = Color(0xFF57564F);
  static const success = Colors.green;
  static const error = Colors.red;
  static const txtError = Colors.white;
  static const shadowTotoro = Colors.black;
  static const txtLink = Color(0xFF0065F8);
  static const discountPackage = Colors.green;
  static const cardbgCurrent = Color.fromARGB(255, 195, 245, 246);
  static const cardbg = Color.fromARGB(255, 201, 196, 178);
  static const caution = Colors.redAccent;
  static const divider = Colors.black;
  static const boxShadow = Colors.deepPurpleAccent;
  static const bgMyChat = LinearGradient(
    colors: [
      primary, // tím đậm
      primaryGradient, // tím sáng hơn
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const bgNotMeChat = LinearGradient(
    colors: [
      Colors.grey, // tím đậm
      primaryGradient, // tím sáng hơn
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
