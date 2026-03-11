import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:total_athlete/models/theme_config.dart';

/// Theme extension for accent scale colors
class AccentScaleExtension extends ThemeExtension<AccentScaleExtension> {
  final Color accentStrong;
  final Color accentMedium;
  final Color accentSoft;
  final Color accentHighlight;

  const AccentScaleExtension({
    required this.accentStrong,
    required this.accentMedium,
    required this.accentSoft,
    required this.accentHighlight,
  });

  @override
  ThemeExtension<AccentScaleExtension> copyWith({
    Color? accentStrong,
    Color? accentMedium,
    Color? accentSoft,
    Color? accentHighlight,
  }) {
    return AccentScaleExtension(
      accentStrong: accentStrong ?? this.accentStrong,
      accentMedium: accentMedium ?? this.accentMedium,
      accentSoft: accentSoft ?? this.accentSoft,
      accentHighlight: accentHighlight ?? this.accentHighlight,
    );
  }

  @override
  ThemeExtension<AccentScaleExtension> lerp(
    covariant ThemeExtension<AccentScaleExtension>? other,
    double t,
  ) {
    if (other is! AccentScaleExtension) return this;
    return AccentScaleExtension(
      accentStrong: Color.lerp(accentStrong, other.accentStrong, t)!,
      accentMedium: Color.lerp(accentMedium, other.accentMedium, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      accentHighlight: Color.lerp(accentHighlight, other.accentHighlight, t)!,
    );
  }
}

/// Theme extension for gradient definitions
class GradientExtension extends ThemeExtension<GradientExtension> {
  final LinearGradient cardGradient;
  final LinearGradient primaryGradient;
  final LinearGradient buttonGradient;
  final LinearGradient progressGradient;
  
  const GradientExtension({
    required this.cardGradient,
    required this.primaryGradient,
    required this.buttonGradient,
    required this.progressGradient,
  });

  @override
  ThemeExtension<GradientExtension> copyWith({
    LinearGradient? cardGradient,
    LinearGradient? primaryGradient,
    LinearGradient? buttonGradient,
    LinearGradient? progressGradient,
  }) {
    return GradientExtension(
      cardGradient: cardGradient ?? this.cardGradient,
      primaryGradient: primaryGradient ?? this.primaryGradient,
      buttonGradient: buttonGradient ?? this.buttonGradient,
      progressGradient: progressGradient ?? this.progressGradient,
    );
  }

  @override
  ThemeExtension<GradientExtension> lerp(
    covariant ThemeExtension<GradientExtension>? other,
    double t,
  ) {
    if (other is! GradientExtension) return this;
    return GradientExtension(
      cardGradient: LinearGradient.lerp(cardGradient, other.cardGradient, t)!,
      primaryGradient: LinearGradient.lerp(primaryGradient, other.primaryGradient, t)!,
      buttonGradient: LinearGradient.lerp(buttonGradient, other.buttonGradient, t)!,
      progressGradient: LinearGradient.lerp(progressGradient, other.progressGradient, t)!,
    );
  }
}

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  static const EdgeInsets paddingXs = EdgeInsets.all(xs);
  static const EdgeInsets paddingSm = EdgeInsets.all(sm);
  static const EdgeInsets paddingMd = EdgeInsets.all(md);
  static const EdgeInsets paddingLg = EdgeInsets.all(lg);
  static const EdgeInsets paddingXl = EdgeInsets.all(xl);

  static const EdgeInsets horizontalXs = EdgeInsets.symmetric(horizontal: xs);
  static const EdgeInsets horizontalSm = EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets horizontalMd = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets horizontalLg = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets horizontalXl = EdgeInsets.symmetric(horizontal: xl);

  static const EdgeInsets verticalXs = EdgeInsets.symmetric(vertical: xs);
  static const EdgeInsets verticalSm = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets verticalMd = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets verticalLg = EdgeInsets.symmetric(vertical: lg);
  static const EdgeInsets verticalXl = EdgeInsets.symmetric(vertical: xl);
}

class AppRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double full = 9999.0;
}

extension TextStyleContext on BuildContext {
  TextTheme get textStyles => Theme.of(this).textTheme;
}

/// Extension to access gradients from context
extension ThemeGradients on BuildContext {
  GradientExtension? get gradients => Theme.of(this).extension<GradientExtension>();
}

/// Premium shadow and glow effects
class AppShadows {
  /// Subtle glow for premium feel (used in Titanium theme)
  static List<BoxShadow> get subtleGlow => [
    BoxShadow(
      color: const Color(0xFF787C8C).withOpacity(0.18),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
  ];
  
  /// Soft card elevation
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 12,
      offset: const Offset(0, 2),
    ),
  ];
  
  /// Button pressed state
  static List<BoxShadow> get buttonPressed => [
    BoxShadow(
      color: Colors.black.withOpacity(0.15),
      blurRadius: 8,
      offset: const Offset(0, 1),
    ),
  ];
  
  /// Glassmorphism shadows - soft depth for frosted glass effect
  static List<BoxShadow> get glassShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.25),
      blurRadius: 30,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.15),
      blurRadius: 15,
      offset: const Offset(0, 4),
    ),
  ];
  
  /// Stronger glass shadow for modals and overlays
  static List<BoxShadow> get glassModalShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.35),
      blurRadius: 40,
      offset: const Offset(0, 12),
    ),
  ];
}

/// Extension to access theme colors consistently across the app
extension ThemeColors on BuildContext {
  /// Get the current theme's color palette
  AppThemeColors get colors {
    final brightness = Theme.of(this).brightness;
    final colorScheme = Theme.of(this).colorScheme;
    
    // Check if using a custom color pack theme
    // Custom themes will have their colors in the colorScheme
    if (colorScheme.surface != AppColors.lightSurface && 
        colorScheme.surface != AppColors.darkSurface) {
      // Custom theme - try to extract accent scale from theme extensions
      final accentScale = Theme.of(this).extension<AccentScaleExtension>();
      
      if (accentScale != null) {
        // Custom theme with accent scale
        return AppThemeColors(
          background: Theme.of(this).scaffoldBackgroundColor,
          card: colorScheme.surface,
          primaryAccent: colorScheme.primary,
          secondaryAccent: colorScheme.secondary,
          primaryText: colorScheme.onSurface,
          secondaryText: colorScheme.onSurface.withOpacity(0.7),
          divider: colorScheme.onSurface.withOpacity(0.12),
          border: colorScheme.onSurface.withOpacity(0.12),
          icon: colorScheme.onSurface.withOpacity(0.7),
          success: const Color(0xFF32D74B),
          warning: const Color(0xFFFFBF00),
          error: colorScheme.error,
          accentStrong: accentScale.accentStrong,
          accentMedium: accentScale.accentMedium,
          accentSoft: accentScale.accentSoft,
          accentHighlight: accentScale.accentHighlight,
        );
      } else {
        // Fallback for custom themes without accent scale
        return AppThemeColors(
          background: Theme.of(this).scaffoldBackgroundColor,
          card: colorScheme.surface,
          primaryAccent: colorScheme.primary,
          secondaryAccent: colorScheme.secondary,
          primaryText: colorScheme.onSurface,
          secondaryText: colorScheme.onSurface.withOpacity(0.7),
          divider: colorScheme.onSurface.withOpacity(0.12),
          border: colorScheme.onSurface.withOpacity(0.12),
          icon: colorScheme.onSurface.withOpacity(0.7),
          success: const Color(0xFF32D74B),
          warning: const Color(0xFFFFBF00),
          error: colorScheme.error,
          accentStrong: colorScheme.primary,
          accentMedium: colorScheme.primary,
          accentSoft: colorScheme.secondary,
          accentHighlight: colorScheme.primary,
        );
      }
    }
    
    // Standard light or dark theme
    if (brightness == Brightness.light) {
      return AppThemeColors(
        background: AppColors.lightBackground,
        card: AppColors.lightSurface,
        primaryAccent: AppColors.lightPrimary,
        secondaryAccent: AppColors.lightSecondary,
        primaryText: AppColors.lightPrimaryText,
        secondaryText: AppColors.lightSecondaryText,
        divider: AppColors.lightDivider,
        border: AppColors.lightDivider,
        icon: AppColors.lightSecondaryText,
        success: AppColors.lightSuccess,
        warning: const Color(0xFFFFBF00),
        error: AppColors.lightError,
        // Light theme green accent scale
        accentSoft: const Color(0xFF7FFF00),
        accentMedium: const Color(0xFFB8F436),
        accentStrong: AppColors.lightPrimary,
        accentHighlight: const Color(0xFFE0FF6E),
      );
    } else {
      return AppThemeColors(
        background: AppColors.darkBackground,
        card: AppColors.darkSurface,
        primaryAccent: AppColors.darkPrimary,
        secondaryAccent: AppColors.darkSecondary,
        primaryText: AppColors.darkPrimaryText,
        secondaryText: AppColors.darkSecondaryText,
        divider: AppColors.darkDivider,
        border: AppColors.darkDivider,
        icon: AppColors.darkSecondaryText,
        success: AppColors.darkSuccess,
        warning: const Color(0xFFFFBF00),
        error: AppColors.darkError,
        // Dark theme green accent scale
        accentSoft: const Color(0xFF7FFF00),
        accentMedium: AppColors.darkPrimary,
        accentStrong: const Color(0xFFD0FD3E),
        accentHighlight: const Color(0xFFE0FF6E),
      );
    }
  }
}

/// Centralized theme colors that work with any theme (light, dark, or custom)
class AppThemeColors {
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
  
  // Accent scale for different emphasis levels
  final Color accentStrong;
  final Color accentMedium;
  final Color accentSoft;
  final Color accentHighlight;

  const AppThemeColors({
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
    required this.accentStrong,
    required this.accentMedium,
    required this.accentSoft,
    required this.accentHighlight,
  });
  
  /// Convenience getters for common color needs
  Color get surface => card;
  Color get onPrimary => const Color(0xFF000000); // Dark text on bright accents
  Color get onSecondary => primaryText;
  Color get hint => secondaryText.withOpacity(0.6);
  Color get onError => const Color(0xFFFFFFFF);
  
  /// Get soft border color (used in Titanium theme for premium feel)
  Color get softBorder => const Color(0x0DFFFFFF); // rgba(255,255,255,0.05)
  
  /// Premium card gradient (if available)
  LinearGradient? cardGradient(BuildContext context) {
    return context.gradients?.cardGradient;
  }
  
  /// Primary accent gradient (if available)
  LinearGradient? primaryGradient(BuildContext context) {
    return context.gradients?.primaryGradient;
  }
  
  /// Button gradient (if available)
  LinearGradient? buttonGradient(BuildContext context) {
    return context.gradients?.buttonGradient;
  }
  
  /// Progress gradient (if available)
  LinearGradient? progressGradient(BuildContext context) {
    return context.gradients?.progressGradient;
  }
}

extension TextStyleExtensions on TextStyle {
  TextStyle get bold => copyWith(fontWeight: FontWeight.bold);
  TextStyle get semiBold => copyWith(fontWeight: FontWeight.w600);
  TextStyle get medium => copyWith(fontWeight: FontWeight.w500);
  TextStyle get normal => copyWith(fontWeight: FontWeight.w400);
  TextStyle get light => copyWith(fontWeight: FontWeight.w300);
  TextStyle withColor(Color color) => copyWith(color: color);
  TextStyle withSize(double size) => copyWith(fontSize: size);
}

/// Legacy color constants for backward compatibility
/// New code should use context.colors extension instead
class AppColors {
  // Light mode colors
  static const lightPrimary = Color(0xFFD0FD3E);
  static const lightOnPrimary = Color(0xFF000000);
  static const lightSecondary = Color(0xFF2C2C2E);
  static const lightOnSecondary = Color(0xFFFFFFFF);
  static const lightAccent = Color(0xFFD0FD3E);
  static const lightBackground = Color(0xFFF2F2F7);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightOnSurface = Color(0xFF1C1C1E);
  static const lightPrimaryText = Color(0xFF1C1C1E);
  static const lightSecondaryText = Color(0xFF636366);
  static const lightHint = Color(0xFF8E8E93);
  static const lightError = Color(0xFFFF453A);
  static const lightOnError = Color(0xFFFFFFFF);
  static const lightSuccess = Color(0xFF32D74B);
  static const lightDivider = Color(0xFFE5E5EA);

  // Dark mode colors
  static const darkPrimary = Color(0xFFB8F436);
  static const darkOnPrimary = Color(0xFF000000);
  static const darkSecondary = Color(0xFF2C2C2E);
  static const darkOnSecondary = Color(0xFFFFFFFF);
  static const darkAccent = Color(0xFFD0FD3E);
  static const darkBackground = Color(0xFF000000);
  static const darkSurface = Color(0xFF1C1C1E);
  static const darkOnSurface = Color(0xFFFFFFFF);
  static const darkPrimaryText = Color(0xFFFFFFFF);
  static const darkSecondaryText = Color(0xFFA1A1A6);
  static const darkHint = Color(0xFF48484A);
  static const darkError = Color(0xFFFF453A);
  static const darkOnError = Color(0xFF000000);
  static const darkSuccess = Color(0xFF32D74B);
  static const darkDivider = Color(0xFF2C2C2E);
  
  /// Get theme-aware colors - this method adapts to custom themes
  static AppThemeColors fromContext(BuildContext context) {
    return context.colors;
  }
}

ThemeData get lightTheme => ThemeData(
  useMaterial3: true,
  colorScheme: const ColorScheme.light(
    primary: AppColors.lightPrimary,
    onPrimary: AppColors.lightOnPrimary,
    secondary: AppColors.lightSecondary,
    onSecondary: AppColors.lightOnSecondary,
    surface: AppColors.lightSurface,
    onSurface: AppColors.lightOnSurface,
    error: AppColors.lightError,
    onError: AppColors.lightOnError,
  ),
  brightness: Brightness.light,
  scaffoldBackgroundColor: AppColors.lightBackground,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    foregroundColor: AppColors.lightPrimaryText,
    elevation: 0,
    scrolledUnderElevation: 0,
  ),
  textTheme: _buildTextTheme(Brightness.light),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: AppColors.lightPrimary,
    foregroundColor: AppColors.lightOnPrimary,
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.lightPrimary,
      foregroundColor: AppColors.lightOnPrimary,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.lightPrimary,
      side: const BorderSide(color: AppColors.lightPrimary, width: 1.5),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.lightSurface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      borderSide: const BorderSide(color: AppColors.lightDivider),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      borderSide: const BorderSide(color: AppColors.lightDivider),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      borderSide: const BorderSide(color: AppColors.lightPrimary, width: 2),
    ),
  ),
);

ThemeData get darkTheme => ThemeData(
  useMaterial3: true,
  colorScheme: const ColorScheme.dark(
    primary: AppColors.darkPrimary,
    onPrimary: AppColors.darkOnPrimary,
    secondary: AppColors.darkSecondary,
    onSecondary: AppColors.darkOnSecondary,
    surface: AppColors.darkSurface,
    onSurface: AppColors.darkOnSurface,
    error: AppColors.darkError,
    onError: AppColors.darkOnError,
  ),
  brightness: Brightness.dark,
  scaffoldBackgroundColor: AppColors.darkBackground,
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    foregroundColor: AppColors.darkPrimaryText,
    elevation: 0,
    scrolledUnderElevation: 0,
  ),
  textTheme: _buildTextTheme(Brightness.dark),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: AppColors.darkPrimary,
    foregroundColor: AppColors.darkOnPrimary,
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.darkPrimary,
      foregroundColor: AppColors.darkOnPrimary,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.darkPrimary,
      side: const BorderSide(color: AppColors.darkPrimary, width: 1.5),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.darkSurface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      borderSide: const BorderSide(color: AppColors.darkDivider),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      borderSide: const BorderSide(color: AppColors.darkDivider),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      borderSide: const BorderSide(color: AppColors.darkPrimary, width: 2),
    ),
  ),
);

TextTheme _buildTextTheme(Brightness brightness) {
  final primaryFont = GoogleFonts.plusJakartaSans;
  final secondaryFont = GoogleFonts.inter;

  return TextTheme(
    headlineLarge: primaryFont(fontSize: 34, fontWeight: FontWeight.w800, height: 1.1),
    headlineMedium: primaryFont(fontSize: 28, fontWeight: FontWeight.w700, height: 1.2),
    headlineSmall: primaryFont(fontSize: 24, fontWeight: FontWeight.w600, height: 1.2),
    titleLarge: primaryFont(fontSize: 22, fontWeight: FontWeight.w700, height: 1.3),
    titleMedium: primaryFont(fontSize: 17, fontWeight: FontWeight.w600, height: 1.4),
    titleSmall: primaryFont(fontSize: 15, fontWeight: FontWeight.w600, height: 1.3),
    bodyLarge: secondaryFont(fontSize: 17, fontWeight: FontWeight.w400, height: 1.5),
    bodyMedium: secondaryFont(fontSize: 15, fontWeight: FontWeight.w400, height: 1.5),
    bodySmall: secondaryFont(fontSize: 13, fontWeight: FontWeight.w400, height: 1.4),
    labelLarge: primaryFont(fontSize: 15, fontWeight: FontWeight.w700, height: 1.2),
    labelMedium: primaryFont(fontSize: 13, fontWeight: FontWeight.w700, height: 1.2),
    labelSmall: primaryFont(fontSize: 11, fontWeight: FontWeight.w700, height: 1.1),
  );
}

/// Build a custom theme from a color pack palette
ThemeData buildCustomTheme(ColorPackPalette palette) {
  final textTheme = _buildTextTheme(Brightness.dark);
  
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.dark(
      primary: palette.primaryAccent,
      onPrimary: const Color(0xFF000000),
      secondary: palette.secondaryAccent,
      onSecondary: palette.primaryText,
      surface: palette.card,
      onSurface: palette.primaryText,
      error: palette.error,
      onError: const Color(0xFFFFFFFF),
      outline: palette.border,
    ),
    brightness: Brightness.dark,
    scaffoldBackgroundColor: palette.background,
    cardColor: palette.card,
    dividerColor: palette.divider,
    iconTheme: IconThemeData(color: palette.icon),
    extensions: [
      AccentScaleExtension(
        accentStrong: palette.accentStrong,
        accentMedium: palette.accentMedium,
        accentSoft: palette.accentSoft,
        accentHighlight: palette.accentHighlight,
      ),
      GradientExtension(
        // Card background gradient: darker at top → lighter at bottom
        cardGradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [palette.card, palette.background.withOpacity(0.95)],
        ),
        // Primary accent gradient: highlight → strong → medium → soft
        primaryGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [palette.accentHighlight, palette.accentStrong, palette.accentMedium],
        ),
        // Button gradient: medium → soft (for subtle depth)
        buttonGradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [palette.accentMedium, palette.accentSoft],
        ),
        // Progress bar gradient: highlight → medium
        progressGradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [palette.accentHighlight, palette.accentMedium],
        ),
      ),
    ],
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: palette.primaryText,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: palette.icon),
      titleTextStyle: textTheme.titleLarge?.copyWith(color: palette.primaryText),
    ),
    textTheme: textTheme.apply(
      bodyColor: palette.primaryText,
      displayColor: palette.primaryText,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: palette.primaryAccent,
      foregroundColor: const Color(0xFF000000),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: palette.primaryAccent,
        foregroundColor: const Color(0xFF000000),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        textStyle: textTheme.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: palette.primaryAccent,
        side: BorderSide(color: palette.primaryAccent, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        textStyle: textTheme.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: palette.primaryAccent,
        textStyle: textTheme.labelLarge,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: palette.card,
      hintStyle: TextStyle(color: palette.secondaryText),
      labelStyle: TextStyle(color: palette.secondaryText),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        borderSide: BorderSide(color: palette.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        borderSide: BorderSide(color: palette.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        borderSide: BorderSide(color: palette.primaryAccent, width: 2),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: palette.card,
      selectedColor: palette.primaryAccent,
      labelStyle: TextStyle(color: palette.primaryText),
      secondaryLabelStyle: TextStyle(color: palette.secondaryText),
      brightness: Brightness.dark,
      side: BorderSide(color: palette.border),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const Color(0xFF000000);
        }
        return palette.secondaryText;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return palette.primaryAccent;
        }
        return palette.divider;
      }),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: palette.card,
      titleTextStyle: textTheme.titleLarge?.copyWith(color: palette.primaryText),
      contentTextStyle: textTheme.bodyMedium?.copyWith(color: palette.secondaryText),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: palette.card,
      modalBackgroundColor: palette.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: palette.card,
      contentTextStyle: textTheme.bodyMedium?.copyWith(color: palette.primaryText),
      actionTextColor: palette.primaryAccent,
    ),
  );
}
