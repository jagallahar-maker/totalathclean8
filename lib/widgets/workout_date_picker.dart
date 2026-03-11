import 'package:flutter/material.dart';
import 'package:total_athlete/theme.dart';
import 'package:total_athlete/utils/format_utils.dart';

/// A compact workout date picker widget
/// Shows the current workout date with ability to change it
class WorkoutDatePicker extends StatelessWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateChanged;
  final bool isDark;

  const WorkoutDatePicker({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isToday = _isToday(selectedDate);
    final colors = context.colors;
    
    return InkWell(
      onTap: () => _showDatePicker(context),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: colors.divider,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 16,
              color: colors.secondaryText,
            ),
            const SizedBox(width: 6),
            Text(
              isToday ? 'Today' : FormatUtils.formatDate(selectedDate),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.primaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down_rounded,
              size: 18,
              color: colors.secondaryText,
            ),
          ],
        ),
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  Future<void> _showDatePicker(BuildContext context) async {
    final now = DateTime.now();
    final colors = context.colors;
    
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: this.selectedDate,
      firstDate: DateTime(2020),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: colors.primaryAccent,
              onPrimary: colors.onPrimary,
              surface: colors.surface,
              onSurface: colors.primaryText,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate != null) {
      // Preserve the time from the current selectedDate
      final newDateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        this.selectedDate.hour,
        this.selectedDate.minute,
        this.selectedDate.second,
      );
      onDateChanged(newDateTime);
    }
  }
}
