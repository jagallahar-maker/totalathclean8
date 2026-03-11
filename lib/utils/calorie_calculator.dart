import 'package:total_athlete/models/exercise.dart';
import 'package:total_athlete/models/workout.dart';
import 'package:total_athlete/models/workout_exercise.dart';
import 'package:total_athlete/models/workout_set.dart';
import 'package:total_athlete/utils/unit_conversion.dart';

/// Realistic calorie estimation for resistance training
/// 
/// Calculates calories based on:
/// 1. Volume-based work (weight × reps × sets)
/// 2. Time-based baseline metabolic expenditure
/// 3. Exercise intensity factors
class CalorieCalculator {
  /// Calculate estimated calories burned for an entire workout
  static double calculateWorkoutCalories(
    Workout workout, {
    double? userBodyweightKg,
  }) {
    // Calculate volume-based calories
    double volumeBasedCalories = 0.0;
    
    for (final exercise in workout.exercises) {
      volumeBasedCalories += calculateExerciseCalories(
        exercise,
        userBodyweightKg: userBodyweightKg,
      );
    }
    
    // Add time-based baseline metabolic expenditure
    // Resistance training burns ~4-6 kcal per minute on average
    // Use 5 kcal/min as baseline for rest periods and setup
    final durationMinutes = workout.duration.inMinutes;
    final timeBasedCalories = durationMinutes * 5.0;
    
    // Combine both components
    // Volume captures intensity, time captures rest/setup
    final totalCalories = volumeBasedCalories + timeBasedCalories;
    
    return totalCalories;
  }
  
  /// Calculate estimated calories burned for a single exercise
  static double calculateExerciseCalories(
    WorkoutExercise workoutExercise, {
    double? userBodyweightKg,
  }) {
    final exercise = workoutExercise.exercise;
    final completedSets = workoutExercise.sets.where((set) => 
      set.isCompleted && set.weightKg > 0 && set.reps > 0
    ).toList();
    
    if (completedSets.isEmpty) return 0.0;
    
    // Calculate total volume for this exercise
    double totalVolumeLb = 0.0;
    
    for (final set in completedSets) {
      // Convert weights from kg to pounds for consistent calculation
      final weightLb = UnitConversion.kgToDisplayUnit(set.weightKg, 'lb');
      final volume = weightLb * set.reps;
      totalVolumeLb += volume;
    }
    
    // Get multiplier based on exercise type
    final multiplier = _getExerciseMultiplier(exercise);
    
    // Calculate calories: volume × multiplier
    return totalVolumeLb * multiplier;
  }
  
  /// Get calorie multiplier based on exercise calorie category
  /// 
  /// Updated multipliers per category (applied to total volume in lb):
  /// - Compound Lower Body: 0.012 (highest calorie burn)
  /// - Compound Upper Body: 0.010
  /// - Isolation: 0.008
  /// - Bodyweight/Core: 0.007
  /// 
  /// These multipliers produce realistic totals:
  /// Example 1: Upper body workout
  /// - Bench Press: 225 lb × 8 reps × 4 sets = 7,200 lb → 72 kcal
  /// - Rows: 185 lb × 10 reps × 4 sets = 7,400 lb → 74 kcal
  /// - Shoulder Press: 135 lb × 10 reps × 3 sets = 4,050 lb → 40.5 kcal
  /// - Curls: 65 lb × 12 reps × 3 sets = 2,340 lb → 18.7 kcal
  /// - Total volume calories: ~205 kcal
  /// - Plus 45 min × 5 kcal/min: 225 kcal
  /// - Total: ~430 kcal (realistic for 45min upper body workout)
  /// 
  /// Example 2: Leg workout
  /// - Squats: 315 lb × 6 reps × 5 sets = 9,450 lb → 113 kcal
  /// - RDL: 225 lb × 8 reps × 4 sets = 7,200 lb → 86 kcal
  /// - Leg Press: 405 lb × 10 reps × 3 sets = 12,150 lb → 146 kcal
  /// - Leg Curls: 120 lb × 12 reps × 3 sets = 4,320 lb → 34.5 kcal
  /// - Total volume calories: ~380 kcal
  /// - Plus 50 min × 5 kcal/min: 250 kcal
  /// - Total: ~630 kcal (realistic for 50min leg workout)
  static double _getExerciseMultiplier(Exercise exercise) {
    // Use the calorie category to determine multiplier
    switch (exercise.calorieCategory) {
      case CalorieCategory.compoundLowerBody:
        return 0.012; // Highest calorie burn (squats, deadlifts, etc.)
      case CalorieCategory.compoundUpperBody:
        return 0.010; // High calorie burn (bench, rows, etc.)
      case CalorieCategory.isolation:
        return 0.008; // Moderate calorie burn (curls, extensions, etc.)
      case CalorieCategory.bodyweightCore:
        return 0.007; // Lower calorie burn (planks, crunches, etc.)
    }
  }
  
  /// Calculate average calories per minute for the workout
  /// Useful for displaying workout intensity
  static double calculateCaloriesPerMinute(Workout workout, {double? userBodyweightKg}) {
    final totalCalories = calculateWorkoutCalories(workout, userBodyweightKg: userBodyweightKg);
    final durationMinutes = workout.duration.inMinutes;
    
    if (durationMinutes <= 0) return 0.0;
    return totalCalories / durationMinutes;
  }
}
