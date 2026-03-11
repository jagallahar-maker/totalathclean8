import 'package:flutter/material.dart';
import 'package:total_athlete/theme.dart';
import 'package:total_athlete/theme/theme_tokens.dart';

/// Primary button with accent gradient/color
/// 
/// Used for primary actions like "Start Workout", "Save", "Finish"
class AppPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final EdgeInsetsGeometry? padding;
  final double? width;
  
  const AppPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.padding,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    
    final gradient = tokens.buttonGradient ?? tokens.accentGradient;
    final backgroundColor = gradient == null ? tokens.accentSolid : null;
    
    return Container(
      width: width,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: onPressed == null ? [] : AppShadows.cardShadow,
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: tokens.textOnAccent,
          elevation: 0,
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          disabledBackgroundColor: tokens.cardBackground,
          disabledForegroundColor: tokens.textMuted,
        ),
        child: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(tokens.textOnAccent),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(label),
                ],
              ),
      ),
    );
  }
}

/// Secondary button with outline style
/// 
/// Used for secondary actions like "Cancel", "Skip"
class AppSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final EdgeInsetsGeometry? padding;
  final double? width;
  
  const AppSecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.padding,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    
    return SizedBox(
      width: width,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: tokens.accentSolid,
          side: BorderSide(
            color: onPressed == null ? tokens.borderSubtle : tokens.accentSolid,
            width: 1.5,
          ),
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          disabledForegroundColor: tokens.textMuted,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20),
              const SizedBox(width: 8),
            ],
            Text(label),
          ],
        ),
      ),
    );
  }
}

/// Text button without background
/// 
/// Used for tertiary actions like "Learn More", "View All"
class AppTextButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final EdgeInsetsGeometry? padding;
  
  const AppTextButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: tokens.accentSolid,
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        disabledForegroundColor: tokens.textMuted,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18),
            const SizedBox(width: 6),
          ],
          Text(label),
        ],
      ),
    );
  }
}

/// Icon button with circular background
/// 
/// Used for single-icon actions like close, menu, info
class AppIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double size;
  final bool useAccent;
  
  const AppIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.size = 40,
    this.useAccent = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    
    final effectiveBackgroundColor = backgroundColor ?? 
        (useAccent ? tokens.accentSolid : tokens.cardBackground);
    final effectiveForegroundColor = foregroundColor ?? 
        (useAccent ? tokens.textOnAccent : tokens.icon);
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: effectiveBackgroundColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: tokens.borderSubtle,
          width: 1,
        ),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: size * 0.5),
        color: effectiveForegroundColor,
        padding: EdgeInsets.zero,
      ),
    );
  }
}

/// Floating action button with accent gradient
/// 
/// Used for primary floating actions
class AppFAB extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? label;
  final bool mini;
  
  const AppFAB({
    super.key,
    required this.icon,
    this.onPressed,
    this.label,
    this.mini = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    
    final gradient = tokens.buttonGradient ?? tokens.accentGradient;
    
    if (label != null) {
      // Extended FAB
      return Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppShadows.glassShadow,
        ),
        child: FloatingActionButton.extended(
          onPressed: onPressed,
          backgroundColor: gradient == null ? tokens.accentSolid : Colors.transparent,
          foregroundColor: tokens.textOnAccent,
          elevation: 0,
          icon: Icon(icon),
          label: Text(label!),
        ),
      );
    }
    
    // Regular FAB
    return Container(
      decoration: BoxDecoration(
        gradient: gradient,
        shape: BoxShape.circle,
        boxShadow: AppShadows.glassShadow,
      ),
      child: FloatingActionButton(
        onPressed: onPressed,
        mini: mini,
        backgroundColor: gradient == null ? tokens.accentSolid : Colors.transparent,
        foregroundColor: tokens.textOnAccent,
        elevation: 0,
        child: Icon(icon),
      ),
    );
  }
}
