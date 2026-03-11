import 'package:flutter/material.dart';

/// Core color constants for the app theme system (legacy)
/// Use context.tokens for semantic tokens instead
class ThemeColorConstants {
  // Primary brand colors
  static const Color primaryAccent = Color(0xFF6C7A89);
  static const Color secondaryAccent = Color(0xFF8B95A3);

  // Background colors
  static const Color backgroundPrimary = Color(0xFF0A0E14);
  static const Color backgroundSecondary = Color(0xFF151A23);
  static const Color backgroundTertiary = Color(0xFF1E232D);

  // Surface colors
  static const Color surfaceCard = Color(0xFF1E232D);
  static const Color surfaceElevated = Color(0xFF252B36);
  static const Color surfaceModal = Color(0xFF2A3140);

  // Text colors
  static const Color textPrimary = Color(0xFFE8E8E8);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color textOnAccent = Colors.white;

  // Border colors
  static const Color borderSubtle = Color(0x1AFFFFFF);
  static const Color borderMedium = Color(0x33FFFFFF);
  static const Color borderStrong = Color(0x4DFFFFFF);

  // State colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Glass effect colors
  static const Color glassBackground = Color(0x99000000);
  static const Color glassBorder = Color(0x1AFFFFFF);
}

/// Theme-specific color variations (Titanium, Crimson, etc.)
class TitaniumColors {
  static const Color accent = Color(0xFFC9C7CC);
  static const Color accentMedium = Color(0xFFA8A5AE);
  static const Color accentDark = Color(0xFF7E7B8B);

  static const Color cardStart = Color(0xFF1E232D);
  static const Color cardEnd = Color(0xFF171B23);

  static const Color buttonStart = Color(0xFF5A6476);
  static const Color buttonEnd = Color(0xFF3F4553);

  static const Color progressStart = Color(0xFFB8B5BE);
  static const Color progressEnd = Color(0xFF8E8B97);
}

class CrimsonColors {
  static const Color accent = Color(0xFFDC143C);
  static const Color accentLight = Color(0xFFFF1744);
  static const Color accentDark = Color(0xFFB71C1C);

  static const Color cardStart = Color(0xFF1A0D0D);
  static const Color cardEnd = Color(0xFF0F0606);
}

class MidnightColors {
  static const Color accent = Color(0xFF1E3A8A);
  static const Color accentLight = Color(0xFFA5F63B);
  static const Color accentDark = Color(0xFF1E40AF);

  static const Color cardStart = Color(0xFF0F1419);
  static const Color cardEnd = Color(0xFF0A0E14);
}

class ForestColors {
  static const Color accent = Color(0xFF10B981);
  static const Color accentLight = Color(0xFF34D399);
  static const Color accentDark = Color(0xFF059669);

  static const Color cardStart = Color(0xFF0D1F17);
  static const Color cardEnd = Color(0xFF071109);
}

class AmberColors {
  static const Color accent = Color(0xFFF59E0B);
  static const Color accentLight = Color(0xFFFBBF24);
  static const Color accentDark = Color(0xFFD97706);

  static const Color cardStart = Color(0xFF1F1A0D);
  static const Color cardEnd = Color(0xFF110F06);
}
