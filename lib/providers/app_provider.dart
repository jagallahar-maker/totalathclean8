import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:total_athlete/models/user.dart';
import 'package:total_athlete/models/workout.dart';
import 'package:total_athlete/models/workout_set.dart';
import 'package:total_athlete/models/exercise.dart';
import 'package:total_athlete/models/bodyweight_log.dart';
import 'package:total_athlete/models/personal_record.dart';
import 'package:total_athlete/models/routine.dart';
import 'package:total_athlete/models/training_program.dart';
import 'package:total_athlete/models/dashboard_config.dart';
import 'package:total_athlete/models/theme_config.dart';
import 'package:total_athlete/services/user_service.dart';
import 'package:total_athlete/services/workout_service.dart';
import 'package:total_athlete/services/exercise_service.dart';
import 'package:total_athlete/services/bodyweight_service.dart';
import 'package:total_athlete/services/personal_record_service.dart';
import 'package:total_athlete/services/routine_service.dart';
import 'package:total_athlete/services/training_program_service.dart';
import 'package:total_athlete/services/weight_migration_service.dart';
import 'package:total_athlete/services/user_migration_service.dart';
import 'package:total_athlete/services/crashlytics_service.dart';
import 'package:total_athlete/services/workout_session_service.dart';
import 'package:total_athlete/services/audio_cue_service.dart';
import 'package:total_athlete/services/routine_migration_service.dart';
import 'package:total_athlete/utils/unit_conversion.dart';

class AppProvider with ChangeNotifier, WidgetsBindingObserver {
  final UserService _userService = UserService();
  final WorkoutService _workoutService = WorkoutService();
  final ExerciseService _exerciseService = ExerciseService();
  final BodyweightService _bodyweightService = BodyweightService();
  final PersonalRecordService _prService = PersonalRecordService();
  final RoutineService _routineService = RoutineService();
  final TrainingProgramService _programService = TrainingProgramService();
  final WorkoutSessionService _sessionService = WorkoutSessionService();
  final AudioCueService _audioCueService = AudioCueService();

  User? _currentUser;
  List<Workout> _workouts = [];
  List<Exercise> _exercises = [];
  List<BodyweightLog> _bodyweightLogs = [];
  List<PersonalRecord> _personalRecords = [];
  List<Routine> _routines = [];
  List<TrainingProgram> _programs = [];
  Workout? _activeWorkout;
  bool _isLoading = false;
  Workout? _pendingRecoveryWorkout; // Workout waiting for user decision (resume/discard)
  
  // Global workout session timer
  Timer? _workoutSessionTimer;
  Duration _sessionDuration = Duration.zero;
  
  // PR celebration callback
  VoidCallback? _onPrAchieved;
  
  // App lifecycle tracking
  bool _wasInBackground = false;

  User? get currentUser => _currentUser;
  List<Workout> get workouts => _workouts;
  List<Exercise> get exercises => _exercises;
  List<BodyweightLog> get bodyweightLogs => _bodyweightLogs;
  List<PersonalRecord> get personalRecords => _personalRecords;
  List<Routine> get routines => _routines;
  List<TrainingProgram> get programs => _programs;
  Workout? get activeWorkout => _activeWorkout;
  bool get isLoading => _isLoading;
  Workout? get pendingRecoveryWorkout => _pendingRecoveryWorkout;
  WorkoutService get workoutService => _workoutService;
  TrainingProgramService get trainingProgramService => _programService;
  WorkoutSessionService get sessionService => _sessionService;
  
  /// Get the current session duration (updated every second)
  Duration get sessionDuration => _sessionDuration;
  
  /// Get the current user's preferred unit ('kg' or 'lb')
  String get preferredUnit => _currentUser?.preferredUnit ?? 'kg';
  
  /// Get the current theme configuration
  ThemeConfig get themeConfig {
    if (_currentUser?.themeConfig != null) {
      return ThemeConfig.fromJson(_currentUser!.themeConfig!);
    }
    return const ThemeConfig(); // Default to system mode
  }
  
  /// Set callback for PR celebration
  void setOnPrAchieved(VoidCallback? callback) {
    _onPrAchieved = callback;
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App resumed from background
      if (_wasInBackground && _activeWorkout != null) {
        debugPrint('📱 App resumed from background - reloading active workout session');
        _reloadActiveWorkoutSession();
      }
      _wasInBackground = false;
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // App going to background
      _wasInBackground = true;
      
      if (_activeWorkout != null) {
        debugPrint('📱 App pausing - saving active workout session');
        // Force save the current session state
        _sessionService.saveSessionState(_activeWorkout!, force: true);
      }
    }
  }
  
  /// Reload active workout session from storage
  /// Called when app resumes from background to ensure session data is fresh
  Future<void> _reloadActiveWorkoutSession() async {
    try {
      // On web, SharedPreferences might have stale cache after backgrounding
      // Force reload by getting a fresh instance
      if (kIsWeb) {
        debugPrint('🌐 Web platform detected - forcing SharedPreferences reload');
        final prefs = await SharedPreferences.getInstance();
        await prefs.reload();
      }
      
      final sessionData = await _sessionService.loadSessionState();
      
      if (sessionData != null) {
        final reloadedWorkout = sessionData['workout'] as Workout;
        
        // Verify this matches our active workout
        if (_activeWorkout != null && reloadedWorkout.id == _activeWorkout!.id) {
          // Update active workout with reloaded data (preserving original start time)
          _activeWorkout = reloadedWorkout;
          
          // Update in workouts list
          final index = _workouts.indexWhere((w) => w.id == reloadedWorkout.id);
          if (index != -1) {
            _workouts[index] = reloadedWorkout;
          }
          
          // Restart the session timer to recalculate duration from original start time
          _startWorkoutSessionTimer();
          
          debugPrint('✅ Active workout session reloaded from storage');
          debugPrint('   - Name: ${reloadedWorkout.name}');
          debugPrint('   - Original start time: ${reloadedWorkout.startTime}');
          debugPrint('   - Current duration: ${DateTime.now().difference(reloadedWorkout.startTime)}');
          debugPrint('   - Completed sets: ${reloadedWorkout.completedSets}/${reloadedWorkout.totalSets}');
          
          notifyListeners();
        } else if (_activeWorkout != null) {
          debugPrint('⚠️ Session mismatch - active: ${_activeWorkout!.id}, loaded: ${reloadedWorkout.id}');
        }
      } else {
        debugPrint('⚠️ No session data found when reloading after resume');
      }
    } catch (e, stackTrace) {
      debugPrint('⚠️ Failed to reload active workout session: $e');
      debugPrint('   Stack trace: $stackTrace');
    }
  }

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();
    
    // Register as app lifecycle observer
    WidgetsBinding.instance.addObserver(this);
    
    final crashlytics = CrashlyticsService();
    
    try {
      // Run weight migration first (before loading data)
      await WeightMigrationService.runMigrationIfNeeded();
      
      // Run user profile migration to update to Tester identity
      await UserMigrationService.migrateToTesterProfile();
      
      _currentUser = await _userService.getCurrentUser();
      if (_currentUser != null) {
        // Set Crashlytics user context
        await crashlytics.setUserIdentifier(_currentUser!.id);
        await crashlytics.setUnitPreference(_currentUser!.preferredUnit);
        
        await Future.wait([
          loadWorkouts(),
          loadExercises(),
          loadBodyweightLogs(),
          loadPersonalRecords(),
          loadRoutines(),
          loadPrograms(),
        ]);
        
        // Run Pull Day routine migration (one-time update)
        final routineMigration = RoutineMigrationService(
          routineService: _routineService,
          exerciseService: _exerciseService,
        );
        await routineMigration.updatePullDayRoutine();
        
        // Reload routines after migration
        await loadRoutines();
        
        // Check for crash-recovered session first
        final recoveredSessionData = await _sessionService.loadSessionState();
        if (recoveredSessionData != null) {
          final recoveredSession = recoveredSessionData['workout'] as Workout;
          debugPrint('🔄 Recovered active workout session: ${recoveredSession.name}');
          
          // Check if should prompt for recovery (same day session)
          final shouldPrompt = await _sessionService.shouldPromptRecovery();
          
          if (shouldPrompt) {
            // Store as pending - UI will prompt user to resume or discard
            debugPrint('📋 Session from today - will prompt user for recovery');
            _pendingRecoveryWorkout = recoveredSession;
            
            // Don't set as active yet - wait for user decision
            _activeWorkout = null;
          } else {
            // Old session (not from today) - auto-recover silently
            debugPrint('🔄 Auto-recovering old session from previous day');
            
            // Check if this workout exists in the database
            final existingWorkout = _workouts.cast<Workout?>().firstWhere(
              (w) => w?.id == recoveredSession.id,
              orElse: () => null,
            );
            
            if (existingWorkout != null) {
              // Update existing workout with recovered state (preserving original start time)
              final index = _workouts.indexWhere((w) => w.id == recoveredSession.id);
              if (index != -1) {
                _workouts[index] = recoveredSession;
                await _workoutService.updateWorkout(recoveredSession);
              }
            } else {
              // Session exists but workout was deleted - restore it
              _workouts.add(recoveredSession);
              await _workoutService.addWorkout(recoveredSession);
            }
            
            _activeWorkout = recoveredSession;
            // Start global session timer for recovered session
            _startWorkoutSessionTimer();
          }
        } else {
          // No recovered session - check for active workout normally
          _activeWorkout = await _workoutService.getActiveWorkout(_currentUser!.id);
          // Start global session timer if there's an active workout
          if (_activeWorkout != null) {
            _startWorkoutSessionTimer();
          }
        }
        
        // Rebuild PRs from all completed workouts if we have workouts but no PRs
        final completedWorkouts = _workouts.where((w) => w.isCompleted).toList();
        if (completedWorkouts.isNotEmpty && _personalRecords.isEmpty) {
          debugPrint('🔄 Rebuilding PRs from ${completedWorkouts.length} completed workouts...');
          await _rebuildPersonalRecordsFromHistory();
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Failed to initialize app: $e');
      await crashlytics.recordError(e, stackTrace, reason: 'App initialization failed');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadWorkouts() async {
    if (_currentUser == null) return;
    _workouts = await _workoutService.getWorkoutsByUserId(_currentUser!.id);
    notifyListeners();
  }

  Future<void> loadExercises() async {
    _exercises = await _exerciseService.getAllExercises();
    notifyListeners();
  }

  Future<void> loadBodyweightLogs() async {
    if (_currentUser == null) return;
    _bodyweightLogs = await _bodyweightService.getLogsByUserId(_currentUser!.id);
    notifyListeners();
  }

  Future<void> loadPersonalRecords() async {
    if (_currentUser == null) return;
    _personalRecords = await _prService.getRecordsByUserId(_currentUser!.id);
    notifyListeners();
  }

  /// Detect and update personal records from a completed workout
  /// Checks for: heaviest single set, best estimated 1RM, and highest volume workout
  Future<void> _detectAndUpdatePersonalRecords(Workout workout) async {
    if (_currentUser == null || !workout.isCompleted) return;
    
    final userId = _currentUser!.id;
    bool hasNewPR = false;
    
    // Process each exercise in the completed workout
    for (var workoutExercise in workout.exercises) {
      final exercise = workoutExercise.exercise;
      final completedSets = workoutExercise.sets.where((s) => s.isCompleted && s.weightKg > 0 && s.reps > 0).toList();
      
      if (completedSets.isEmpty) continue;
      
      // Find the best set from this workout (by weight first, then reps)
      var bestSet = completedSets.first;
      var bestWeightKg = bestSet.weightKg;
      
      for (var set in completedSets) {
        // Weights are already in kg
        final weightKg = set.weightKg;
        
        // Compare by weight first, then reps for ties
        if (weightKg > bestWeightKg || (weightKg == bestWeightKg && set.reps > bestSet.reps)) {
          bestWeightKg = weightKg;
          bestSet = set;
        }
      }
      
      // Calculate estimated 1RM for this set
      final bestE1RM = bestWeightKg * (1 + bestSet.reps / 30);
      
      // Get existing PR for this exercise (if any)
      final existingPR = _personalRecords.cast<PersonalRecord?>().firstWhere(
        (pr) => pr?.exerciseId == exercise.id,
        orElse: () => null,
      );
      
      // Determine if this is a new PR
      bool isNewPR = false;
      
      if (existingPR == null) {
        // No existing PR - this is automatically a new PR
        isNewPR = true;
      } else {
        // Convert existing PR weight to kg for comparison
        final existingWeightKg = existingPR.unit == 'kg' ? existingPR.weight : existingPR.weight * 0.453592;
        
        // Compare by weight first, then reps for ties
        if (bestWeightKg > existingWeightKg || (bestWeightKg == existingWeightKg && bestSet.reps > existingPR.reps)) {
          isNewPR = true;
        }
      }
      
      if (isNewPR) {
        // Create or update PR
        final now = DateTime.now();
        final userUnit = _currentUser?.preferredUnit ?? 'kg';
        final displayWeight = UnitConversion.kgToDisplayUnit(bestSet.weightKg, userUnit);
        
        final newPR = PersonalRecord(
          id: existingPR?.id ?? _generateUuid(),
          userId: userId,
          exerciseId: exercise.id,
          exerciseName: exercise.name,
          weight: displayWeight,
          unit: userUnit,
          reps: bestSet.reps,
          estimatedOneRepMax: bestE1RM,
          achievedDate: workout.startTime,
          createdAt: existingPR?.createdAt ?? now,
          updatedAt: now,
        );
        
        if (existingPR == null) {
          await _prService.addRecord(newPR);
          debugPrint('🏆 NEW PR: ${exercise.name} - ${displayWeight.toStringAsFixed(1)}$userUnit x ${bestSet.reps} (e1RM: ${bestE1RM.toStringAsFixed(1)}kg)');
        } else {
          await _prService.updateRecord(newPR);
          debugPrint('🏆 UPDATED PR: ${exercise.name} - ${displayWeight.toStringAsFixed(1)}$userUnit x ${bestSet.reps} (e1RM: ${bestE1RM.toStringAsFixed(1)}kg)');
        }
        
        hasNewPR = true;
        
        // Trigger PR celebration callback
        _onPrAchieved?.call();
      }
    }
    
    // Reload PRs if any were updated
    if (hasNewPR) {
      await loadPersonalRecords();
    }
  }
  
  String _generateUuid() {
    // Simple UUID generation (timestamp-based)
    return 'pr_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecondsSinceEpoch % 1000}';
  }

  /// Rebuild all personal records from workout history
  /// Used when initializing the app or after data import
  Future<void> _rebuildPersonalRecordsFromHistory() async {
    if (_currentUser == null) return;
    
    final userId = _currentUser!.id;
    final completedWorkouts = _workouts.where((w) => w.isCompleted).toList();
    
    if (completedWorkouts.isEmpty) return;
    
    // Map to track best performance per exercise: exerciseId -> best PR data
    final exerciseBestPRs = <String, Map<String, dynamic>>{};
    
    // Process all completed workouts
    for (var workout in completedWorkouts) {
      for (var workoutExercise in workout.exercises) {
        final exercise = workoutExercise.exercise;
        final completedSets = workoutExercise.sets.where((s) => s.isCompleted && s.weightKg > 0 && s.reps > 0).toList();
        
        if (completedSets.isEmpty) continue;
        
        // Find the best set from this workout
        for (var set in completedSets) {
          // Weights are already in kg
          final weightKg = set.weightKg;
          // Calculate estimated 1RM
          final e1rm = weightKg * (1 + set.reps / 30);
          
          // Check if this is better than current best for this exercise
          final currentBest = exerciseBestPRs[exercise.id];
          final userUnit = _currentUser?.preferredUnit ?? 'kg';
          final displayWeight = UnitConversion.kgToDisplayUnit(weightKg, userUnit);
          
          if (currentBest == null) {
            // No existing best - this is the first
            exerciseBestPRs[exercise.id] = {
              'exerciseName': exercise.name,
              'weight': displayWeight,
              'unit': userUnit,
              'reps': set.reps,
              'weightKg': weightKg,
              'estimatedOneRepMax': e1rm,
              'achievedDate': workout.startTime,
            };
          } else {
            // Compare by weight first, then reps for ties
            final currentBestWeightKg = currentBest['weightKg'] as double;
            final currentBestReps = currentBest['reps'] as int;
            
            if (weightKg > currentBestWeightKg || (weightKg == currentBestWeightKg && set.reps > currentBestReps)) {
              exerciseBestPRs[exercise.id] = {
                'exerciseName': exercise.name,
                'weight': displayWeight,
                'unit': userUnit,
                'reps': set.reps,
                'weightKg': weightKg,
                'estimatedOneRepMax': e1rm,
                'achievedDate': workout.startTime,
              };
            }
          }
        }
      }
    }
    
    // Create PR records from best performances
    final now = DateTime.now();
    for (var entry in exerciseBestPRs.entries) {
      final exerciseId = entry.key;
      final prData = entry.value;
      
      final newPR = PersonalRecord(
        id: _generateUuid(),
        userId: userId,
        exerciseId: exerciseId,
        exerciseName: prData['exerciseName'] as String,
        weight: prData['weight'] as double,
        unit: prData['unit'] as String,
        reps: prData['reps'] as int,
        estimatedOneRepMax: prData['estimatedOneRepMax'] as double,
        achievedDate: prData['achievedDate'] as DateTime,
        createdAt: now,
        updatedAt: now,
      );
      
      await _prService.addRecord(newPR);
      debugPrint('✅ Detected PR: ${newPR.exerciseName} - ${newPR.weight}${newPR.unit} x ${newPR.reps}');
    }
    
    // Reload PRs
    await loadPersonalRecords();
    debugPrint('🏆 Rebuilt ${exerciseBestPRs.length} personal records from workout history');
  }

  Future<void> loadRoutines() async {
    if (_currentUser == null) return;
    _routines = await _routineService.getRoutinesByUserId(_currentUser!.id);
    notifyListeners();
  }

  Future<void> addRoutine(Routine routine) async {
    await _routineService.addRoutine(routine);
    await loadRoutines();
  }

  Future<void> updateRoutine(Routine routine) async {
    await _routineService.updateRoutine(routine);
    await loadRoutines();
  }

  Future<void> deleteRoutine(String id) async {
    await _routineService.deleteRoutine(id);
    await loadRoutines();
  }

  Future<void> loadPrograms() async {
    if (_currentUser == null) return;
    _programs = await _programService.getProgramsByUserId(_currentUser!.id);
    notifyListeners();
  }

  Future<void> addProgram(TrainingProgram program) async {
    await _programService.addProgram(program);
    await loadPrograms();
  }

  Future<void> updateProgram(TrainingProgram program) async {
    await _programService.updateProgram(program);
    await loadPrograms();
  }

  Future<void> deleteProgram(String id) async {
    await _programService.deleteProgram(id);
    await loadPrograms();
  }

  Future<void> addWorkout(Workout workout) async {
    await _workoutService.addWorkout(workout);
    await loadWorkouts();
    if (!workout.isCompleted) {
      _activeWorkout = workout;
      // Clear any pending recovery workout (user has started a new session)
      if (_pendingRecoveryWorkout != null) {
        debugPrint('🔄 Clearing pending recovery workout - user started new session');
        _pendingRecoveryWorkout = null;
      }
      // Clear any existing session state before starting a new workout
      // This prevents showing false recovery banners for brand new workouts
      await _sessionService.clearSessionState();
      // Save initial session state for crash recovery
      await _sessionService.saveSessionState(workout);
      // Start global session timer
      _startWorkoutSessionTimer();
      // Play workout start audio cue
      await _audioCueService.playWorkoutStart(_currentUser);
    }
    notifyListeners();
  }
  
  /// Start the global workout session timer
  /// This timer runs in the background and updates every second
  void _startWorkoutSessionTimer() {
    _workoutSessionTimer?.cancel();
    
    if (_activeWorkout == null) {
      _sessionDuration = Duration.zero;
      return;
    }
    
    // Update duration immediately
    _sessionDuration = DateTime.now().difference(_activeWorkout!.startTime);
    notifyListeners();
    
    // Start periodic timer
    _workoutSessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_activeWorkout != null) {
        _sessionDuration = DateTime.now().difference(_activeWorkout!.startTime);
        notifyListeners();
      } else {
        timer.cancel();
      }
    });
    
    debugPrint('⏱️ Global workout session timer started');
  }
  
  /// Stop the global workout session timer
  void _stopWorkoutSessionTimer() {
    _workoutSessionTimer?.cancel();
    _workoutSessionTimer = null;
    _sessionDuration = Duration.zero;
    debugPrint('⏱️ Global workout session timer stopped');
  }

  Future<void> updateWorkout(
    Workout workout, {
    int? currentExerciseIndex,
    Map<String, dynamic>? restTimerState,
    bool forceAutosave = false,
  }) async {
    await _workoutService.updateWorkout(workout);
    await loadWorkouts();
    if (workout.isCompleted) {
      _activeWorkout = null;
      // Stop global session timer
      _stopWorkoutSessionTimer();
      // Clear session state when workout is completed
      await _sessionService.clearSessionState();
      // Detect and update PRs after completing a workout
      await _detectAndUpdatePersonalRecords(workout);
    } else {
      // Update active workout reference
      final wasNewWorkout = _activeWorkout?.id != workout.id;
      _activeWorkout = workout;
      
      // Restart timer if workout start time changed or this is a new workout
      if (wasNewWorkout) {
        _startWorkoutSessionTimer();
      }
      
      // Autosave session state for crash recovery
      await _sessionService.saveSessionState(
        workout,
        currentExerciseIndex: currentExerciseIndex,
        restTimerState: restTimerState,
        force: forceAutosave,
      );
    }
    notifyListeners();
  }

  /// Delete a workout and cascade delete all related data
  /// This includes workout sets, exercises, and recomputes PRs and analytics
  Future<void> deleteWorkout(String workoutId) async {
    if (_currentUser == null) return;
    
    debugPrint('🗑️ Deleting workout: $workoutId');
    
    // Get the workout before deleting (to check if it had any PRs)
    final workoutToDelete = _workouts.cast<Workout?>().firstWhere(
      (w) => w?.id == workoutId,
      orElse: () => null,
    );
    
    if (workoutToDelete == null) {
      debugPrint('⚠️ Workout not found: $workoutId');
      return;
    }
    
    // Extract exercise IDs from the deleted workout for PR recomputation
    final affectedExerciseIds = workoutToDelete.exercises
        .map((we) => we.exercise.id)
        .toSet();
    
    // 1. Delete the workout from storage
    await _workoutService.deleteWorkout(workoutId);
    
    // 2. Reload workouts to reflect the deletion
    await loadWorkouts();
    
    // 3. Clear active workout if it was deleted
    if (_activeWorkout?.id == workoutId) {
      _activeWorkout = null;
      // Stop global session timer
      _stopWorkoutSessionTimer();
      // Clear session state when active workout is deleted
      await _sessionService.clearSessionState();
    }
    
    // 4. Clear pending recovery workout if it was deleted
    if (_pendingRecoveryWorkout?.id == workoutId) {
      _pendingRecoveryWorkout = null;
    }
    
    // 5. Recompute PRs for all affected exercises
    // This ensures PRs reflect only existing workouts
    debugPrint('🔄 Recomputing PRs for ${affectedExerciseIds.length} affected exercises...');
    await _recomputePersonalRecordsForExercises(affectedExerciseIds);
    
    debugPrint('✅ Workout deleted and analytics updated');
    notifyListeners();
  }
  
  /// Recompute personal records for specific exercises
  /// Used after workout deletion to ensure PRs reflect only existing workouts
  Future<void> _recomputePersonalRecordsForExercises(Set<String> exerciseIds) async {
    if (_currentUser == null || exerciseIds.isEmpty) return;
    
    final userId = _currentUser!.id;
    final completedWorkouts = _workouts.where((w) => w.isCompleted).toList();
    
    // For each affected exercise, find the new best performance across all remaining workouts
    for (final exerciseId in exerciseIds) {
      double bestWeightKg = 0;
      int bestReps = 0;
      DateTime? bestDate;
      String? exerciseName;
      
      // Search all completed workouts for this exercise
      for (final workout in completedWorkouts) {
        for (final workoutExercise in workout.exercises) {
          if (workoutExercise.exercise.id == exerciseId) {
            exerciseName = workoutExercise.exercise.name;
            final completedSets = workoutExercise.sets
                .where((s) => s.isCompleted && s.weightKg > 0 && s.reps > 0)
                .toList();
            
            for (final set in completedSets) {
              final weightKg = set.weightKg;
              
              // Compare by weight first, then reps for ties
              if (weightKg > bestWeightKg || (weightKg == bestWeightKg && set.reps > bestReps)) {
                bestWeightKg = weightKg;
                bestReps = set.reps;
                bestDate = workout.startTime;
              }
            }
          }
        }
      }
      
      // Get existing PR for this exercise
      final existingPR = _personalRecords.cast<PersonalRecord?>().firstWhere(
        (pr) => pr?.exerciseId == exerciseId,
        orElse: () => null,
      );
      
      if (bestWeightKg > 0 && bestDate != null && exerciseName != null) {
        // Found a valid best performance - update or create PR
        final userUnit = _currentUser?.preferredUnit ?? 'kg';
        final displayWeight = UnitConversion.kgToDisplayUnit(bestWeightKg, userUnit);
        final e1rm = bestWeightKg * (1 + bestReps / 30);
        final now = DateTime.now();
        
        final newPR = PersonalRecord(
          id: existingPR?.id ?? _generateUuid(),
          userId: userId,
          exerciseId: exerciseId,
          exerciseName: exerciseName,
          weight: displayWeight,
          unit: userUnit,
          reps: bestReps,
          estimatedOneRepMax: e1rm,
          achievedDate: bestDate,
          createdAt: existingPR?.createdAt ?? now,
          updatedAt: now,
        );
        
        if (existingPR == null) {
          await _prService.addRecord(newPR);
        } else {
          await _prService.updateRecord(newPR);
        }
        
        debugPrint('✅ Updated PR for $exerciseName: ${displayWeight.toStringAsFixed(1)}$userUnit x $bestReps');
      } else if (existingPR != null) {
        // No valid performance found - delete the PR
        await _prService.deleteRecord(existingPR.id);
        debugPrint('🗑️ Deleted PR for $exerciseName (no remaining performances)');
      }
    }
    
    // Reload PRs to reflect changes
    await loadPersonalRecords();
  }

  /// Resume the pending recovery workout
  /// This is called when user chooses "Resume" in the recovery dialog
  Future<void> resumePendingWorkout() async {
    if (_pendingRecoveryWorkout == null) {
      debugPrint('⚠️ No pending recovery workout to resume');
      return;
    }

    debugPrint('▶️ Resuming recovered workout: ${_pendingRecoveryWorkout!.name}');
    
    // Check if this workout exists in the database
    final existingWorkout = _workouts.cast<Workout?>().firstWhere(
      (w) => w?.id == _pendingRecoveryWorkout!.id,
      orElse: () => null,
    );
    
    if (existingWorkout != null) {
      // Update existing workout with recovered state (preserving original start time)
      final index = _workouts.indexWhere((w) => w.id == _pendingRecoveryWorkout!.id);
      if (index != -1) {
        _workouts[index] = _pendingRecoveryWorkout!;
        await _workoutService.updateWorkout(_pendingRecoveryWorkout!);
      }
    } else {
      // Session exists but workout was deleted - restore it
      _workouts.add(_pendingRecoveryWorkout!);
      await _workoutService.addWorkout(_pendingRecoveryWorkout!);
    }
    
    // Set as active workout
    _activeWorkout = _pendingRecoveryWorkout;
    _pendingRecoveryWorkout = null;
    
    // Start global session timer
    _startWorkoutSessionTimer();
    
    notifyListeners();
  }

  /// Discard the pending recovery workout
  /// This is called when user chooses "Discard" in the recovery dialog
  Future<void> discardPendingWorkout() async {
    if (_pendingRecoveryWorkout == null) {
      debugPrint('⚠️ No pending recovery workout to discard');
      return;
    }

    debugPrint('🗑️ Discarding recovered workout: ${_pendingRecoveryWorkout!.name}');
    
    final discardedWorkoutId = _pendingRecoveryWorkout!.id;
    
    // Clear the session state
    await _sessionService.clearSessionState();
    
    // Delete the workout from database if it exists
    final existingWorkout = _workouts.cast<Workout?>().firstWhere(
      (w) => w?.id == discardedWorkoutId,
      orElse: () => null,
    );
    
    if (existingWorkout != null) {
      await _workoutService.deleteWorkout(discardedWorkoutId);
      await loadWorkouts();
    }
    
    // Clear pending workout
    _pendingRecoveryWorkout = null;
    
    // Check if there are any other incomplete workouts and set as active
    if (_currentUser != null) {
      final otherActiveWorkout = _workouts.cast<Workout?>().firstWhere(
        (w) => w != null && w.userId == _currentUser!.id && !w.isCompleted && w.id != discardedWorkoutId,
        orElse: () => null,
      );
      
      if (otherActiveWorkout != null) {
        debugPrint('✅ Found another active workout: ${otherActiveWorkout.name}');
        _activeWorkout = otherActiveWorkout;
        _startWorkoutSessionTimer();
      } else {
        _activeWorkout = null;
        _stopWorkoutSessionTimer();
      }
    } else {
      _activeWorkout = null;
      _stopWorkoutSessionTimer();
    }
    
    notifyListeners();
  }

  Future<void> addBodyweightLog(BodyweightLog log) async {
    await _bodyweightService.addLog(log);
    await loadBodyweightLogs();
    
    // Update current weight if this is the most recent log
    if (_currentUser != null && _bodyweightLogs.isNotEmpty) {
      final mostRecentLog = _bodyweightLogs.first; // Logs are sorted by date descending
      if (mostRecentLog.id == log.id) {
        final updatedUser = _currentUser!.copyWith(
          currentWeight: log.weight,
          updatedAt: DateTime.now(),
        );
        await _userService.updateUser(updatedUser);
        _currentUser = updatedUser;
        notifyListeners();
      }
    }
  }

  Future<void> deleteBodyweightLog(String id) async {
    await _bodyweightService.deleteLog(id);
    await loadBodyweightLogs();
    
    // Update current weight to the most recent log if it exists
    if (_currentUser != null && _bodyweightLogs.isNotEmpty) {
      final mostRecentLog = _bodyweightLogs.first; // Logs are sorted by date descending
      final updatedUser = _currentUser!.copyWith(
        currentWeight: mostRecentLog.weight,
        updatedAt: DateTime.now(),
      );
      await _userService.updateUser(updatedUser);
      _currentUser = updatedUser;
      notifyListeners();
    }
  }

  Future<void> addPersonalRecord(PersonalRecord record) async {
    await _prService.addRecord(record);
    await loadPersonalRecords();
  }

  Future<void> updateUser(User user) async {
    await _userService.updateUser(user);
    _currentUser = user;
    notifyListeners();
  }

  /// Update the user's preferred unit (kg or lb)
  Future<void> updateUnitPreference(String unit) async {
    if (_currentUser == null) return;
    if (unit != 'kg' && unit != 'lb') return;
    
    final updatedUser = _currentUser!.copyWith(
      preferredUnit: unit,
      updatedAt: DateTime.now(),
    );
    
    await _userService.updateUser(updatedUser);
    _currentUser = updatedUser;
    
    // Update Crashlytics context
    await CrashlyticsService().setUnitPreference(unit);
    
    notifyListeners();
  }

  /// Update the smith machine bar weight
  Future<void> updateSmithMachineBarWeight({double? kg, double? lb}) async {
    if (_currentUser == null) return;
    
    final updatedUser = _currentUser!.copyWith(
      smithMachineBarWeightKg: kg ?? _currentUser!.smithMachineBarWeightKg,
      smithMachineBarWeightLb: lb ?? _currentUser!.smithMachineBarWeightLb,
      updatedAt: DateTime.now(),
    );
    
    await _userService.updateUser(updatedUser);
    _currentUser = updatedUser;
    notifyListeners();
  }

  /// Update audio cue preferences
  Future<void> updateAudioPreferences({
    bool? workoutStart,
    bool? workoutComplete,
    bool? setStart,
    bool? setComplete,
    bool? restStart,
    bool? restComplete,
  }) async {
    if (_currentUser == null) return;
    
    final updatedUser = _currentUser!.copyWith(
      audioWorkoutStart: workoutStart ?? _currentUser!.audioWorkoutStart,
      audioWorkoutComplete: workoutComplete ?? _currentUser!.audioWorkoutComplete,
      audioSetStart: setStart ?? _currentUser!.audioSetStart,
      audioSetComplete: setComplete ?? _currentUser!.audioSetComplete,
      audioRestStart: restStart ?? _currentUser!.audioRestStart,
      audioRestComplete: restComplete ?? _currentUser!.audioRestComplete,
      updatedAt: DateTime.now(),
    );
    
    await _userService.updateUser(updatedUser);
    _currentUser = updatedUser;
    notifyListeners();
  }

  /// Update default rest timer duration in seconds
  Future<void> updateDefaultRestTimer(int seconds) async {
    if (_currentUser == null) return;
    if (seconds < 0) return;
    
    final updatedUser = _currentUser!.copyWith(
      defaultRestTimerSeconds: seconds,
      updatedAt: DateTime.now(),
    );
    
    await _userService.updateUser(updatedUser);
    _currentUser = updatedUser;
    notifyListeners();
  }

  /// Set or update rest timer for a specific exercise
  Future<void> setExerciseRestTimer(String exerciseId, int seconds) async {
    if (_currentUser == null) return;
    if (seconds < 0) return;
    
    final updatedTimers = Map<String, int>.from(_currentUser!.exerciseRestTimers);
    updatedTimers[exerciseId] = seconds;
    
    final updatedUser = _currentUser!.copyWith(
      exerciseRestTimers: updatedTimers,
      updatedAt: DateTime.now(),
    );
    
    await _userService.updateUser(updatedUser);
    _currentUser = updatedUser;
    notifyListeners();
  }

  /// Update theme configuration
  Future<void> updateThemeConfig(ThemeConfig config) async {
    if (_currentUser == null) return;
    
    final updatedUser = _currentUser!.copyWith(
      themeConfig: config.toJson(),
      updatedAt: DateTime.now(),
    );
    
    await _userService.updateUser(updatedUser);
    _currentUser = updatedUser;
    notifyListeners();
  }

  /// Remove rest timer override for a specific exercise (revert to default)
  Future<void> removeExerciseRestTimer(String exerciseId) async {
    if (_currentUser == null) return;
    
    final updatedTimers = Map<String, int>.from(_currentUser!.exerciseRestTimers);
    updatedTimers.remove(exerciseId);
    
    final updatedUser = _currentUser!.copyWith(
      exerciseRestTimers: updatedTimers,
      updatedAt: DateTime.now(),
    );
    
    await _userService.updateUser(updatedUser);
    _currentUser = updatedUser;
    notifyListeners();
  }

  /// Get rest timer duration for a specific exercise (returns override or default)
  int getRestTimerForExercise(String exerciseId) {
    if (_currentUser == null) return 90; // Fallback default
    return _currentUser!.exerciseRestTimers[exerciseId] ?? _currentUser!.defaultRestTimerSeconds;
  }

  // Dashboard Customization Methods

  /// Get dashboard configuration (main dashboard screen)
  DashboardConfig getDashboardConfig() {
    if (_currentUser?.dashboardConfig == null) {
      return DashboardConfig.defaultConfig();
    }
    try {
      return DashboardConfig.fromJson(_currentUser!.dashboardConfig!);
    } catch (e) {
      debugPrint('Error parsing dashboard config: $e');
      return DashboardConfig.defaultConfig();
    }
  }

  /// Update dashboard configuration (main dashboard screen)
  Future<void> updateDashboardConfig(DashboardConfig config) async {
    if (_currentUser == null) return;
    
    final updatedUser = _currentUser!.copyWith(
      dashboardConfig: config.toJson(),
      updatedAt: DateTime.now(),
    );
    
    await _userService.updateUser(updatedUser);
    _currentUser = updatedUser;
    notifyListeners();
  }

  /// Get analytics dashboard configuration
  DashboardConfig getAnalyticsDashboardConfig() {
    if (_currentUser?.analyticsDashboardConfig == null) {
      return DashboardConfig.defaultAnalyticsConfig();
    }
    try {
      return DashboardConfig.fromJson(_currentUser!.analyticsDashboardConfig!);
    } catch (e) {
      debugPrint('Error parsing analytics dashboard config: $e');
      return DashboardConfig.defaultAnalyticsConfig();
    }
  }

  /// Update analytics dashboard configuration
  Future<void> updateAnalyticsDashboardConfig(DashboardConfig config) async {
    if (_currentUser == null) return;
    
    final updatedUser = _currentUser!.copyWith(
      analyticsDashboardConfig: config.toJson(),
      updatedAt: DateTime.now(),
    );
    
    await _userService.updateUser(updatedUser);
    _currentUser = updatedUser;
    notifyListeners();
  }

  // Analytics Helper Methods

  /// Get all completed workouts from today
  List<Workout> getTodaysWorkouts() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _workouts
        .where((w) => w.isCompleted && w.startTime.isAfter(today))
        .toList();
  }

  /// Get all completed workouts from the last 7 days
  List<Workout> getWeeklyWorkouts() {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    return _workouts
        .where((w) => w.isCompleted && w.startTime.isAfter(weekAgo))
        .toList();
  }

  /// Get muscle groups trained today
  Set<String> getMusclesTrainedToday() {
    final todayWorkouts = getTodaysWorkouts();
    final muscles = <String>{};
    for (var workout in todayWorkouts) {
      for (var exercise in workout.exercises) {
        muscles.add(_formatMuscleGroup(exercise.exercise.primaryMuscleGroup.name));
      }
    }
    return muscles;
  }

  /// Get sets per muscle group for the week
  Map<String, int> getWeeklyMuscleGroupSets() {
    final weeklyWorkouts = getWeeklyWorkouts();
    final muscleGroupSets = <String, int>{};
    
    for (var workout in weeklyWorkouts) {
      for (var exercise in workout.exercises) {
        final muscle = _formatMuscleGroup(exercise.exercise.primaryMuscleGroup.name);
        muscleGroupSets[muscle] = (muscleGroupSets[muscle] ?? 0) + exercise.completedSets;
      }
    }
    
    return muscleGroupSets;
  }

  /// Get last workout date for each muscle group (for recovery tracking)
  Map<String, DateTime> getLastWorkoutByMuscleGroup() {
    final completedWorkouts = _workouts
        .where((w) => w.isCompleted)
        .toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
    
    final lastWorkoutDates = <String, DateTime>{};
    
    for (var workout in completedWorkouts) {
      for (var exercise in workout.exercises) {
        final muscle = _formatMuscleGroup(exercise.exercise.primaryMuscleGroup.name);
        if (!lastWorkoutDates.containsKey(muscle)) {
          lastWorkoutDates[muscle] = workout.startTime;
        }
      }
    }
    
    return lastWorkoutDates;
  }

  /// Get volume trend for the last N workouts
  List<double> getVolumeTrend(int count) {
    final completedWorkouts = _workouts
        .where((w) => w.isCompleted)
        .toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
    
    return completedWorkouts
        .take(count)
        .map((w) => w.totalVolume)
        .toList()
        .reversed
        .toList();
  }

  /// Calculate volume change percentage from previous period
  double getVolumeChangePercentage() {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final twoWeeksAgo = now.subtract(const Duration(days: 14));
    
    final thisWeekWorkouts = _workouts
        .where((w) => w.isCompleted && w.startTime.isAfter(weekAgo))
        .toList();
    final lastWeekWorkouts = _workouts
        .where((w) => w.isCompleted && w.startTime.isAfter(twoWeeksAgo) && w.startTime.isBefore(weekAgo))
        .toList();
    
    final thisWeekVolume = thisWeekWorkouts.fold<double>(0.0, (sum, w) => sum + w.totalVolume);
    final lastWeekVolume = lastWeekWorkouts.fold<double>(0.0, (sum, w) => sum + w.totalVolume);
    
    if (lastWeekVolume == 0) return 0.0;
    return ((thisWeekVolume - lastWeekVolume) / lastWeekVolume) * 100;
  }

  /// Get training insights based on recent data
  List<String> getTrainingInsights() {
    final insights = <String>[];
    final weeklyWorkouts = getWeeklyWorkouts();
    
    if (weeklyWorkouts.isEmpty) {
      insights.add('Start your first workout this week');
      return insights;
    }
    
    // Volume trend insight
    final volumeChange = getVolumeChangePercentage();
    if (volumeChange > 10) {
      insights.add('Volume up ${volumeChange.toStringAsFixed(1)}% from last week - great progressive overload');
    } else if (volumeChange < -10) {
      insights.add('Volume down ${volumeChange.abs().toStringAsFixed(1)}% - consider a deload week');
    } else {
      insights.add('Volume stable - maintaining current training load');
    }
    
    // Frequency insight
    if (weeklyWorkouts.length >= 4) {
      insights.add('${weeklyWorkouts.length} sessions this week - excellent consistency');
    } else if (weeklyWorkouts.length >= 2) {
      insights.add('${weeklyWorkouts.length} sessions this week - solid training frequency');
    } else {
      insights.add('Only ${weeklyWorkouts.length} session this week - aim for 3-5 weekly');
    }
    
    // Muscle balance insight
    final muscleGroupSets = getWeeklyMuscleGroupSets();
    final maxSets = muscleGroupSets.values.isEmpty ? 0 : muscleGroupSets.values.reduce((a, b) => a > b ? a : b);
    final minSets = muscleGroupSets.values.isEmpty ? 0 : muscleGroupSets.values.reduce((a, b) => a < b ? a : b);
    
    if (maxSets > 0 && minSets == 0 && muscleGroupSets.length < 3) {
      insights.add('Focus on more muscle groups for balanced development');
    } else if (maxSets - minSets > 15) {
      insights.add('Consider balancing volume across muscle groups');
    }
    
    return insights;
  }

  String _formatMuscleGroup(String muscle) {
    return muscle[0].toUpperCase() + muscle.substring(1);
  }

  /// Get the user's most recent bodyweight in kilograms
  /// Returns null if no bodyweight logs exist
  double? getMostRecentBodyweightKg() {
    if (_bodyweightLogs.isEmpty) return null;
    
    // Sort by log date descending and get the most recent
    final sortedLogs = List<BodyweightLog>.from(_bodyweightLogs)
      ..sort((a, b) => b.logDate.compareTo(a.logDate));
    
    final mostRecent = sortedLogs.first;
    
    // Convert to kg if needed
    if (mostRecent.unit == 'kg') {
      return mostRecent.weight;
    } else {
      // Convert lb to kg
      return mostRecent.weight * 0.453592;
    }
  }

  /// Force a complete reload of all app data (used after data reset)
  Future<void> forceReloadAllData() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Reload user (which may have cleared goals)
      _currentUser = await _userService.getCurrentUser();
      
      if (_currentUser != null) {
        // Reload all data from services
        await Future.wait([
          loadWorkouts(),
          loadExercises(),
          loadBodyweightLogs(),
          loadPersonalRecords(),
          loadRoutines(),
        ]);
        
        // Check for active workout
        _activeWorkout = await _workoutService.getActiveWorkout(_currentUser!.id);
      }
      
      debugPrint('✅ Complete data reload finished');
      debugPrint('   - Workouts: ${_workouts.length}');
      debugPrint('   - Bodyweight logs: ${_bodyweightLogs.length}');
      debugPrint('   - Personal records: ${_personalRecords.length}');
      debugPrint('   - Active workout: ${_activeWorkout != null ? "Yes" : "None"}');
    } catch (e) {
      debugPrint('❌ Failed to reload app data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Manually rebuild all Personal Records from workout history
  /// Clears existing PRs and recalculates from scratch using the correct ranking logic
  /// (highest weight first, then highest reps for ties)
  Future<void> rebuildPersonalRecords() async {
    if (_currentUser == null) return;
    
    try {
      debugPrint('🔄 Manually rebuilding Personal Records...');
      
      // Clear existing PRs
      await _prService.clearAllRecords(_currentUser!.id);
      _personalRecords.clear();
      notifyListeners();
      
      // Rebuild from workout history
      await _rebuildPersonalRecordsFromHistory();
      
      debugPrint('✅ Personal Records rebuilt successfully');
      
      // Final notify to ensure UI updates
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error rebuilding Personal Records: $e');
      // Reload PRs even if rebuild fails to show current state
      await loadPersonalRecords();
      rethrow;
    }
  }

  /// Calculate average intensity from workouts in a given time period
  /// Intensity = (weight used / best weight) for each exercise
  /// Uses PRs if available, otherwise uses the best set from all workouts
  /// Returns null if no data available
  double? calculateAverageIntensity({int days = 30}) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final recentWorkouts = _workouts
        .where((w) => w.isCompleted && w.startTime.isAfter(cutoff))
        .toList();
    
    if (recentWorkouts.isEmpty) return null;
    
    // Build a map of exercise ID -> best estimated 1RM (from all completed workouts)
    final exerciseBestE1RM = <String, double>{};
    
    for (var workout in _workouts.where((w) => w.isCompleted)) {
      for (var exercise in workout.exercises) {
        final exerciseId = exercise.exercise.id;
        
        // Calculate best e1RM from this exercise's sets
        for (var set in exercise.sets.where((s) => s.isCompleted && s.weightKg > 0 && s.reps > 0)) {
          // Weights are already in kg
          double setWeightKg = set.weightKg;
          // Calculate estimated 1RM: weight × (1 + reps / 30)
          double e1rm = setWeightKg * (1 + set.reps / 30);
          
          if (!exerciseBestE1RM.containsKey(exerciseId) || e1rm > exerciseBestE1RM[exerciseId]!) {
            exerciseBestE1RM[exerciseId] = e1rm;
          }
        }
      }
    }
    
    if (exerciseBestE1RM.isEmpty) return null;
    
    double totalIntensity = 0.0;
    int totalCompletedSets = 0;
    
    // Now calculate intensity for recent workouts
    for (var workout in recentWorkouts) {
      for (var exercise in workout.exercises) {
        final exerciseId = exercise.exercise.id;
        final bestE1RM = exerciseBestE1RM[exerciseId];
        
        // Skip if we don't have a baseline for this exercise
        if (bestE1RM == null) continue;
        
        // Calculate intensity for each completed set
        for (var set in exercise.sets.where((s) => s.isCompleted && s.weightKg > 0 && s.reps > 0)) {
          // Weights are already in kg
          double setWeightKg = set.weightKg;
          // Calculate e1RM for this set
          double setE1RM = setWeightKg * (1 + set.reps / 30);
          
          // Intensity = this set's e1RM / best e1RM ever
          final intensity = setE1RM / bestE1RM;
          totalIntensity += intensity;
          totalCompletedSets++;
        }
      }
    }
    
    if (totalCompletedSets == 0) return null;
    
    // Return average as percentage (0.0 to 1.0 range)
    return totalIntensity / totalCompletedSets;
  }

  /// Calculate intensity change percentage comparing two periods
  /// Returns null if insufficient data
  double? getIntensityChangePercentage() {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final twoWeeksAgo = now.subtract(const Duration(days: 14));
    
    // Get workouts for this week and last week
    final thisWeekWorkouts = _workouts
        .where((w) => w.isCompleted && w.startTime.isAfter(weekAgo))
        .toList();
    final lastWeekWorkouts = _workouts
        .where((w) => w.isCompleted && w.startTime.isAfter(twoWeeksAgo) && w.startTime.isBefore(weekAgo))
        .toList();
    
    if (thisWeekWorkouts.isEmpty || lastWeekWorkouts.isEmpty) return null;
    
    // Build exercise baseline map (best e1RM for each exercise from all time)
    final exerciseBestE1RM = <String, double>{};
    for (var workout in _workouts.where((w) => w.isCompleted)) {
      for (var exercise in workout.exercises) {
        final exerciseId = exercise.exercise.id;
        for (var set in exercise.sets.where((s) => s.isCompleted && s.weightKg > 0 && s.reps > 0)) {
          double setWeightKg = set.weightKg;
          double e1rm = setWeightKg * (1 + set.reps / 30);
          if (!exerciseBestE1RM.containsKey(exerciseId) || e1rm > exerciseBestE1RM[exerciseId]!) {
            exerciseBestE1RM[exerciseId] = e1rm;
          }
        }
      }
    }
    
    if (exerciseBestE1RM.isEmpty) return null;
    
    // Calculate this week's average intensity
    double thisWeekTotal = 0.0;
    int thisWeekSets = 0;
    for (var workout in thisWeekWorkouts) {
      for (var exercise in workout.exercises) {
        final bestE1RM = exerciseBestE1RM[exercise.exercise.id];
        if (bestE1RM == null) continue;
        for (var set in exercise.sets.where((s) => s.isCompleted && s.weightKg > 0 && s.reps > 0)) {
          double setWeightKg = set.weightKg;
          double setE1RM = setWeightKg * (1 + set.reps / 30);
          thisWeekTotal += setE1RM / bestE1RM;
          thisWeekSets++;
        }
      }
    }
    
    // Calculate last week's average intensity
    double lastWeekTotal = 0.0;
    int lastWeekSets = 0;
    for (var workout in lastWeekWorkouts) {
      for (var exercise in workout.exercises) {
        final bestE1RM = exerciseBestE1RM[exercise.exercise.id];
        if (bestE1RM == null) continue;
        for (var set in exercise.sets.where((s) => s.isCompleted && s.weightKg > 0 && s.reps > 0)) {
          double setWeightKg = set.weightKg;
          double setE1RM = setWeightKg * (1 + set.reps / 30);
          lastWeekTotal += setE1RM / bestE1RM;
          lastWeekSets++;
        }
      }
    }
    
    if (thisWeekSets == 0 || lastWeekSets == 0) return null;
    
    final thisWeekIntensity = thisWeekTotal / thisWeekSets;
    final lastWeekIntensity = lastWeekTotal / lastWeekSets;
    
    // Calculate percentage change
    return ((thisWeekIntensity - lastWeekIntensity) / lastWeekIntensity) * 100;
  }

  /// Calculate strength progress data for major lifts
  /// Returns a list of ExerciseStrengthData for exercises with enough data
  List<Map<String, dynamic>> getStrengthProgressData({int days = 30}) {
    // Major lifts to track (by exercise name)
    final majorLiftNames = [
      'Barbell Bench Press',
      'Back Squat',
      'Deadlift',
      'Barbell Overhead Press',
      'Pull-Ups',
      'Leg Press',
    ];

    final cutoff = DateTime.now().subtract(Duration(days: days));
    final completedWorkouts = _workouts
        .where((w) => w.isCompleted)
        .toList()
        ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final results = <Map<String, dynamic>>[];

    // Process each major lift
    for (final liftName in majorLiftNames) {
      // Find the exercise in our exercise list
      final exercise = _exercises.cast<Exercise?>().firstWhere(
        (e) => e?.name == liftName,
        orElse: () => null,
      );

      if (exercise == null) continue; // Exercise not found

      // Collect all sets for this exercise across all workouts
      final allDataPoints = <Map<String, dynamic>>[];
      
      for (var workout in completedWorkouts) {
        for (var workoutExercise in workout.exercises) {
          if (workoutExercise.exercise.id == exercise.id) {
            // Find the best set in this workout
            final completedSets = workoutExercise.sets
                .where((s) => s.isCompleted && s.weightKg > 0 && s.reps > 0)
                .toList();

            if (completedSets.isEmpty) continue;

            // Find the best set by weight first, then reps
            var bestSet = completedSets.first;
            var bestWeightKg = bestSet.weightKg;

            // Find highest volume set (weight × reps)
            var highestVolumeSet = completedSets.first;
            var highestVolume = highestVolumeSet.weightKg * highestVolumeSet.reps;

            for (var set in completedSets) {
              // Weights are already in kg
              final weightKg = set.weightKg;
              
              // Compare by weight first, then reps for ties
              if (weightKg > bestWeightKg || (weightKg == bestWeightKg && set.reps > bestSet.reps)) {
                bestWeightKg = weightKg;
                bestSet = set;
              }

              // Check for highest volume
              final setVolume = set.weightKg * set.reps;
              if (setVolume > highestVolume) {
                highestVolume = setVolume;
                highestVolumeSet = set;
              }
            }
            
            // Calculate estimated 1RM for the best set
            final bestE1RM = bestWeightKg * (1 + bestSet.reps / 30);

            // Calculate total volume for this exercise in this workout
            final totalVolume = completedSets.fold<double>(
              0.0,
              (sum, set) => sum + (set.weightKg * set.reps),
            );

            allDataPoints.add({
              'date': workout.startTime,
              'estimatedOneRepMax': bestE1RM,
              'bestSet': bestSet,
              'weightKg': bestWeightKg,
              'highestVolumeSet': highestVolumeSet,
              'totalVolume': totalVolume,
            });
          }
        }
      }

      // Need at least 2 data points to show progress
      if (allDataPoints.length < 2) continue;

      // Get data points from the last 30 days
      final recentDataPoints = allDataPoints
          .where((dp) => (dp['date'] as DateTime).isAfter(cutoff))
          .toList();

      // Get the best overall set by weight first, then reps
      final bestOverall = allDataPoints.reduce((a, b) {
        final aWeightKg = a['weightKg'] as double;
        final bWeightKg = b['weightKg'] as double;
        final aReps = (a['bestSet'] as WorkoutSet).reps;
        final bReps = (b['bestSet'] as WorkoutSet).reps;
        
        if (aWeightKg > bWeightKg || (aWeightKg == bWeightKg && aReps > bReps)) {
          return a;
        }
        return b;
      });

      // Get the highest volume set overall
      final highestVolumeOverall = allDataPoints.reduce((a, b) {
        final aVolume = (a['highestVolumeSet'] as WorkoutSet).weightKg * (a['highestVolumeSet'] as WorkoutSet).reps;
        final bVolume = (b['highestVolumeSet'] as WorkoutSet).weightKg * (b['highestVolumeSet'] as WorkoutSet).reps;
        return aVolume > bVolume ? a : b;
      });

      // Calculate 30-day change
      double thirtyDayChange = 0.0;
      if (recentDataPoints.length >= 2) {
        final oldest = recentDataPoints.first;
        final newest = recentDataPoints.last;
        final oldE1RM = oldest['estimatedOneRepMax'] as double;
        final newE1RM = newest['estimatedOneRepMax'] as double;
        
        if (oldE1RM > 0) {
          thirtyDayChange = ((newE1RM - oldE1RM) / oldE1RM) * 100;
        }
      }

      results.add({
        'exercise': exercise,
        'bestSet': bestOverall['bestSet'],
        'estimatedOneRepMax': bestOverall['estimatedOneRepMax'],
        'highestVolumeSet': highestVolumeOverall['highestVolumeSet'],
        'thirtyDayChange': thirtyDayChange,
        'dataPoints': recentDataPoints.isEmpty ? allDataPoints.take(10).toList() : recentDataPoints,
        'hasEnoughData': true,
      });
    }

    return results;
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _workoutSessionTimer?.cancel();
    super.dispose();
  }
}
