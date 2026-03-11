import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:total_athlete/theme.dart';

/// Glassmorphism styling levels
enum GlassLevel {
  /// Subtle glass effect for nested cards or secondary surfaces
  subtle,
  /// Standard glass effect for most cards
  standard,
  /// Strong glass effect for modals, dialogs, and overlays
  modal,
}

/// Premium glassmorphism container with frosted-glass effect
/// 
/// Provides a translucent, blurred background with soft borders
/// for a modern, layered UI aesthetic.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final BorderRadiusGeometry? borderRadius;
  final GlassLevel level;
  final Color? customColor;
  final Border? border;
  final List<BoxShadow>? customShadow;

  const GlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.borderRadius,
    this.level = GlassLevel.standard,
    this.customColor,
    this.border,
    this.customShadow,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    
    // Get glass properties based on level
    final glassProps = _getGlassProperties(level, colors);
    
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(AppRadius.xl),
        boxShadow: customShadow ?? glassProps.shadow,
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(AppRadius.xl),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: glassProps.blurAmount,
            sigmaY: glassProps.blurAmount,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: customColor ?? glassProps.backgroundColor,
              borderRadius: borderRadius ?? BorderRadius.circular(AppRadius.xl),
              border: border ?? Border.all(
                color: glassProps.borderColor,
                width: 1,
              ),
            ),
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }

  /// Get glass styling properties based on level
  _GlassProperties _getGlassProperties(GlassLevel level, AppThemeColors colors) {
    switch (level) {
      case GlassLevel.subtle:
        // Subtle glass for nested cards
        return _GlassProperties(
          backgroundColor: const Color(0xFF1E232D).withOpacity(0.60),
          borderColor: Colors.white.withOpacity(0.05),
          blurAmount: 10.0,
          shadow: AppShadows.cardShadow,
        );
        
      case GlassLevel.standard:
        // Standard glass for primary cards
        return _GlassProperties(
          backgroundColor: const Color(0xFF1E232D).withOpacity(0.70),
          borderColor: Colors.white.withOpacity(0.07),
          blurAmount: 12.0,
          shadow: AppShadows.glassShadow,
        );
        
      case GlassLevel.modal:
        // Strong glass for modals and dialogs
        return _GlassProperties(
          backgroundColor: const Color(0xFF1E232D).withOpacity(0.75),
          borderColor: Colors.white.withOpacity(0.08),
          blurAmount: 14.0,
          shadow: AppShadows.glassModalShadow,
        );
    }
  }
}

/// Internal helper class for glass properties
class _GlassProperties {
  final Color backgroundColor;
  final Color borderColor;
  final double blurAmount;
  final List<BoxShadow> shadow;

  const _GlassProperties({
    required this.backgroundColor,
    required this.borderColor,
    required this.blurAmount,
    required this.shadow,
  });
}
