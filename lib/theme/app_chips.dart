import 'package:flutter/material.dart';
import 'package:total_athlete/theme.dart';
import 'package:total_athlete/theme/theme_tokens.dart';

/// Centralized filter chip component that follows the active theme
/// 
/// Provides consistent styling for all filter chips across the app:
/// - Selected state: uses theme accent gradient/color with white text
/// - Unselected state: uses card background with subtle border
/// - Hover/Press: animated elevation and brightness changes
class AppFilterChip extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final double? fontSize;
  
  const AppFilterChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.padding,
    this.fontSize,
  });

  @override
  State<AppFilterChip> createState() => _AppFilterChipState();
}

class _AppFilterChipState extends State<AppFilterChip> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    
    // Determine background styling based on selection state
    final Color? backgroundColor;
    final Gradient? gradient;
    
    if (widget.selected) {
      // Selected: use gradient if available, otherwise solid accent color
      backgroundColor = tokens.chipSelectedGradient != null ? null : tokens.chipSelectedBackground;
      gradient = tokens.chipSelectedGradient;
    } else {
      // Unselected: use chip background token
      backgroundColor = tokens.chipBackground;
      gradient = null;
    }
    
    // Text color based on selection
    final textColor = widget.selected ? tokens.chipSelectedText : tokens.chipText;
    
    // Border based on selection
    final borderColor = widget.selected ? Colors.transparent : tokens.chipBorder;
    
    // Shadow/elevation based on pressed state
    final boxShadow = _isPressed 
        ? AppShadows.buttonPressed 
        : (widget.selected ? AppShadows.cardShadow : <BoxShadow>[]);
    
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: backgroundColor,
          gradient: gradient,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: borderColor,
            width: 1,
          ),
          boxShadow: boxShadow,
        ),
        child: Text(
          widget.label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: textColor,
            fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w500,
            fontSize: widget.fontSize,
          ),
        ),
      ),
    );
  }
}

/// Compact filter chip variant for smaller spaces
class AppFilterChipCompact extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  
  const AppFilterChipCompact({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppFilterChip(
      label: label,
      selected: selected,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      fontSize: 12,
    );
  }
}
