import 'package:flutter/material.dart';
import 'package:total_athlete/theme.dart';

/// A reusable timer display widget used throughout the workout flow.
/// Provides consistent styling for both session timers and rest timers.
class WorkoutTimerDisplay extends StatelessWidget {
  final String timeText;
  final IconData? icon;
  final bool isDark;
  final String? label; // Optional prefix label like "REST"
  final bool isCompact; // If true, uses smaller padding and size

  const WorkoutTimerDisplay({
    super.key,
    required this.timeText,
    this.icon,
    required this.isDark,
    this.label,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: isCompact ? 8 : 12,
      ),
      decoration: BoxDecoration(
        color: colors.primaryAccent,
        borderRadius: BorderRadius.circular(isCompact ? AppRadius.full : AppRadius.md),
      ),
      child: Row(
        mainAxisSize: isCompact ? MainAxisSize.min : MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: isCompact ? 18 : 20,
              color: colors.onPrimary,
            ),
            SizedBox(width: isCompact ? 6 : 8),
          ],
          Text(
            label != null ? '$label $timeText' : timeText,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: colors.onPrimary,
              fontSize: isCompact ? 14 : null,
            ),
          ),
        ],
      ),
    );
  }
}
