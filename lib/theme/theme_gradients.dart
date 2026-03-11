import 'package:flutter/material.dart';
import 'theme_colors.dart';

/// Gradient definitions for the app
class ThemeGradients {
  // Card gradients
  static LinearGradient cardGradient(Color startColor, Color endColor) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [startColor, endColor],
    );
  }
  
  static LinearGradient get defaultCard => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      ThemeColorConstants.surfaceCard,
      ThemeColorConstants.backgroundSecondary,
    ],
  );
  
  // Button gradients
  static LinearGradient buttonGradient(Color startColor, Color endColor) {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [startColor, endColor],
    );
  }
  
  // Progress bar gradients
  static LinearGradient progressGradient(Color startColor, Color endColor) {
    return LinearGradient(
      colors: [startColor, endColor],
    );
  }
  
  // Glass effect gradient
  static LinearGradient get glass => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      ThemeColorConstants.glassBackground,
      ThemeColorConstants.glassBackground.withOpacity(0.7),
    ],
  );
  
  // Titanium theme gradients
  static LinearGradient get titaniumCard => cardGradient(
    TitaniumColors.cardStart,
    TitaniumColors.cardEnd,
  );
  
  static LinearGradient get titaniumButton => buttonGradient(
    TitaniumColors.buttonStart,
    TitaniumColors.buttonEnd,
  );
  
  static LinearGradient get titaniumProgress => progressGradient(
    TitaniumColors.progressStart,
    TitaniumColors.progressEnd,
  );
  
  // Crimson theme gradients
  static LinearGradient get crimsonCard => cardGradient(
    CrimsonColors.cardStart,
    CrimsonColors.cardEnd,
  );
  
  // Midnight theme gradients
  static LinearGradient get midnightCard => cardGradient(
    MidnightColors.cardStart,
    MidnightColors.cardEnd,
  );
  
  // Forest theme gradients
  static LinearGradient get forestCard => cardGradient(
    ForestColors.cardStart,
    ForestColors.cardEnd,
  );
  
  // Amber theme gradients
  static LinearGradient get amberCard => cardGradient(
    AmberColors.cardStart,
    AmberColors.cardEnd,
  );
}
