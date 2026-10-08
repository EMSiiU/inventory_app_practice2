import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Color Tokens
  static const Color bgCanvas = Color(0xFF000000); 
  static const Color surfaceCard = Color(0xFF1C1C1E); 
  static const Color surfaceElevated = Color(0xFF2C2C2E); 
  static const Color borderSeparator = Color(0xFF38383A); 
  
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color accentBlue = Color(0xFF0A84FF); 
  
  static const Color statusExpired = Color(0xFFFF453A); 
  static const Color statusWarning = Color(0xFFFF9F0A); 
  static const Color statusLow = Color(0xFFFFD60A); 
  static const Color statusGood = Color(0xFF30D158); 
  static const Color badgeAccent = Color(0xFFFF2D55); 

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgCanvas,
      
      // Aplica la fuente Inter globalmente a toda la app
      fontFamily: GoogleFonts.inter().fontFamily,
      
      colorScheme: const ColorScheme.dark(
        primary: accentBlue,
        surface: surfaceCard,
        background: bgCanvas,
        error: statusExpired,
      ),
      
      // Usa const TextTheme y TextStyle estándar sin errores de tipo
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, letterSpacing: -0.4, color: textPrimary),
        titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.26, color: textPrimary),
        titleMedium: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: textPrimary),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: textSecondary),
        labelSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, letterSpacing: 0.2, color: textSecondary),
      ),

      cardTheme: CardThemeData(
        color: surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: EdgeInsets.zero,
      ),
    );
  }
}