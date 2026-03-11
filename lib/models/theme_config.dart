import 'package:flutter/material.dart';

/// Appearance mode options
enum AppearanceMode {
  system,
  light,
  dark,
  custom,
}

/// Color pack themes
enum ColorPack {
  graphitePerformance,
  midnightBlue,
  ember,
  titanium,
  solar,
  aurora,
}

/// Theme configuration model
class ThemeConfig {
  final AppearanceMode appearanceMode;
  final ColorPack? colorPack; // Only used when appearanceMode is custom

  const ThemeConfig({
    this.appearanceMode = AppearanceMode.system,
    this.colorPack,
  });

  /// Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'appearanceMode': appearanceMode.index,
      'colorPack': colorPack?.index,
    };
  }

  /// Create from JSON
  factory ThemeConfig.fromJson(Map<String, dynamic> json) {
    return ThemeConfig(
      appearanceMode: AppearanceMode.values[json['appearanceMode'] ?? 0],
      colorPack: json['colorPack'] != null ? ColorPack.values[json['colorPack']] : null,
    );
  }

  ThemeConfig copyWith({
    AppearanceMode? appearanceMode,
    ColorPack? colorPack,
  }) {
    return ThemeConfig(
      appearanceMode: appearanceMode ?? this.appearanceMode,
      colorPack: colorPack ?? this.colorPack,
    );
  }
}

/// Color pack palette definition
class ColorPackPalette {
  final Color background;
  final Color card;
  final Color primaryAccent;
  final Color secondaryAccent;
  final Color primaryText;
  final Color secondaryText;
  final Color divider;
  final Color border;
  final Color icon;
  final Color success;
  final Color warning;
  final Color error;
  final String name;
  final String description;
  
  // Accent scale for different emphasis levels
  final Color accentStrong;
  final Color accentMedium;
  final Color accentSoft;
  final Color accentHighlight;

  const ColorPackPalette({
    required this.background,
    required this.card,
    required this.primaryAccent,
    required this.secondaryAccent,
    required this.primaryText,
    required this.secondaryText,
    required this.divider,
    required this.border,
    required this.icon,
    required this.success,
    required this.warning,
    required this.error,
    required this.name,
    required this.description,
    required this.accentStrong,
    required this.accentMedium,
    required this.accentSoft,
    required this.accentHighlight,
  });

  /// Get the glow color for PR celebrations
  Color get celebrationGlow => primaryAccent;
}

/// Available color pack palettes
class ColorPacks {
  static const graphitePerformance = ColorPackPalette(
    background: Color(0xFF0A0A0A),
    card: Color(0xFF1A1A1A),
    primaryAccent: Color(0xFFD0FD3E), // Neon green
    secondaryAccent: Color(0xFF7FFF00),
    primaryText: Color(0xFFFFFFFF),
    secondaryText: Color(0xFFB0B0B0),
    divider: Color(0xFF2A2A2A),
    border: Color(0xFF2A2A2A),
    icon: Color(0xFFB0B0B0),
    success: Color(0xFF32D74B),
    warning: Color(0xFFFFBF00),
    error: Color(0xFFFF453A),
    name: 'Graphite Performance',
    description: 'Dark and sleek with neon green accents',
    // Green accent scale: soft -> medium -> strong -> highlight
    accentSoft: Color(0xFF7FFF00),
    accentMedium: Color(0xFFB8F436),
    accentStrong: Color(0xFFD0FD3E),
    accentHighlight: Color(0xFFE0FF6E),
  );

  static const midnightBlue = ColorPackPalette(
    background: Color(0xFF0B1929),
    card: Color(0xFF1A2942),
    primaryAccent: Color(0xFF00D9FF), // Cyan
    secondaryAccent: Color(0xFF0099CC),
    primaryText: Color(0xFFFFFFFF),
    secondaryText: Color(0xFFA8C7E0),
    divider: Color(0xFF2A3F5F),
    border: Color(0xFF2A3F5F),
    icon: Color(0xFFA8C7E0),
    success: Color(0xFF32D74B),
    warning: Color(0xFFFFBF00),
    error: Color(0xFFFF453A),
    name: 'Midnight Blue',
    description: 'Deep ocean with cyan highlights',
    // Cyan accent scale: soft -> medium -> strong -> highlight
    accentSoft: Color(0xFF0099CC),
    accentMedium: Color(0xFF00B8E6),
    accentStrong: Color(0xFF00D9FF),
    accentHighlight: Color(0xFF33E3FF),
  );

  static const ember = ColorPackPalette(
    background: Color(0xFF1A0B0B),
    card: Color(0xFF2A1515),
    primaryAccent: Color(0xFFFF3B30), // Red primary
    secondaryAccent: Color(0xFFE53935),
    primaryText: Color(0xFFFFFFFF),
    secondaryText: Color(0xFFD4A5A5),
    divider: Color(0xFF3A2020),
    border: Color(0xFF3A2020),
    icon: Color(0xFFD4A5A5),
    success: Color(0xFF32D74B),
    warning: Color(0xFFFFBF00),
    error: Color(0xFFFF6B6B),
    name: 'Ember',
    description: 'Burning passion with red fire',
    // Red accent scale: soft -> medium -> strong -> highlight
    accentSoft: Color(0xFFB71C1C),
    accentMedium: Color(0xFFE53935),
    accentStrong: Color(0xFFFF5A4D),
    accentHighlight: Color(0xFFFF6A5F),
  );

  static const titanium = ColorPackPalette(
    background: Color(0xFF0F1419), // Deep dark base
    card: Color(0xFF1E232D), // Softer card background (gradient start)
    primaryAccent: Color(0xFFA8A5AE), // Soft titanium gray (gradient middle)
    secondaryAccent: Color(0xFF7E7B8B), // Deeper titanium (gradient end)
    primaryText: Color(0xFFFFFFFF),
    secondaryText: Color(0xFFA8A5AE), // Softer secondary text
    divider: Color(0x0DFFFFFF), // rgba(255,255,255,0.05) subtle divider
    border: Color(0x0DFFFFFF), // rgba(255,255,255,0.05) subtle border
    icon: Color(0xFFA8A5AE), // Soft icon color
    success: Color(0xFF32D74B),
    warning: Color(0xFFFFBF00),
    error: Color(0xFFFF453A),
    name: 'Titanium',
    description: 'Soft premium metal with subtle gradients',
    // Titanium accent gradient scale: #C9C7CC → #A8A5AE → #7E7B8B
    accentSoft: Color(0xFF7E7B8B), // Deepest - for subtle backgrounds
    accentMedium: Color(0xFF8E8B97), // Progress bars and medium emphasis
    accentStrong: Color(0xFFA8A5AE), // Primary accent
    accentHighlight: Color(0xFFC9C7CC), // Lightest - for highlights
  );

  static const solar = ColorPackPalette(
    background: Color(0xFF1A1508),
    card: Color(0xFF2A2410),
    primaryAccent: Color(0xFFFFBF00), // Gold
    secondaryAccent: Color(0xFFFF9500),
    primaryText: Color(0xFFFFFFFF),
    secondaryText: Color(0xFFD4C494),
    divider: Color(0xFF3A3420),
    border: Color(0xFF3A3420),
    icon: Color(0xFFD4C494),
    success: Color(0xFF32D74B),
    warning: Color(0xFFFF9500),
    error: Color(0xFFFF453A),
    name: 'Solar',
    description: 'Golden sunrise energy',
    // Gold accent scale: soft -> medium -> strong -> highlight
    accentSoft: Color(0xFFCC9900),
    accentMedium: Color(0xFFFF9500),
    accentStrong: Color(0xFFFFBF00),
    accentHighlight: Color(0xFFFFD633),
  );

  static const aurora = ColorPackPalette(
    background: Color(0xFF1A0A1A),
    card: Color(0xFF2A1A2A),
    primaryAccent: Color(0xFFFF00FF), // Magenta
    secondaryAccent: Color(0xFFCC00CC),
    primaryText: Color(0xFFFFFFFF),
    secondaryText: Color(0xFFD4A5D4),
    divider: Color(0xFF3A2A3A),
    border: Color(0xFF3A2A3A),
    icon: Color(0xFFD4A5D4),
    success: Color(0xFF32D74B),
    warning: Color(0xFFFFBF00),
    error: Color(0xFFFF453A),
    name: 'Aurora',
    description: 'Mystical magenta northern lights',
    // Magenta accent scale: soft -> medium -> strong -> highlight
    accentSoft: Color(0xFFCC00CC),
    accentMedium: Color(0xFFE600E6),
    accentStrong: Color(0xFFFF00FF),
    accentHighlight: Color(0xFFFF33FF),
  );

  /// Get palette by ColorPack enum
  static ColorPackPalette getPalette(ColorPack pack) {
    switch (pack) {
      case ColorPack.graphitePerformance:
        return graphitePerformance;
      case ColorPack.midnightBlue:
        return midnightBlue;
      case ColorPack.ember:
        return ember;
      case ColorPack.titanium:
        return titanium;
      case ColorPack.solar:
        return solar;
      case ColorPack.aurora:
        return aurora;
    }
  }

  /// Get all available palettes
  static List<ColorPackPalette> getAllPalettes() {
    return [
      graphitePerformance,
      midnightBlue,
      ember,
      titanium,
      solar,
      aurora,
    ];
  }
}
