import 'package:flutter/material.dart';
import 'package:total_athlete/theme.dart';

/// Centralized Theme Token System
/// 
/// Provides semantic color tokens that all UI components reference.
/// Changing a token updates all components globally.
/// 
/// Usage:
/// ```dart
/// final tokens = context.tokens;
/// Container(
///   color: tokens.cardBackground,
///   decoration: BoxDecoration(
///     border: Border.all(color: tokens.cardBorder),
///   ),
/// );
/// ```
class ThemeTokens {
  // ============================================================================
  // PAGE TOKENS
  // ============================================================================
  
  /// Main page background color
  final Color pageBackground;
  
  // ============================================================================
  // CARD TOKENS
  // ============================================================================
  
  /// Card background color
  final Color cardBackground;
  
  /// Card border color
  final Color cardBorder;
  
  /// Card gradient (optional, null for themes without gradients)
  final Gradient? cardGradient;
  
  // ============================================================================
  // CHIP TOKENS
  // ============================================================================
  
  /// Unselected chip background
  final Color chipBackground;
  
  /// Selected chip background (solid color fallback)
  final Color chipSelectedBackground;
  
  /// Selected chip gradient (optional)
  final Gradient? chipSelectedGradient;
  
  /// Unselected chip border
  final Color chipBorder;
  
  /// Chip text color (unselected)
  final Color chipText;
  
  /// Chip text color (selected)
  final Color chipSelectedText;
  
  // ============================================================================
  // INPUT TOKENS
  // ============================================================================
  
  /// Input field background
  final Color inputBackground;
  
  /// Input field border (enabled state)
  final Color inputBorder;
  
  /// Input field border (focused state)
  final Color inputBorderFocused;
  
  /// Input text color
  final Color inputText;
  
  /// Input placeholder/hint text color
  final Color inputHint;
  
  // ============================================================================
  // ACCENT TOKENS
  // ============================================================================
  
  /// Primary accent color (solid)
  final Color accentSolid;
  
  /// Primary accent gradient (optional)
  final Gradient? accentGradient;
  
  /// Button accent gradient (optional)
  final Gradient? buttonGradient;
  
  /// Progress bar gradient (optional)
  final Gradient? progressGradient;
  
  // ============================================================================
  // ACCENT SCALE (for different emphasis levels)
  // ============================================================================
  
  /// Strongest accent (brightest)
  final Color accentStrong;
  
  /// Medium accent
  final Color accentMedium;
  
  /// Soft accent (subtle)
  final Color accentSoft;
  
  /// Highlight accent (for special emphasis)
  final Color accentHighlight;
  
  // ============================================================================
  // STATE TOKENS
  // ============================================================================
  
  /// Success state color (green)
  final Color success;
  
  /// Warning state color (amber/yellow)
  final Color warning;
  
  /// Danger/Error state color (red)
  final Color danger;
  
  /// Info state color (blue)
  final Color info;
  
  // ============================================================================
  // TEXT TOKENS
  // ============================================================================
  
  /// Primary text color (highest contrast)
  final Color textPrimary;
  
  /// Secondary text color (medium contrast)
  final Color textSecondary;
  
  /// Muted text color (low contrast)
  final Color textMuted;
  
  /// Text on accent backgrounds
  final Color textOnAccent;
  
  // ============================================================================
  // ADDITIONAL TOKENS
  // ============================================================================
  
  /// Icon color
  final Color icon;
  
  /// Divider color
  final Color divider;
  
  /// Subtle border (very low opacity)
  final Color borderSubtle;
  
  const ThemeTokens({
    // Page
    required this.pageBackground,
    
    // Card
    required this.cardBackground,
    required this.cardBorder,
    this.cardGradient,
    
    // Chip
    required this.chipBackground,
    required this.chipSelectedBackground,
    this.chipSelectedGradient,
    required this.chipBorder,
    required this.chipText,
    required this.chipSelectedText,
    
    // Input
    required this.inputBackground,
    required this.inputBorder,
    required this.inputBorderFocused,
    required this.inputText,
    required this.inputHint,
    
    // Accent
    required this.accentSolid,
    this.accentGradient,
    this.buttonGradient,
    this.progressGradient,
    
    // Accent Scale
    required this.accentStrong,
    required this.accentMedium,
    required this.accentSoft,
    required this.accentHighlight,
    
    // State
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
    
    // Text
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textOnAccent,
    
    // Additional
    required this.icon,
    required this.divider,
    required this.borderSubtle,
  });
}

/// Extension to access theme tokens from any BuildContext
extension ThemeTokensContext on BuildContext {
  /// Get the current theme's token palette
  ThemeTokens get tokens {
    final colors = this.colors;
    final gradients = this.gradients;
    
    return ThemeTokens(
      // ========================================================================
      // PAGE
      // ========================================================================
      pageBackground: colors.background,
      
      // ========================================================================
      // CARD
      // ========================================================================
      cardBackground: colors.card,
      cardBorder: colors.softBorder,
      cardGradient: gradients?.cardGradient,
      
      // ========================================================================
      // CHIP
      // ========================================================================
      chipBackground: colors.card,
      chipSelectedBackground: colors.primaryAccent,
      chipSelectedGradient: gradients?.primaryGradient,
      chipBorder: colors.border,
      chipText: colors.primaryText,
      chipSelectedText: Colors.white,
      
      // ========================================================================
      // INPUT
      // ========================================================================
      inputBackground: colors.card,
      inputBorder: colors.border,
      inputBorderFocused: colors.primaryAccent,
      inputText: colors.primaryText,
      inputHint: colors.secondaryText.withOpacity(0.6),
      
      // ========================================================================
      // ACCENT
      // ========================================================================
      accentSolid: colors.primaryAccent,
      accentGradient: gradients?.primaryGradient,
      buttonGradient: gradients?.buttonGradient,
      progressGradient: gradients?.progressGradient,
      
      // ========================================================================
      // ACCENT SCALE
      // ========================================================================
      accentStrong: colors.accentStrong,
      accentMedium: colors.accentMedium,
      accentSoft: colors.accentSoft,
      accentHighlight: colors.accentHighlight,
      
      // ========================================================================
      // STATE
      // ========================================================================
      success: colors.success,
      warning: colors.warning,
      danger: colors.error,
      info: const Color(0xFF3B82F6), // Blue info color
      
      // ========================================================================
      // TEXT
      // ========================================================================
      textPrimary: colors.primaryText,
      textSecondary: colors.secondaryText,
      textMuted: colors.secondaryText.withOpacity(0.6),
      textOnAccent: Colors.white,
      
      // ========================================================================
      // ADDITIONAL
      // ========================================================================
      icon: colors.icon,
      divider: colors.divider,
      borderSubtle: colors.softBorder,
    );
  }
}
