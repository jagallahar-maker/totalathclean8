/// THEME MIGRATION HELPER
/// 
/// This document maps old hardcoded color patterns to new centralized theme tokens.
/// All components should use `context.colors` instead of hardcoded AppColors values.
/// 
/// MAPPINGS:
/// 
/// OLD PATTERN                                    → NEW PATTERN
/// =====================================================================================================================
/// isDark ? AppColors.darkBackground : AppColors.lightBackground  → colors.background
/// isDark ? AppColors.darkSurface : AppColors.lightSurface        → colors.card (or colors.surface)
/// isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText → colors.primaryText
/// isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText → colors.secondaryText
/// isDark ? AppColors.darkHint : AppColors.lightHint              → colors.hint
/// isDark ? AppColors.darkDivider : AppColors.lightDivider        → colors.divider
/// isDark ? AppColors.darkPrimary : AppColors.lightPrimary        → colors.primaryAccent
/// isDark ? AppColors.darkSecondary : AppColors.lightSecondary    → colors.secondaryAccent
/// isDark ? AppColors.darkSuccess : AppColors.lightSuccess        → colors.success
/// isDark ? AppColors.darkError : AppColors.lightError            → colors.error
/// isDark ? AppColors.darkOnPrimary : AppColors.lightOnPrimary    → colors.onPrimary
/// isDark ? AppColors.darkOnSecondary : AppColors.lightOnSecondary → colors.onSecondary
/// 
/// ACCENT SCALE (for different emphasis levels):
/// colors.accentStrong      - Primary accent (brightest/most emphasis)
/// colors.accentMedium      - Medium emphasis (progress bars)
/// colors.accentSoft        - Subtle backgrounds
/// colors.accentHighlight   - Lightest highlights
/// 
/// SEMANTIC COLORS (preserve these - they have inherent meaning):
/// colors.success           - Always green (0xFF32D74B)
/// colors.warning           - Always amber (0xFFFFBF00)
/// colors.error             - Always red (0xFFFF453A)
/// 
/// SPECIAL CASES:
/// Colors.black.withOpacity(...) → Keep as-is for shadows
/// Colors.transparent → Keep as-is
/// Color(0xFF...) in shadows → Keep as-is (structural, not thematic)
/// 
/// USAGE EXAMPLE:
/// ```dart
/// // OLD (hardcoded, theme-unaware)
/// final isDark = Theme.of(context).brightness == Brightness.dark;
/// Container(
///   color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
///   child: Text(
///     'Hello',
///     style: TextStyle(color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText),
///   ),
/// )
/// 
/// // NEW (centralized, theme-aware)
/// final colors = context.colors;
/// Container(
///   color: colors.card,
///   child: Text(
///     'Hello',
///     style: TextStyle(color: colors.primaryText),
///   ),
/// )
/// ```
/// 
/// BENEFITS:
/// - Switching themes updates ALL components automatically
/// - No more isDark checks scattered everywhere
/// - Single source of truth for theme colors
/// - Future theme additions work instantly
/// - Consistent visual language across app
