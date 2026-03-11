import 'package:flutter/material.dart';
import 'package:total_athlete/theme.dart';
import 'package:total_athlete/theme/theme_tokens.dart';

/// Badge component for status indicators
/// 
/// Used for displaying counts, status, or labels
class AppBadge extends StatelessWidget {
  final String label;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;
  final BadgeVariant variant;
  final bool small;
  
  const AppBadge({
    super.key,
    required this.label,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.variant = BadgeVariant.neutral,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    
    // Determine colors based on variant
    final Color effectiveBackgroundColor;
    final Color effectiveTextColor;
    
    switch (variant) {
      case BadgeVariant.success:
        effectiveBackgroundColor = backgroundColor ?? tokens.success.withOpacity(0.15);
        effectiveTextColor = textColor ?? tokens.success;
        break;
      case BadgeVariant.warning:
        effectiveBackgroundColor = backgroundColor ?? tokens.warning.withOpacity(0.15);
        effectiveTextColor = textColor ?? tokens.warning;
        break;
      case BadgeVariant.danger:
        effectiveBackgroundColor = backgroundColor ?? tokens.danger.withOpacity(0.15);
        effectiveTextColor = textColor ?? tokens.danger;
        break;
      case BadgeVariant.info:
        effectiveBackgroundColor = backgroundColor ?? tokens.info.withOpacity(0.15);
        effectiveTextColor = textColor ?? tokens.info;
        break;
      case BadgeVariant.accent:
        effectiveBackgroundColor = backgroundColor ?? tokens.accentSolid.withOpacity(0.15);
        effectiveTextColor = textColor ?? tokens.accentSolid;
        break;
      case BadgeVariant.neutral:
      default:
        effectiveBackgroundColor = backgroundColor ?? tokens.cardBackground;
        effectiveTextColor = textColor ?? tokens.textSecondary;
        break;
    }
    
    final fontSize = small ? 11.0 : 13.0;
    final horizontalPadding = small ? 8.0 : 12.0;
    final verticalPadding = small ? 4.0 : 6.0;
    final iconSize = small ? 12.0 : 14.0;
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        color: effectiveBackgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(
          color: tokens.borderSubtle,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: iconSize,
              color: effectiveTextColor,
            ),
            SizedBox(width: small ? 4 : 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: effectiveTextColor,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Pill-shaped badge with accent background
/// 
/// Used for category tags, workout types, etc.
class AppPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;
  
  const AppPill({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    
    final backgroundColor = selected 
        ? tokens.accentSolid.withOpacity(0.2) 
        : tokens.cardBackground;
    final textColor = selected ? tokens.accentSolid : tokens.textSecondary;
    final borderColor = selected ? tokens.accentSolid : tokens.borderSubtle;
    
    Widget content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: textColor),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
    
    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: content,
      );
    }
    
    return content;
  }
}

/// Count badge (circular badge with number)
/// 
/// Used for notification counts, set numbers, etc.
class AppCountBadge extends StatelessWidget {
  final int count;
  final Color? backgroundColor;
  final Color? textColor;
  final double size;
  
  const AppCountBadge({
    super.key,
    required this.count,
    this.backgroundColor,
    this.textColor,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    
    final effectiveBackgroundColor = backgroundColor ?? tokens.accentSolid;
    final effectiveTextColor = textColor ?? tokens.textOnAccent;
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: effectiveBackgroundColor,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        count > 99 ? '99+' : count.toString(),
        style: TextStyle(
          color: effectiveTextColor,
          fontSize: size * 0.5,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}

/// Badge variant types
enum BadgeVariant {
  neutral,
  success,
  warning,
  danger,
  info,
  accent,
}
