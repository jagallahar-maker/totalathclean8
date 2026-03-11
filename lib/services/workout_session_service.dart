import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:total_athlete/models/workout.dart';

/// Service for crash-safe workout session state management
/// Persists active workout session data to recover from crashes/interruptions
/// Autosaves after every meaningful action and periodically for video-game-like recovery
class WorkoutSessionService {
  static const String _sessionKey = 'active_workout_session';
  static const String _sessionStartKey = 'session_start_time';
  static const String _lastAutoSaveKey = 'last_autosave_time';
  static const String _restTimerStateKey = 'rest_timer_state';
  static const String _currentExerciseIndexKey = 'current_exercise_index';
  
  /// Minimum time between autosaves to avoid excessive writes
  static const Duration _minAutosaveInterval = Duration(seconds: 2);

  /// Save the current workout session state
  /// This should be called after every meaningful action (set completed, weight/reps changed, etc.)
  /// Throttled to avoid excessive writes (min 2 seconds between saves)
  Future<void> saveSessionState(
    Workout workout, {
    int? currentExerciseIndex,
    Map<String, dynamic>? restTimerState,
    bool force = false,
  }) async {
    if (workout.isCompleted) {
      // Don't save completed workouts as active sessions
      await clearSessionState();
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check throttle (unless forced)
      if (!force) {
        final lastAutoSaveStr = prefs.getString(_lastAutoSaveKey);
        if (lastAutoSaveStr != null) {
          final lastAutoSave = DateTime.parse(lastAutoSaveStr);
          final timeSinceLastSave = DateTime.now().difference(lastAutoSave);
          if (timeSinceLastSave < _minAutosaveInterval) {
            // Too soon since last save - skip to avoid excessive writes
            return;
          }
        }
      }
      
      // Save workout data
      await prefs.setString(_sessionKey, json.encode(workout.toJson()));
      
      // Preserve original start time (never overwrite this during autosave)
      final existingStartTime = prefs.getString(_sessionStartKey);
      if (existingStartTime == null) {
        // First save - record the original start time
        await prefs.setString(_sessionStartKey, workout.startTime.toIso8601String());
      }
      
      // Save current exercise index (for UI restoration)
      if (currentExerciseIndex != null) {
        await prefs.setInt(_currentExerciseIndexKey, currentExerciseIndex);
      }
      
      // Save rest timer state (for recovery)
      if (restTimerState != null) {
        await prefs.setString(_restTimerStateKey, json.encode(restTimerState));
      }
      
      // Record autosave timestamp
      await prefs.setString(_lastAutoSaveKey, DateTime.now().toIso8601String());
      
      debugPrint('💾 Session autosaved: ${workout.name} (${workout.completedSets}/${workout.totalSets} sets)');
    } catch (e) {
      debugPrint('⚠️ Failed to save session state: $e');
    }
  }

  /// Load the saved workout session (if any)
  /// Returns the workout with the ORIGINAL start time preserved, plus additional recovery data
  Future<Map<String, dynamic>?> loadSessionState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionData = prefs.getString(_sessionKey);
      final originalStartTimeStr = prefs.getString(_sessionStartKey);
      
      if (sessionData == null) {
        return null;
      }

      // Parse the workout
      final workoutJson = json.decode(sessionData) as Map<String, dynamic>;
      Workout workout = Workout.fromJson(workoutJson);

      // Restore the ORIGINAL start time if available
      if (originalStartTimeStr != null) {
        final originalStartTime = DateTime.parse(originalStartTimeStr);
        
        // Check if start time was corrupted/changed
        if (workout.startTime.difference(originalStartTime).abs() > const Duration(seconds: 5)) {
          debugPrint('🔧 Restoring original session start time: $originalStartTime');
          workout = workout.copyWith(startTime: originalStartTime);
        }
      }

      // Load additional recovery data
      final currentExerciseIndex = prefs.getInt(_currentExerciseIndexKey);
      
      Map<String, dynamic>? restTimerState;
      final restTimerStateStr = prefs.getString(_restTimerStateKey);
      if (restTimerStateStr != null) {
        restTimerState = json.decode(restTimerStateStr) as Map<String, dynamic>;
      }

      // Get last autosave time for debugging
      final lastAutoSaveStr = prefs.getString(_lastAutoSaveKey);
      Duration? timeSinceLastSave;
      if (lastAutoSaveStr != null) {
        final lastAutoSave = DateTime.parse(lastAutoSaveStr);
        timeSinceLastSave = DateTime.now().difference(lastAutoSave);
        debugPrint('🔄 Recovered session: ${workout.name} (last saved ${_formatDuration(timeSinceLastSave)} ago)');
      }

      return {
        'workout': workout,
        'currentExerciseIndex': currentExerciseIndex,
        'restTimerState': restTimerState,
        'timeSinceLastSave': timeSinceLastSave,
      };
    } catch (e) {
      debugPrint('⚠️ Failed to load session state: $e');
      return null;
    }
  }

  /// Check if there's a recoverable session
  Future<bool> hasRecoverableSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionData = prefs.getString(_sessionKey);
      return sessionData != null;
    } catch (e) {
      return false;
    }
  }

  /// Get session recovery info (for UI display)
  Future<Map<String, dynamic>?> getSessionInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionData = prefs.getString(_sessionKey);
      final originalStartTimeStr = prefs.getString(_sessionStartKey);
      final lastAutoSaveStr = prefs.getString(_lastAutoSaveKey);
      
      if (sessionData == null) {
        return null;
      }

      final workoutJson = json.decode(sessionData) as Map<String, dynamic>;
      final workout = Workout.fromJson(workoutJson);
      
      DateTime? originalStartTime;
      if (originalStartTimeStr != null) {
        originalStartTime = DateTime.parse(originalStartTimeStr);
      }
      
      DateTime? lastAutoSave;
      if (lastAutoSaveStr != null) {
        lastAutoSave = DateTime.parse(lastAutoSaveStr);
      }

      return {
        'workoutId': workout.id,
        'workoutName': workout.name,
        'completedSets': workout.completedSets,
        'totalSets': workout.totalSets,
        'exerciseCount': workout.exercises.length,
        'startTime': originalStartTime ?? workout.startTime,
        'lastAutoSave': lastAutoSave,
        'timeSinceLastSave': lastAutoSave != null 
            ? DateTime.now().difference(lastAutoSave) 
            : null,
      };
    } catch (e) {
      debugPrint('⚠️ Failed to get session info: $e');
      return null;
    }
  }

  /// Check if there's a recoverable session from today that should be prompted
  /// Returns true if session exists and started today (same calendar day)
  Future<bool> shouldPromptRecovery() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionData = prefs.getString(_sessionKey);
      final originalStartTimeStr = prefs.getString(_sessionStartKey);
      
      if (sessionData == null) {
        return false;
      }

      // Check if session started today
      if (originalStartTimeStr != null) {
        final originalStartTime = DateTime.parse(originalStartTimeStr);
        final now = DateTime.now();
        
        // Check if same calendar day
        final isSameDay = originalStartTime.year == now.year &&
                          originalStartTime.month == now.month &&
                          originalStartTime.day == now.day;
        
        return isSameDay;
      }

      return false;
    } catch (e) {
      debugPrint('⚠️ Failed to check if should prompt recovery: $e');
      return false;
    }
  }

  /// Clear the saved session state
  /// Call this when workout is completed or discarded
  Future<void> clearSessionState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sessionKey);
      await prefs.remove(_sessionStartKey);
      await prefs.remove(_lastAutoSaveKey);
      await prefs.remove(_restTimerStateKey);
      await prefs.remove(_currentExerciseIndexKey);
      debugPrint('🗑️ Session state cleared');
    } catch (e) {
      debugPrint('⚠️ Failed to clear session state: $e');
    }
  }

  /// Get the original session start time
  /// Returns null if no active session
  Future<DateTime?> getOriginalStartTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final startTimeStr = prefs.getString(_sessionStartKey);
      if (startTimeStr != null) {
        return DateTime.parse(startTimeStr);
      }
      return null;
    } catch (e) {
      debugPrint('⚠️ Failed to get original start time: $e');
      return null;
    }
  }

  /// Update the session start time (use with caution)
  /// This should only be used when the user explicitly changes the workout date
  Future<void> updateStartTime(DateTime newStartTime) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_sessionStartKey, newStartTime.toIso8601String());
      debugPrint('📅 Session start time updated: $newStartTime');
    } catch (e) {
      debugPrint('⚠️ Failed to update start time: $e');
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
}
