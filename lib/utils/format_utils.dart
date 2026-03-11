import 'package:intl/intl.dart';

import 'package:total_athlete/utils/unit_conversion.dart';

class FormatUtils {
  /// Format weight with unit conversion
  /// Weight is ALWAYS stored in kg, converted to display unit here
  /// storedUnit parameter is DEPRECATED but kept for backwards compatibility
  static String formatWeight(double weightKg, String displayUnit, {String? storedUnit}) {
    // If storedUnit is provided (old code), convert old data to kg first
    double actualWeightKg = weightKg;
    if (storedUnit != null && storedUnit == 'lb') {
      actualWeightKg = weightKg * 0.453592; // Convert old lb data to kg
    }
    
    final displayWeight = UnitConversion.kgToDisplayUnit(actualWeightKg, displayUnit);
    return '${displayWeight.toStringAsFixed(displayWeight % 1 == 0 ? 0 : 1)} $displayUnit';
  }

  /// Format volume with unit conversion
  /// Volume is ALWAYS stored in kg, converted to display unit here
  /// storedUnit parameter is DEPRECATED but kept for backwards compatibility
  static String formatVolume(double volumeKg, String displayUnit, {String? storedUnit}) {
    // If storedUnit is provided (old code), convert old data to kg first
    double actualVolumeKg = volumeKg;
    if (storedUnit != null && storedUnit == 'lb') {
      actualVolumeKg = volumeKg * 0.453592; // Convert old lb data to kg
    }
    
    final displayVolume = UnitConversion.kgToDisplayUnit(actualVolumeKg, displayUnit);
    return '${(displayVolume / 1000).toStringAsFixed(1)}k $displayUnit';
  }

  static String formatCalories(double calories) => '${calories.toStringAsFixed(0)} kcal';

  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  static String formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today, ${DateFormat('MMM d').format(date)}';
    } else if (dateOnly == yesterday) {
      return 'Yesterday';
    } else if (now.difference(date).inDays < 7) {
      return '${DateFormat('EEEE').format(date)}, ${DateFormat('MMM d').format(date)}';
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }

  static String formatTime(DateTime time) => DateFormat('hh:mm a').format(time);

  static String formatDateWithTime(DateTime dateTime) => '${formatDate(dateTime)}, ${formatTime(dateTime)}';

  static String formatMuscleGroup(String group) {
    return group[0].toUpperCase() + group.substring(1);
  }

  static String formatEquipment(String equipment) {
    return equipment[0].toUpperCase() + equipment.substring(1);
  }
}
