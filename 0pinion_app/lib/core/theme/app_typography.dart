import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 0pinion Typography System
/// Headlines: Space Grotesk (Bold)
/// Body & Labels: Geist (Regular)
class AppTypography {
  AppTypography._();

  // â”€â”€â”€ Headlines (Space Grotesk) â”€â”€â”€

  static TextStyle display({Color? color}) => GoogleFonts.spaceGrotesk(
        fontSize: 48,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: -1.5,
        height: 1.1,
      );

  static TextStyle h1({Color? color}) => GoogleFonts.spaceGrotesk(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: -0.5,
        height: 1.2,
      );

  static TextStyle h2({Color? color}) => GoogleFonts.spaceGrotesk(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: color,
        height: 1.3,
      );

  static TextStyle h3({Color? color}) => GoogleFonts.spaceGrotesk(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: color,
        height: 1.3,
      );

  // â”€â”€â”€ Body (Geist) â”€â”€â”€

  static TextStyle body({Color? color}) => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.5,
      );

  static TextStyle bodyMedium({Color? color}) => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: color,
        height: 1.5,
      );

  static TextStyle bodySemiBold({Color? color}) => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: color,
        height: 1.5,
      );

  // â”€â”€â”€ Captions & Labels â”€â”€â”€

  static TextStyle caption({Color? color}) => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.4,
      );

  static TextStyle captionMedium({Color? color}) => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: color,
        height: 1.4,
      );

  static TextStyle label({Color? color}) => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: color,
        letterSpacing: 0.5,
        height: 1.3,
      );

  static TextStyle button({Color? color}) => GoogleFonts.spaceGrotesk(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: color,
        height: 1.0,
      );
}
