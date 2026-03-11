import 'package:total_athlete/models/exercise.dart';
import 'package:total_athlete/models/workout_set.dart';
import 'package:total_athlete/models/workout_exercise.dart';

/// Service for calculating smart progressive overload suggestions
class ProgressiveOverloadService {
  /// Calculate the recommended weight for the next set based on:
  /// 1. Previous set in current workout
  /// 2. Exercise history (last workout performance)
  /// 3. Exercise type and equipment
  /// 4. Rep range
  static double getNextSetWeight({
    required Exercise exercise,
    required List<WorkoutSet> currentSets,
    WorkoutExercise? lastWorkoutPerformance,
    required int setIndex,
  }) {
    // If this is the first set, use history or defaults
    if (currentSets.isEmpty) {
      return _getFirstSetWeight(exercise, lastWorkoutPerformance);
    }

    // Get the previous set (most recently entered)
    final previousSet = currentSets.last;
    
    // If user already manually edited this weight, don't auto-fill
    // (This check would be done by caller based on set state)
    
    // For sets after the first, apply progression based on set number
    return _getProgressiveWeight(
      exercise: exercise,
      previousSet: previousSet,
      currentSetIndex: setIndex,
      totalSetsPlanned: currentSets.length + 1,
      lastWorkoutPerformance: lastWorkoutPerformance,
    );
  }

  /// Calculate recommended reps for the next set
  static int getNextSetReps({
    required Exercise exercise,
    required List<WorkoutSet> currentSets,
    WorkoutExercise? lastWorkoutPerformance,
  }) {
    // If this is the first set, use history or defaults
    if (currentSets.isEmpty) {
      return _getFirstSetReps(exercise, lastWorkoutPerformance);
    }

    // For subsequent sets, keep same reps unless doing a pyramid/drop set scheme
    final previousSet = currentSets.last;
    return previousSet.reps;
  }

  /// Get weight for the first set based on last workout or defaults
  /// Returns weight in KG (internal storage format)
  static double _getFirstSetWeight(Exercise exercise, WorkoutExercise? lastWorkoutPerformance) {
    // If we have history, use the first working set from last time
    if (lastWorkoutPerformance != null && lastWorkoutPerformance.sets.isNotEmpty) {
      // Find the most common weight used (working weight)
      final weightCounts = <double, int>{};
      for (final set in lastWorkoutPerformance.sets) {
        if (set.isCompleted && set.weightKg > 0) {
          weightCounts[set.weightKg] = (weightCounts[set.weightKg] ?? 0) + 1;
        }
      }
      
      if (weightCounts.isNotEmpty) {
        // Return the most frequently used weight (working weight)
        final sortedWeights = weightCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        
        final lastWorkingWeight = sortedWeights.first.key;
        
        // Apply small progression if user hit target reps consistently last time
        final workingSets = lastWorkoutPerformance.sets.where((s) => s.weightKg == lastWorkingWeight).toList();
        if (workingSets.isNotEmpty) {
          final avgReps = workingSets.map((s) => s.reps).reduce((a, b) => a + b) / workingSets.length;
          final minReps = workingSets.map((s) => s.reps).reduce((a, b) => a < b ? a : b);
          
          // If all sets hit 8+ reps, suggest slight increase
          if (minReps >= 8 && avgReps >= 10) {
            return _applySmallIncrement(lastWorkingWeight, exercise);
          }
        }
        
        return lastWorkingWeight;
      }
    }

    // No history - return sensible defaults by exercise category (in KG)
    return _getDefaultStartingWeight(exercise);
  }

  /// Get reps for the first set based on last workout or defaults
  static int _getFirstSetReps(Exercise exercise, WorkoutExercise? lastWorkoutPerformance) {
    // If we have history, use the average reps from working sets
    if (lastWorkoutPerformance != null && lastWorkoutPerformance.sets.isNotEmpty) {
      // Find working sets (most common weight)
      final weightCounts = <double, int>{};
      for (final set in lastWorkoutPerformance.sets) {
        if (set.isCompleted && set.weightKg > 0) {
          weightCounts[set.weightKg] = (weightCounts[set.weightKg] ?? 0) + 1;
        }
      }
      
      if (weightCounts.isNotEmpty) {
        final sortedWeights = weightCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final workingWeight = sortedWeights.first.key;
        
        final workingSets = lastWorkoutPerformance.sets.where((s) => s.weightKg == workingWeight).toList();
        if (workingSets.isNotEmpty) {
          // Return the first set's reps from last workout
          return workingSets.first.reps;
        }
      }
    }

    // No history - return sensible rep default
    return _getDefaultReps(exercise);
  }

  /// Calculate progressive weight for sets beyond the first
  /// Returns weight in KG (internal storage format)
  static double _getProgressiveWeight({
    required Exercise exercise,
    required WorkoutSet previousSet,
    required int currentSetIndex,
    required int totalSetsPlanned,
    WorkoutExercise? lastWorkoutPerformance,
  }) {
    final previousWeight = previousSet.weightKg;
    
    // Determine if we should increase weight (pyramid up) or keep same
    // Most common schemes:
    // - Straight sets: same weight across all sets
    // - Pyramid: increase weight, decrease reps
    // - Reverse pyramid: decrease weight, increase reps
    
    // Default: straight sets (same weight)
    // Only increase for compound lifts on early sets
    if (currentSetIndex <= 2 && _isHeavyCompoundLift(exercise)) {
      // On set 2 or 3, might do a small pyramid if doing strength work (low reps)
      if (previousSet.reps <= 6) {
        return previousWeight + _getIncrementAmount(previousWeight, exercise);
      }
    }
    
    // Keep same weight for most sets
    return previousWeight;
  }

  /// Apply a small increment for progressive overload
  static double _applySmallIncrement(double currentWeight, Exercise exercise) {
    return currentWeight + _getIncrementAmount(currentWeight, exercise);
  }

  /// Get the appropriate increment amount based on exercise type and current weight
  static double _getIncrementAmount(double currentWeight, Exercise exercise) {
    // Determine increment based on exercise category and equipment
    final category = exercise.calorieCategory;
    final equipment = exercise.equipment;
    
    // Compound lower body: larger increments (10 lb / 5 kg)
    if (category == CalorieCategory.compoundLowerBody) {
      if (equipment == EquipmentType.barbell || equipment == EquipmentType.smithMachine) {
        return currentWeight < 100 ? 5.0 : 10.0; // 5kg for lighter, 10kg for heavier
      } else {
        return 5.0; // Dumbbells, machines
      }
    }
    
    // Compound upper body: medium increments (5 lb / 2.5 kg)
    if (category == CalorieCategory.compoundUpperBody) {
      if (equipment == EquipmentType.barbell || equipment == EquipmentType.smithMachine) {
        return 2.5;
      } else {
        return 2.5; // Dumbbells (smallest increment available)
      }
    }
    
    // Isolation and machine: small increments (2.5 lb / 1-2 machine pins)
    // Machines typically increment by 5-10 lb plates, but we'll use 2.5 as base
    if (equipment == EquipmentType.machine || equipment == EquipmentType.cable) {
      return currentWeight < 50 ? 2.5 : 5.0; // Smaller increments for lighter weights
    }
    
    // Bodyweight: minimal increment (add 2.5 kg plate for weighted exercises)
    if (equipment == EquipmentType.bodyweight) {
      return 2.5;
    }
    
    // Default: 2.5 kg increment
    return 2.5;
  }

  /// Get default starting weight for an exercise with no history
  static double _getDefaultStartingWeight(Exercise exercise) {
    final category = exercise.calorieCategory;
    final equipment = exercise.equipment;
    
    // Compound lower body
    if (category == CalorieCategory.compoundLowerBody) {
      if (equipment == EquipmentType.barbell) {
        return 60.0; // Empty bar (20kg) + light plates
      } else if (equipment == EquipmentType.smithMachine) {
        return 40.0; // Smith bar is lighter
      } else if (equipment == EquipmentType.machine) {
        return 50.0; // Machine leg press, hack squat
      } else {
        return 15.0; // Dumbbell lunges, goblet squats
      }
    }
    
    // Compound upper body
    if (category == CalorieCategory.compoundUpperBody) {
      if (equipment == EquipmentType.barbell) {
        return 40.0; // Bench press, rows
      } else if (equipment == EquipmentType.smithMachine) {
        return 30.0;
      } else if (equipment == EquipmentType.machine) {
        return 40.0;
      } else if (equipment == EquipmentType.dumbbell) {
        return 12.5; // Per dumbbell
      } else if (equipment == EquipmentType.bodyweight) {
        return 0.0; // Pull-ups, dips start at bodyweight
      } else {
        return 30.0;
      }
    }
    
    // Isolation
    if (category == CalorieCategory.isolation) {
      if (equipment == EquipmentType.machine || equipment == EquipmentType.cable) {
        return 20.0;
      } else if (equipment == EquipmentType.dumbbell) {
        return 7.5;
      } else {
        return 10.0;
      }
    }
    
    // Bodyweight/core
    if (category == CalorieCategory.bodyweightCore) {
      return 0.0; // Start with bodyweight
    }
    
    // Default
    return 20.0;
  }

  /// Get default rep count for an exercise
  static int _getDefaultReps(Exercise exercise) {
    final category = exercise.calorieCategory;
    
    // Compound lifts: moderate reps (8-10)
    if (category == CalorieCategory.compoundLowerBody || 
        category == CalorieCategory.compoundUpperBody) {
      return 8;
    }
    
    // Isolation: higher reps (10-12)
    if (category == CalorieCategory.isolation) {
      return 10;
    }
    
    // Bodyweight/core: higher reps or time-based
    if (category == CalorieCategory.bodyweightCore) {
      return 12;
    }
    
    return 10; // Default
  }

  /// Check if this is a heavy compound lift that might use pyramid schemes
  static bool _isHeavyCompoundLift(Exercise exercise) {
    return (exercise.calorieCategory == CalorieCategory.compoundLowerBody ||
            exercise.calorieCategory == CalorieCategory.compoundUpperBody) &&
           (exercise.equipment == EquipmentType.barbell ||
            exercise.equipment == EquipmentType.smithMachine);
  }

  /// Round weight to nearest practical increment (2.5 kg / 5 lb)
  static double roundToNearestIncrement(double weight, {double increment = 2.5}) {
    return (weight / increment).round() * increment;
  }
}
