/// Utility class for weight unit conversions
/// 
/// STORAGE MODEL: All weights are stored internally in KILOGRAMS ONLY.
/// Conversion happens ONLY at the UI layer for display purposes.
class UnitConversion {
  static const double kgToLbRatio = 2.20462;
  static const double lbToKgRatio = 0.453592;

  /// Convert kilograms to display unit (kg or lb)
  /// This is the PRIMARY method for UI display
  static double kgToDisplayUnit(double weightKg, String displayUnit) {
    if (displayUnit == 'lb') {
      return weightKg * kgToLbRatio;
    }
    return weightKg; // Already in kg
  }

  /// Convert user input (in their preferred unit) to kilograms for storage
  /// This is the PRIMARY method for saving user input
  static double inputToKg(double inputWeight, String inputUnit) {
    if (inputUnit == 'lb') {
      return inputWeight * lbToKgRatio;
    }
    return inputWeight; // Already in kg
  }

  /// Format weight for display with unit label
  /// Takes weight in KG and converts to display unit
  static String formatWeightFromKg(double weightKg, String displayUnit, {int decimals = 1}) {
    final displayWeight = kgToDisplayUnit(weightKg, displayUnit);
    return '${displayWeight.toStringAsFixed(decimals)} $displayUnit';
  }

  /// Get plate weights for the given unit
  static List<double> getPlateWeights(String unit) {
    if (unit == 'lb') {
      return [45, 35, 25, 10, 5, 2.5];
    }
    return [25, 20, 15, 10, 5, 2.5, 1.25];
  }

  /// Get bar weight for the given unit (returns value in KG)
  static double getBarWeightKg(String displayUnit) {
    if (displayUnit == 'lb') {
      return 45.0 * lbToKgRatio; // Convert 45 lb bar to kg
    }
    return 20.0; // 20 kg bar
  }

  /// DEPRECATED: Legacy method for backwards compatibility
  /// Use kgToDisplayUnit instead
  @Deprecated('Use kgToDisplayUnit instead')
  static double toDisplayUnit(double weightInKg, String preferredUnit) {
    return kgToDisplayUnit(weightInKg, preferredUnit);
  }

  /// DEPRECATED: Legacy method for backwards compatibility
  /// Use inputToKg instead
  @Deprecated('Use inputToKg instead')
  static double toStorageUnit(double displayWeight, String preferredUnit) {
    return inputToKg(displayWeight, preferredUnit);
  }

  /// DEPRECATED: Old conversion method - weights are now always stored in kg
  @Deprecated('Weights are always stored in kg - use kgToDisplayUnit or inputToKg')
  static double convert(double weight, String fromUnit, String toUnit) {
    if (fromUnit == toUnit) return weight;
    
    if (fromUnit == 'kg' && toUnit == 'lb') {
      return weight * kgToLbRatio;
    } else if (fromUnit == 'lb' && toUnit == 'kg') {
      return weight * lbToKgRatio;
    }
    return weight;
  }

  /// DEPRECATED: Old method - use kgToDisplayUnit instead
  @Deprecated('Use kgToDisplayUnit instead')
  static double getDisplayWeight(double storedWeight, String storedUnit, String displayUnit) {
    // For backwards compatibility during migration
    if (storedUnit == 'lb') {
      storedWeight = storedWeight * lbToKgRatio; // Convert to kg first
    }
    return kgToDisplayUnit(storedWeight, displayUnit);
  }

  /// DEPRECATED: Old method
  @Deprecated('Weights are always in kg now')
  static double toKg(double weight, String unit) {
    return inputToKg(weight, unit);
  }

  /// DEPRECATED: Old method
  @Deprecated('Weights are always in kg now')
  static String formatWeight(double storedWeight, String storedUnit, String displayUnit, {int decimals = 1}) {
    // For backwards compatibility during migration
    if (storedUnit == 'lb') {
      storedWeight = storedWeight * lbToKgRatio; // Convert to kg first
    }
    return formatWeightFromKg(storedWeight, displayUnit, decimals: decimals);
  }
}
