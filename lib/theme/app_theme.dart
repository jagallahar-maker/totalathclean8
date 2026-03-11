import 'dart:ui';

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:total_athlete/theme.dart';
import 'package:total_athlete/theme/theme_tokens.dart';

/// Card elevation levels for glassmorphism styling
enum CardLevel {
  /// Subtle glass for nested cards/secondary surfaces (60% opacity, 10px blur)
  subtle,
  
  /// Standard glass for main cards (70% opacity, 20px blur) - DEFAULT
  standard,
  
  /// Elevated glass for modals and overlays (80% opacity, 30px blur)
  elevated,
  
  /// Flat glass without blur - just translucent background
  flat,
  
  /// Full glassmorphism effect with blur (alias for standard)
  glass,
}

/// Unified app card component with consistent styling
/// 
/// Supports glassmorphism, gradients, and consistent padding/borders
class AppCard extends StatelessWidget {
  final CardLevel level;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Gradient? gradient;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? boxShadow;
  
  const AppCard({
    super.key,
    this.level = CardLevel.standard,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.onTap,
    this.backgroundColor,
    this.gradient,
    this.borderRadius,
    this.boxShadow,
  });
  
  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    
    // Determine opacity and blur based on card level
    final double opacity;
    final double blur;
    
    switch (level) {
      case CardLevel.subtle:
        opacity = 0.6;
        blur = 10;
        break;
      case CardLevel.standard:
      case CardLevel.glass:
        opacity = 0.7;
        blur = 20;
        break;
      case CardLevel.elevated:
        opacity = 0.8;
        blur = 30;
        break;
      case CardLevel.flat:
        opacity = 1.0;
        blur = 0;
        break;
    }
    
    // Use gradient if available, otherwise solid color
    final effectiveGradient = gradient ?? tokens.cardGradient;
    final effectiveBackgroundColor = backgroundColor ?? 
      (effectiveGradient == null ? tokens.cardBackground.withOpacity(opacity) : null);
    
    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(AppRadius.md);
    final effectiveBoxShadow = boxShadow ?? AppShadows.glassShadow;
    final effectivePadding = padding ?? AppSpacing.paddingMd;
    
    Widget card = Container(
      width: width,
      height: height,
      margin: margin,
      padding: effectivePadding,
      decoration: BoxDecoration(
        color: effectiveBackgroundColor,
        gradient: effectiveGradient,
        borderRadius: effectiveBorderRadius,
        border: Border.all(
          color: tokens.cardBorder,
          width: 1,
        ),
        boxShadow: effectiveBoxShadow,
      ),
      child: child,
    );
    
    // Wrap with ClipRRect and BackdropFilter if blur is needed
    if (blur > 0 && level != CardLevel.flat) {
      card = ClipRRect(
        borderRadius: effectiveBorderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: card,
        ),
      );
    }
    
    // Wrap with InkWell if tappable
    if (onTap != null) {
      card = InkWell(
        onTap: onTap,
        borderRadius: effectiveBorderRadius,
        child: card,
      );
    }
    
    return card;
  }
}
