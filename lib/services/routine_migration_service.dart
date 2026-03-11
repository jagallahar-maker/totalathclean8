import 'package:total_athlete/services/routine_service.dart';
import 'package:total_athlete/services/exercise_service.dart';
import 'package:total_athlete/models/routine.dart';
import 'package:flutter/foundation.dart';

class RoutineMigrationService {
  final RoutineService _routineService;
  final ExerciseService _exerciseService;

  RoutineMigrationService({
    required RoutineService routineService,
    required ExerciseService exerciseService,
  }) : _routineService = routineService,
       _exerciseService = exerciseService;

  /// Updates existing Pull Day routine to new exercise list
  Future<void> updatePullDayRoutine() async {
    try {
      final routines = await _routineService.getAllRoutines();
      final exercises = await _exerciseService.getAllExercises();
      
      // Find the Pull Day routine
      final pullDayRoutine = routines.where((r) => r.name == 'Pull Day').firstOrNull;
      
      if (pullDayRoutine == null) {
        debugPrint('No Pull Day routine found to update');
        return;
      }

      // New exercise list for Pull Day (in order)
      final newExerciseNames = [
        'Pull-Ups',
        'Hammer Strength Row',
        'Smith Machine Row',
        'Barbell Curl',
        'Preacher Curl',
        'Face Pulls',
      ];

      // Find exercise IDs
      final newExerciseIds = <String>[];
      final missingExercises = <String>[];
      
      for (final name in newExerciseNames) {
        final exercise = exercises.where((e) => e.name == name).firstOrNull;
        if (exercise != null) {
          newExerciseIds.add(exercise.id);
        } else {
          missingExercises.add(name);
          debugPrint('⚠️ Exercise "$name" not found in library - skipping');
        }
      }

      if (newExerciseIds.isEmpty) {
        debugPrint('❌ Error: No exercises found for Pull Day update');
        return;
      }
      
      if (missingExercises.isNotEmpty) {
        debugPrint('⚠️ Pull Day update: ${missingExercises.length} exercise(s) not found: ${missingExercises.join(", ")}');
      }

      // Update the routine
      final updatedRoutine = pullDayRoutine.copyWith(
        exerciseIds: newExerciseIds,
        updatedAt: DateTime.now(),
      );

      await _routineService.updateRoutine(updatedRoutine);
      debugPrint('✅ Pull Day routine updated successfully with ${newExerciseIds.length} exercises');
    } catch (e) {
      debugPrint('Failed to update Pull Day routine: $e');
    }
  }
}
