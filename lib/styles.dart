// lib/styles.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const mostUrgent = Color(0xFFFF7043);
  static const important = Color(0xFF5C6BC0);
  static const doThisLater = Color(0xFF64B5F6);
  static const kindOfImportant = Color(0xFFBA68C8);
  static const complete = Colors.grey;
  static const lightGrey = Color(0xFFF5F5F5);
  static const black = Colors.black;
  static const white = Colors.white;
}

class AppTextStyles {
  static final header = GoogleFonts.montserrat(
    fontSize: 28,
    fontWeight: FontWeight.w400,
  );

  static final groupTitle = GoogleFonts.montserrat(
    fontWeight: FontWeight.w500,
    color: AppColors.white,
    fontSize:20
  );

  static final taskItem = GoogleFonts.montserrat(
    fontSize: 14,
    color: AppColors.white,
    fontWeight: FontWeight.w500,
  );

  static final chipText = GoogleFonts.montserrat(fontSize: 12);

  static final buttonText = GoogleFonts.montserrat(
    color: AppColors.white,
  );
}
