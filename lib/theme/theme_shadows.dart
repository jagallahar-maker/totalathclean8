import 'package:flutter/material.dart';
import 'theme_colors.dart';

/// Shadow definitions for the app
class ThemeShadows {
  // Subtle elevation shadows
  static List<BoxShadow> get subtle => [
    BoxShadow(
      color: Colors.black.withOpacity(0.1),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
  
  // Medium elevation shadows
  static List<BoxShadow> get medium => [
    BoxShadow(
      color: Colors.black.withOpacity(0.15),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
  
  // Strong elevation shadows
  static List<BoxShadow> get strong => [
    BoxShadow(
      color: Colors.black.withOpacity(0.25),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];
  
  // Glow effects
  static List<BoxShadow> glowEffect(Color color) => [
    BoxShadow(
      color: color.withOpacity(0.3),
      blurRadius: 12,
      spreadRadius: 2,
    ),
  ];
  
  // Glass effect shadow
  static List<BoxShadow> get glass => [
    BoxShadow(
      color: Colors.black.withOpacity(0.2),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: ThemeColorConstants.glassBorder,
      blurRadius: 1,
      spreadRadius: 0.5,
    ),
  ];
}
