import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:total_athlete/models/user.dart';
import 'package:total_athlete/utils/unit_conversion.dart';

/// Service to migrate user goal weight and current weight data
/// 
/// This service detects and fixes goal/current weights that were saved in pounds
/// but stored as if they were kilograms (missing the lb to kg conversion).
class WeightMigrationService {
  static const String _goalWeightMigrationKey = 'goal_weight_migration_v1_completed';
  static const String _userKey = 'current_user';
  
  /// Run the migration if it hasn't been run before
  static Future<void> runMigrationIfNeeded() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Run goal weight migration
      final goalWeightMigrationCompleted = prefs.getBool(_goalWeightMigrationKey) ?? false;
      if (!goalWeightMigrationCompleted) {
        print('🔄 Running goal weight migration...');
        await _migrateUserGoalWeight();
        await prefs.setBool(_goalWeightMigrationKey, true);
        print('✅ Goal weight migration completed');
      }
    } catch (e) {
      print('⚠️ Migration failed but continuing: $e');
      // Don't block app initialization if migration fails
    }
  }
  
  /// Migrate user's goalWeight and currentWeight to ensure they're stored in kg
  /// 
  /// Detects if weights appear to be stored in pounds and converts them to kg
  static Future<void> _migrateUserGoalWeight() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString(_userKey);
      
      if (userData == null) {
        print('   No user data to migrate');
        return;
      }
      
      final userMap = json.decode(userData) as Map<String, dynamic>;
      final user = User.fromJson(userMap);
      
      bool needsUpdate = false;
      double? migratedGoalWeight = user.goalWeight;
      double? migratedCurrentWeight = user.currentWeight;
      
      // More sophisticated detection: Check if values look like they're stored in pounds
      // Case 1: Value > 200 (obviously too heavy for kg)
      // Case 2: User's preferred unit is lb AND goalWeight seems unreasonable as kg
      //         (e.g., 200 kg would be 440 lb, which is a very uncommon goal)
      // Case 3: GoalWeight is a nice round number in lb range (100-400) and preferredUnit is lb
      
      if (user.goalWeight != null) {
        final shouldMigrate = _looksLikePoundsStoredAsKg(user.goalWeight!) ||
            (user.preferredUnit == 'lb' && user.goalWeight! >= 100 && user.goalWeight! <= 400);
        
        if (shouldMigrate) {
          print('   Detected goalWeight stored in pounds: ${user.goalWeight} lb');
          migratedGoalWeight = UnitConversion.toStorageUnit(user.goalWeight!, 'lb');
          print('   Converted to kg: $migratedGoalWeight kg');
          needsUpdate = true;
        }
      }
      
      // Check if currentWeight looks like it's stored in pounds
      // Only migrate currentWeight if it's > 200 to avoid false positives
      if (user.currentWeight != null && _looksLikePoundsStoredAsKg(user.currentWeight!)) {
        print('   Detected currentWeight stored in pounds: ${user.currentWeight} lb');
        migratedCurrentWeight = UnitConversion.toStorageUnit(user.currentWeight!, 'lb');
        print('   Converted to kg: $migratedCurrentWeight kg');
        needsUpdate = true;
      }
      
      if (needsUpdate) {
        final updatedUser = user.copyWith(
          goalWeight: migratedGoalWeight,
          currentWeight: migratedCurrentWeight,
          updatedAt: DateTime.now(),
        );
        
        await prefs.setString(_userKey, json.encode(updatedUser.toJson()));
        print('   ✅ User weight data migrated successfully');
      } else {
        print('   No migration needed for user weight data');
      }
    } catch (e) {
      print('   ⚠️ Error migrating user goal weight: $e');
    }
  }
  
  /// Detect if a weight value looks like it was incorrectly stored
  /// 
  /// Heuristic: If a weight in "kg" is > 200, it's likely actually in pounds
  /// (since 200+ kg is 440+ lbs, which is very uncommon for most exercises)
  static bool _looksLikePoundsStoredAsKg(double weightInKg) {
    return weightInKg > 200.0;
  }
}
