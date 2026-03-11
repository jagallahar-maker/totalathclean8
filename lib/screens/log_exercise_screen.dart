import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:total_athlete/nav.dart';
import 'package:uuid/uuid.dart';
import 'package:total_athlete/providers/app_provider.dart';
import 'package:total_athlete/theme.dart';
import 'package:total_athlete/theme/app_chips.dart';
import 'package:total_athlete/models/workout.dart';
import 'package:total_athlete/models/workout_exercise.dart';
import 'package:total_athlete/models/workout_set.dart';
import 'package:total_athlete/models/exercise.dart';
import 'package:total_athlete/utils/format_utils.dart';
import 'package:total_athlete/utils/unit_conversion.dart';
import 'package:total_athlete/widgets/plate_calculator_modal.dart';
import 'package:total_athlete/widgets/workout_date_picker.dart';
import 'package:total_athlete/widgets/workout_timer_display.dart';
import 'package:total_athlete/widgets/compact_set_row.dart';
import 'package:total_athlete/widgets/custom_workout_keypad.dart';
import 'package:total_athlete/services/crashlytics_service.dart';
import 'package:total_athlete/services/progressive_overload_service.dart';
import 'package:total_athlete/services/audio_cue_service.dart';

enum SetMode {
  repeat, // Duplicate the previous set
  progressive, // Increase weight by increment
  backoff, // Decrease weight by percentage
}

class LogExerciseScreen extends StatefulWidget {
  final String workoutId;
  final String? exerciseIndex;

  const LogExerciseScreen({super.key, required this.workoutId, this.exerciseIndex});

  @override
  State<LogExerciseScreen> createState() => _LogExerciseScreenState();
}

class _LogExerciseScreenState extends State<LogExerciseScreen> {
  Workout? _workout;
  WorkoutExercise? _currentExercise;
  int _currentExerciseIndex = -1;

  // Search and filter state
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  MuscleGroup? _selectedMuscleFilter;

  // Rest timer state
  bool _isResting = false;
  int _restSecondsRemaining = 90;
  Timer? _restTimer;
  int _currentRestTimerSeconds = 90; // Gets set from user preferences

  // Periodic autosave timer
  Timer? _autosaveTimer;
  static const Duration _periodicAutosaveInterval = Duration(seconds: 20);

  // Previous performance state
  WorkoutExercise? _previousPerformance;
  DateTime? _lastWorkoutDate;
  WorkoutSet? _bestSetEver;

  // Progression suggestion state
  Map<String, dynamic>? _progressionSuggestion;

  // Last workout expanded state
  bool _isLastWorkoutExpanded = false;

  // Track which sets have been manually edited (by set ID)
  final Set<String> _manuallyEditedSetIds = {};

  // Track if user navigated in order (for auto-progression)
  bool _isNavigatedInOrder = true;

  // Set mode for Add Set behavior
  SetMode _selectedSetMode = SetMode.repeat;

  // Custom keypad state
  int? _keypadSetIndex;
  bool _isKeypadForWeight = true;
  String _keypadInput = '';

  // Helper getter for preferred unit
  String get preferredUnit {
    final provider = Provider.of<AppProvider>(context, listen: false);
    return provider.preferredUnit;
  }

  get colors => null;

  @override
  void initState() {
    super.initState();
    _loadWorkout();
    _startPeriodicAutosave();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _restTimer?.cancel();
    _autosaveTimer?.cancel();
    super.dispose();
  }

  /// Start periodic autosave (every 20 seconds) for video-game-like crash recovery
  void _startPeriodicAutosave() {
    _autosaveTimer = Timer.periodic(_periodicAutosaveInterval, (timer) {
      if (_workout != null && !_workout!.isCompleted) {
        _performAutosave(reason: 'periodic');
      }
    });
  }

  /// Perform autosave with optional reason for debugging
  Future<void> _performAutosave({String reason = 'manual'}) async {
    if (_workout == null) return;

    final provider = Provider.of<AppProvider>(context, listen: false);

    // Prepare rest timer state for recovery
    final restTimerState = _isResting ? {
      'isResting': _isResting,
      'restSecondsRemaining': _restSecondsRemaining,
    } : null;

    // Save session state with current exercise index and rest timer state
    await provider.sessionService.saveSessionState(
      _workout!,
      currentExerciseIndex: _currentExerciseIndex,
      restTimerState: restTimerState,
      force: reason == 'periodic', // Force periodic saves to ensure regularity
    );

    debugPrint('💾 Autosave triggered: $reason (exercise ${_currentExerciseIndex + 1})');
  }

  void _startRestTimer() async {
    _restTimer?.cancel();
    setState(() {
      _isResting = true;
      _restSecondsRemaining = _currentRestTimerSeconds;
    });

    // Play rest timer start audio cue
    final provider = Provider.of<AppProvider>(context, listen: false);
    await AudioCueService().playRestStart(provider.currentUser);

    // Trigger autosave when rest timer starts
    _performAutosave(reason: 'rest_timer_start');

    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_restSecondsRemaining > 0) {
          _restSecondsRemaining--;
        } else {
          _stopRestTimer();
        }
      });
    });
  }

  void _stopRestTimer() async {
    final wasResting = _isResting;
    _restTimer?.cancel();
    setState(() {
      _isResting = false;
      _restSecondsRemaining = _currentRestTimerSeconds;
    });

    // Play rest timer complete audio cue (only if rest was active)
    if (wasResting) {
      final provider = Provider.of<AppProvider>(context, listen: false);
      await AudioCueService().playRestComplete(provider.currentUser);

      // Trigger autosave when rest timer stops
      _performAutosave(reason: 'rest_timer_stop');
    }
  }

  void _resetRestTimer() {
    _restTimer?.cancel();
    setState(() {
      _restSecondsRemaining = _currentRestTimerSeconds;
    });
    _startRestTimer();
  }

  void _adjustRestTimer(int seconds) {
    setState(() {
      _restSecondsRemaining = (_restSecondsRemaining + seconds).clamp(0, 600); // Max 10 minutes
    });

    // Trigger autosave when rest timer is adjusted
    _performAutosave(reason: 'rest_timer_adjust');
  }

  void _showRestTimerSettings() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = Provider.of<AppProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Row(
              children: [
                Icon(
                  Icons.timer_outlined,
                  color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Rest Timer Settings',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Quick preset buttons
            Text(
              'Quick Presets',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
              ),
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [30, 60, 90, 120, 180].map((seconds) {
                final minutes = seconds ~/ 60;
                final secs = seconds % 60;
                final label = secs == 0 ? '${minutes}m' : '${minutes}m ${secs}s';
                final isSelected = _currentRestTimerSeconds == seconds;

                return InkWell(
                  onTap: () {
                    setState(() {
                      _currentRestTimerSeconds = seconds;
                      if (_currentExercise != null) {
                        provider.setExerciseRestTimer(_currentExercise!.exercise.id, seconds);
                      }
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Rest timer set to $label for ${_currentExercise!.exercise.name}'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                        ? (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
                        : (isDark ? AppColors.darkBackground : AppColors.lightBackground),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                          ? (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
                          : (isDark ? AppColors.darkDivider : AppColors.lightDivider),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected
                          ? (isDark ? AppColors.darkOnPrimary : AppColors.lightOnPrimary)
                          : (isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Reset to default button
            OutlinedButton.icon(
              onPressed: () {
                if (_currentExercise != null) {
                  provider.removeExerciseRestTimer(_currentExercise!.exercise.id);
                  setState(() {
                    _currentRestTimerSeconds = provider.currentUser?.defaultRestTimerSeconds ?? 90;
                  });
                }
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Reset to default rest timer'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reset to Default'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _loadWorkout() async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final workouts = provider.workouts;
    final workout = workouts.firstWhere((w) => w.id == widget.workoutId);

    // Clear manually edited set tracking when loading a workout
    _manuallyEditedSetIds.clear();

    // Check if this is a recovered session and restore state
    final sessionData = await provider.sessionService.loadSessionState();
    int? recoveredExerciseIndex;
    Map<String, dynamic>? recoveredRestTimerState;

    if (sessionData != null && (sessionData['workout'] as Workout).id == widget.workoutId) {
      // This is a recovered session - restore additional state
      recoveredExerciseIndex = sessionData['currentExerciseIndex'] as int?;
      recoveredRestTimerState = sessionData['restTimerState'] as Map<String, dynamic>?;
      debugPrint('🔄 Restoring session state: exercise ${recoveredExerciseIndex != null ? recoveredExerciseIndex + 1 : 'unknown'}');
    }

    setState(() {
      _workout = workout;
      // If exerciseIndex is provided, use it (user tapped on an existing exercise)
      if (widget.exerciseIndex != null) {
        final index = int.tryParse(widget.exerciseIndex!) ?? -1;
        if (index >= 0 && index < workout.exercises.length) {
          _currentExerciseIndex = index;
          _currentExercise = workout.exercises[index];

          // Check if user navigated in order or jumped to a specific exercise
          _isNavigatedInOrder = _isExerciseNextInOrder(index);
        }
      }
      // If NO exerciseIndex is provided, show exercise selection screen
      // Do NOT auto-restore recovered exercise index - let the user choose
      // This ensures "Add Exercise" button works correctly
      // Otherwise, _currentExercise remains null, which will show exercise selection screen

      // Load rest timer setting for current exercise (if set)
      if (_currentExercise != null) {
        _currentRestTimerSeconds = provider.getRestTimerForExercise(_currentExercise!.exercise.id);
      }

      // Restore rest timer state if available
      if (recoveredRestTimerState != null && recoveredRestTimerState['isResting'] == true) {
        _isResting = true;
        _restSecondsRemaining = recoveredRestTimerState['restSecondsRemaining'] as int? ?? _currentRestTimerSeconds;
        // Restart timer with recovered time
        _startRestTimer();
        debugPrint('⏱️ Restored rest timer: ${_restSecondsRemaining}s remaining');
      }
    });

    // Log screen to Crashlytics
    final crashlytics = CrashlyticsService();
    await crashlytics.logScreen('LogExercise');
    if (_currentExercise != null) {
      await crashlytics.setCustomKey('current_exercise', _currentExercise!.exercise.name);
    }

    // Load previous performance for the current exercise if it exists
    if (_currentExercise != null) {
      await _loadPreviousPerformance(_currentExercise!.exercise.id);
    }
  }

  /// Check if the given exercise index is the next unfinished exercise in order
  bool _isExerciseNextInOrder(int index) {
    if (_workout == null) return false;

    // Find the first unfinished exercise
    final nextUnfinishedIndex = _workout!.exercises.indexWhere((ex) {
      final completedSets = ex.sets.where((set) => set.isCompleted).length;
      final totalSets = ex.sets.length;
      return completedSets < totalSets;
    });

    // If no unfinished exercise found or this is the next unfinished one, it's in order
    return nextUnfinishedIndex == -1 || index == nextUnfinishedIndex;
  }

  /// Get the next exercise index in the routine
  int? _getNextExerciseIndex() {
    if (_workout == null || _currentExerciseIndex == -1) return null;

    // Look for the next unfinished exercise after the current one
    for (int i = _currentExerciseIndex + 1; i < _workout!.exercises.length; i++) {
      final ex = _workout!.exercises[i];
      final completedSets = ex.sets.where((set) => set.isCompleted).length;
      final totalSets = ex.sets.length;

      if (completedSets < totalSets) {
        return i;
      }
    }

    return null; // No more exercises
  }

  Future<void> _loadPreviousPerformance(String exerciseId) async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final userId = _workout?.userId ?? 'user_1';

    // Get exercise history to find the date
    final history = await provider.workoutService.getExerciseHistory(userId, exerciseId);

    // Get best set ever
    final bestSet = await provider.workoutService.getBestSetEver(userId, exerciseId);

    // Get progression suggestion
    final suggestion = await provider.workoutService.getProgressionSuggestion(userId, exerciseId);

    if (history.isNotEmpty) {
      final lastEntry = history.first;
      final lastOccurrence = await provider.workoutService.getLastExerciseOccurrence(userId, exerciseId);
      setState(() {
        _previousPerformance = lastOccurrence;
        _lastWorkoutDate = lastEntry['date'] as DateTime;
        _bestSetEver = bestSet;
        _progressionSuggestion = suggestion;
      });
    } else {
      setState(() {
        _previousPerformance = null;
        _lastWorkoutDate = null;
        _bestSetEver = null;
        _progressionSuggestion = null;
      });
    }
  }

  Future<void> _saveWorkout() async {
    if (_workout == null) return;
    final provider = Provider.of<AppProvider>(context, listen: false);

    try {
      // Update the current exercise in the workout
      if (_currentExercise != null && _currentExerciseIndex >= 0) {
        final updatedExercises = List<WorkoutExercise>.from(_workout!.exercises);
        updatedExercises[_currentExerciseIndex] = _currentExercise!;
        _workout = _workout!.copyWith(
          exercises: updatedExercises,
          updatedAt: DateTime.now(),
        );
      }

      // Prepare rest timer state for autosave
      final restTimerState = _isResting ? {
        'isResting': _isResting,
        'restSecondsRemaining': _restSecondsRemaining,
      } : null;

      // Update workout with autosave context
      await provider.updateWorkout(
        _workout!,
        currentExerciseIndex: _currentExerciseIndex,
        restTimerState: restTimerState,
      );

      debugPrint('💾 Workout saved with autosave context');
    } catch (e, stackTrace) {
      // Log error to Crashlytics
      await CrashlyticsService().recordError(
        e,
        stackTrace,
        reason: 'Failed to save workout in LogExerciseScreen',
      );
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final preferredUnit = Provider.of<AppProvider>(context).preferredUnit;

    if (_workout == null) {
      return Scaffold(
        backgroundColor: context.colors.background,
        body: Center(child: CircularProgressIndicator(color: context.colors.primaryAccent)),
      );
    }

    if (_currentExercise == null) {
      return _buildExerciseSelection();
    }

    return _buildWorkoutSession();
  }

  Widget _buildWorkoutSession() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = context.colors;

    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Compact Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: context.colors.card,
                border: Border(bottom: BorderSide(color: context.colors.divider)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded, size: 22),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () async {
                          await _saveWorkout();
                          if (context.mounted) {
                            context.go('${AppRoutes.workoutSession}/${widget.workoutId}');
                          }
                        },
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            _isResting ? _buildRestTimerDisplay(isDark) : _buildWorkoutTimerDisplay(isDark),
                            const SizedBox(height: 2),
                            WorkoutDatePicker(
                              selectedDate: _workout!.startTime,
                              onDateChanged: (date) {
                                setState(() {
                                  _workout = _workout!.copyWith(
                                    startTime: date,
                                    updatedAt: DateTime.now(),
                                  );
                                });
                                _saveWorkout();
                              },
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => _finishWorkout(),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(50, 30),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Finish',
                          style: TextStyle(
                            color: colors.success,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Exercise Info Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: context.colors.card,
                border: Border(bottom: BorderSide(color: context.colors.divider)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _currentExercise!.exercise.name,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              FormatUtils.formatMuscleGroup(_currentExercise!.exercise.primaryMuscleGroup.name),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.colors.secondaryText),
                            ),
                          ],
                        ),
                      ),
                      // Exercise Progress Button
                      IconButton(
                        icon: Icon(Icons.bar_chart_rounded, color: context.colors.accentMedium),
                        onPressed: () {
                          context.push('${AppRoutes.exerciseProgress}/${_currentExercise!.exercise.id}');
                        },
                        tooltip: 'View Progress',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: _keypadSetIndex != null 
                ? _buildKeypadView() 
                : _buildSetsList(),
            ),

            // Quick Add Set Button (bottom action bar)
            if (_keypadSetIndex == null) _buildQuickAddButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildRestTimerDisplay(bool isDark) {
    final minutes = _restSecondsRemaining ~/ 60;
    final seconds = _restSecondsRemaining % 60;
    final timeText = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return GestureDetector(
      onTap: _showRestTimerControls,
      child: WorkoutTimerDisplay(
        timeText: timeText,
        icon: Icons.timer_outlined,
        isDark: isDark,
        label: 'REST',
        isCompact: true,
      ),
    );
  }

  Widget _buildWorkoutTimerDisplay(bool isDark) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final duration = provider.sessionDuration;
        final hours = duration.inHours;
        final minutes = duration.inMinutes.remainder(60);
        final seconds = duration.inSeconds.remainder(60);

        String timeText;
        if (hours > 0) {
          timeText = '${hours}h ${minutes}m';
        } else if (minutes > 0) {
          timeText = '${minutes}m ${seconds}s';
        } else {
          timeText = '${seconds}s';
        }

        return WorkoutTimerDisplay(
          timeText: timeText,
          icon: Icons.timer_outlined,
          isDark: isDark,
          isCompact: true,
        );
      },
    );
  }

  void _showRestTimerControls() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: context.colors.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: context.colors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Text(
              'Rest Timer',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // Timer display
            Text(
              '${(_restSecondsRemaining ~/ 60).toString().padLeft(2, '0')}:${(_restSecondsRemaining % 60).toString().padLeft(2, '0')}',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontFeatures: [const FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 24),

            // Quick adjust buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton.filled(
                  onPressed: () => _adjustRestTimer(-15),
                  icon: const Icon(Icons.remove),
                  style: IconButton.styleFrom(
                    backgroundColor: context.colors.background,
                    foregroundColor: context.colors.primaryText,
                  ),
                ),
                TextButton.icon(
                  onPressed: _resetRestTimer,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Reset'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
                IconButton.filled(
                  onPressed: () => _adjustRestTimer(15),
                  icon: const Icon(Icons.add),
                  style: IconButton.styleFrom(
                    backgroundColor: context.colors.background,
                    foregroundColor: context.colors.primaryText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Skip/Stop buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _stopRestTimer();
                      Navigator.pop(context);
                    },
                    child: const Text('Skip Rest'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetsList() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final preferredUnit = Provider.of<AppProvider>(context).preferredUnit;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Last workout reference (if available)
        if (_previousPerformance != null && _lastWorkoutDate != null)
          _buildLastWorkoutCard(isDark, preferredUnit),

        const SizedBox(height: 16),

        // Sets list
        ..._currentExercise!.sets.asMap().entries.map((entry) {
          final index = entry.key;
          final set = entry.value;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: CompactSetRow(
              index: index,
              workoutSet: set,
              exercise: _currentExercise!.exercise,
              preferredUnit: preferredUnit,
              onUpdate: (updatedSet) {
                setState(() {
                  _currentExercise!.sets[index] = updatedSet;
                });
              },
              onTapWeight: () => _showCustomKeypad(index, isWeight: true),
              onTapReps: () => _showCustomKeypad(index, isWeight: false),
              onToggleComplete: () => _toggleSetCompletion(index),
              onDelete: () => _deleteSet(index),
            ),
          );
        }),

        const SizedBox(height: 12),

        // Set mode selector
        _buildSetModeSelector(isDark),

        const SizedBox(height: 12),

        // Add Set button
        OutlinedButton.icon(
          onPressed: _addSet,
          icon: const Icon(Icons.add_rounded),
          label: Text(_getAddSetButtonLabel()),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            side: BorderSide(color: context.colors.border),
          ),
        ),

        const SizedBox(height: 80), // Space for bottom button
      ],
    );
  }

  Widget _buildSetModeSelector(bool isDark) {
    return Row(
      children: [
        Text(
          'Add Set Mode:',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: context.colors.secondaryText,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Wrap(
            spacing: 8,
            children: [
              AppFilterChip(
                label: 'Repeat',
                selected: _selectedSetMode == SetMode.repeat,
                onTap: () => setState(() => _selectedSetMode = SetMode.repeat),
              ),
              AppFilterChip(
                label: 'Progressive',
                selected: _selectedSetMode == SetMode.progressive,
                onTap: () => setState(() => _selectedSetMode = SetMode.progressive),
              ),
              AppFilterChip(
                label: 'Backoff',
                selected: _selectedSetMode == SetMode.backoff,
                onTap: () => setState(() => _selectedSetMode = SetMode.backoff),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getAddSetButtonLabel() {
    switch (_selectedSetMode) {
      case SetMode.repeat:
        return 'Repeat Last Set';
      case SetMode.progressive:
        return 'Progressive (+5%)';
      case SetMode.backoff:
        return 'Backoff (-10%)';
    }
  }

  void _addSet() {
    final lastSet = _currentExercise!.sets.isNotEmpty ? _currentExercise!.sets.last : null;

    double newWeight;
    int newReps;

    if (lastSet != null) {
      switch (_selectedSetMode) {
        case SetMode.repeat:
          newWeight = lastSet.weightKg;
          newReps = lastSet.reps;
          break;
        case SetMode.progressive:
          newWeight = lastSet.weightKg * 1.05; // +5%
          newReps = lastSet.reps;
          break;
        case SetMode.backoff:
          newWeight = lastSet.weightKg * 0.90; // -10%
          newReps = lastSet.reps;
          break;
      }
    } else {
      // No previous sets - use smart defaults
      newWeight = ProgressiveOverloadService.getNextSetWeight(
        exercise: _currentExercise!.exercise,
        currentSets: [],
        lastWorkoutPerformance: _previousPerformance,
        setIndex: 0,
      );
      newReps = ProgressiveOverloadService.getNextSetReps(
        exercise: _currentExercise!.exercise,
        currentSets: [],
        lastWorkoutPerformance: _previousPerformance,
      );
    }

    final newSet = WorkoutSet(
      id: const Uuid().v4(),
      setNumber: _currentExercise!.sets.length + 1,
      weightKg: newWeight,
      reps: newReps,
      isCompleted: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    setState(() {
      _currentExercise = _currentExercise!.copyWith(
        sets: [..._currentExercise!.sets, newSet],
        updatedAt: DateTime.now(),
      );
    });

    _saveWorkout();
  }

  void _deleteSet(int index) {
    final updatedSets = List<WorkoutSet>.from(_currentExercise!.sets);
    updatedSets.removeAt(index);

    // Renumber remaining sets
    for (int i = 0; i < updatedSets.length; i++) {
      updatedSets[i] = updatedSets[i].copyWith(setNumber: i + 1);
    }

    setState(() {
      _currentExercise = _currentExercise!.copyWith(
        sets: updatedSets,
        updatedAt: DateTime.now(),
      );
    });

    _saveWorkout();
  }

  void _toggleSetCompletion(int index) async {
    final set = _currentExercise!.sets[index];
    final updatedSet = set.copyWith(
      isCompleted: !set.isCompleted,
      completedAt: !set.isCompleted ? DateTime.now() : null,
      updatedAt: DateTime.now(),
    );

    _updateSet(index, updatedSet);

    // Start rest timer if set was just completed
    if (updatedSet.isCompleted && !set.isCompleted) {
      _startRestTimer();
    }
  }

  void _updateSet(int index, WorkoutSet updatedSet) {
    final updatedSets = List<WorkoutSet>.from(_currentExercise!.sets);
    updatedSets[index] = updatedSet;

    setState(() {
      _currentExercise = _currentExercise!.copyWith(
        sets: updatedSets,
        updatedAt: DateTime.now(),
      );
    });

    _saveWorkout();
  }

  Widget _buildLastWorkoutCard(bool isDark, String preferredUnit) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isLastWorkoutExpanded = !_isLastWorkoutExpanded;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.colors.card,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: context.colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Last Workout',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.colors.secondaryText,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      FormatUtils.formatDate(_lastWorkoutDate!),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.colors.hint,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      _isLastWorkoutExpanded ? Icons.expand_less : Icons.expand_more,
                      color: context.colors.hint,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_isLastWorkoutExpanded) ...[
              ..._previousPerformance!.sets.where((s) => s.isCompleted).map((set) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: context.colors.background,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Center(
                        child: Text(
                          '${set.setNumber}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${FormatUtils.formatWeight(set.weightKg, preferredUnit)} × ${set.reps}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              )),
            ] else ...[
              // Compact summary
              Text(
                '${_previousPerformance!.sets.where((s) => s.isCompleted).length} sets',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],

            if (_bestSetEver != null) ...[
              const SizedBox(height: 12),
              Divider(color: context.colors.divider),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.emoji_events_rounded, color: context.colors.warning, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Best: ${FormatUtils.formatWeight(_bestSetEver!.weightKg, preferredUnit)} × ${_bestSetEver!.reps}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: context.colors.warning,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showPlateCalculator(double weightKg) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PlateCalculatorModal(
        targetWeight: weightKg,
        equipmentType: _currentExercise!.exercise.equipment,
      ),
    );
  }

  Widget _buildKeypadView() {
    final set = _currentExercise!.sets[_keypadSetIndex!];

    return CustomWorkoutKeypad(
      setIndex: _keypadSetIndex!,
      isKeypadForWeight: _isKeypadForWeight,
      keypadInput: _keypadInput,
      preferredUnit: preferredUnit,
      onInput: _handleKeypadInput,
      onNext: _handleKeypadNext,
      onClose: _closeKeypad,
    );
  }

  Widget _buildQuickAddButton() {
    final preferredUnit = Provider.of<AppProvider>(context).preferredUnit;
    final colors = context.colors;

    // Use smart progressive overload to calculate recommended next set
    final setIndex = _currentExercise!.sets.length;

    final recommendedWeight = ProgressiveOverloadService.getNextSetWeight(
      exercise: _currentExercise!.exercise,
      currentSets: _currentExercise!.sets,
      lastWorkoutPerformance: _previousPerformance,
      setIndex: setIndex,
    );

    final recommendedReps = ProgressiveOverloadService.getNextSetReps(
      exercise: _currentExercise!.exercise,
      currentSets: _currentExercise!.sets,
      lastWorkoutPerformance: _previousPerformance,
    );

    // Convert weight to display unit for showing in the button
    final displayWeight = UnitConversion.toDisplayUnit(recommendedWeight, preferredUnit);

    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
        border: Border(top: BorderSide(color: colors.divider)),
      ),
      padding: AppSpacing.paddingLg,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            onPressed: () => _quickAddSet(recommendedWeight, recommendedReps),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 64),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
              elevation: 4,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_rounded, size: 28, color: colors.onPrimary),
                const SizedBox(width: 12),
                Text(
                  'ADD SET: ${displayWeight.round()} $preferredUnit × $recommendedReps',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colors.onPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseSelection() {
    final provider = Provider.of<AppProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Filter exercises based on search and muscle group
    final filteredExercises = provider.exercises.where((exercise) {
      final matchesSearch = _searchQuery.isEmpty ||
          exercise.name.toLowerCase().contains(_searchQuery);
      final matchesMuscleFilter = _selectedMuscleFilter == null ||
          exercise.primaryMuscleGroup == _selectedMuscleFilter;
      return matchesSearch && matchesMuscleFilter;
    }).toList();

    return Scaffold(
      backgroundColor: context.colors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add Exercise'),
            if (_workout!.exercises.isNotEmpty)
              Text(
                '${_workout!.exercises.length} exercise${_workout!.exercises.length == 1 ? '' : 's'} added',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.colors.secondaryText),
              ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () async {
            await _saveWorkout();
            if (context.mounted) {
              context.pop();
            }
          },
        ),
      ),
      body: Column(
        children: [
          // Workout Summary
          if (_workout!.exercises.isNotEmpty)
            Container(
              margin: AppSpacing.paddingLg,
              padding: AppSpacing.paddingMd,
              decoration: BoxDecoration(
                color: context.colors.card,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: context.colors.border),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildWorkoutStat(context, Icons.fitness_center_rounded, 'Exercises', '${_workout!.exercises.length}'),
                      Container(width: 1, height: 32, color: context.colors.divider),
                      _buildWorkoutStat(context, Icons.format_list_numbered_rounded, 'Sets', '${_workout!.totalSets}'),
                      Container(width: 1, height: 32, color: context.colors.divider),
                      _buildWorkoutStat(context, Icons.monitor_weight_rounded, 'Volume', FormatUtils.formatWeight(_workout!.totalVolume, preferredUnit)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Divider(color: context.colors.divider),
                  const SizedBox(height: 8),
                  ..._workout!.exercises.map((ex) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, size: 16, color: context.colors.success),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            ex.exercise.name,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        Text(
                          '${ex.sets.length} ${ex.sets.length == 1 ? 'set' : 'sets'}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.colors.secondaryText),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          // Search Bar
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              style: Theme.of(context).textTheme.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Search exercises...',
                hintStyle: TextStyle(color: context.colors.hint),
                prefixIcon: Icon(Icons.search_rounded, color: context.colors.hint),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear_rounded, color: context.colors.hint),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                filled: true,
                fillColor: context.colors.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  borderSide: BorderSide(color: context.colors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  borderSide: BorderSide(color: context.colors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  borderSide: BorderSide(color: context.colors.primaryAccent, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
          ),
          // Muscle Group Filters
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildMuscleFilterChip('All', null, isDark),
                ...MuscleGroup.values.map((muscle) =>
                  _buildMuscleFilterChip(FormatUtils.formatMuscleGroup(muscle.name), muscle, isDark)
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Exercise List
          Expanded(
            child: filteredExercises.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 64,
                          color: isDark ? AppColors.darkHint : AppColors.lightHint,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No exercises found',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try a different search or filter',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isDark ? AppColors.darkHint : AppColors.lightHint,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: filteredExercises.length,
                    itemBuilder: (context, index) {
                      final exercise = filteredExercises[index];
                      return GestureDetector(
                        onTap: () => _selectExercise(exercise),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: AppSpacing.paddingMd,
                          decoration: BoxDecoration(
                            color: context.colors.card,
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            border: Border.all(color: context.colors.border),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: context.colors.background,
                                  borderRadius: BorderRadius.circular(AppRadius.md),
                                ),
                                child: Icon(
                                  Icons.fitness_center_rounded,
                                  color: context.colors.accentMedium,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      exercise.name,
                                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      FormatUtils.formatMuscleGroup(exercise.primaryMuscleGroup.name),
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.colors.secondaryText),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.add_circle_rounded,
                                color: context.colors.primaryAccent,
                                size: 32,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMuscleFilterChip(String label, MuscleGroup? muscle, bool isDark) {
    final isSelected = _selectedMuscleFilter == muscle;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: AppFilterChip(
        label: label,
        selected: isSelected,
        onTap: () {
          setState(() {
            _selectedMuscleFilter = muscle;
          });
        },
      ),
    );
  }

  Widget _buildWorkoutStat(BuildContext context, IconData icon, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Icon(icon, size: 20, color: context.colors.accentMedium),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: isDark ? AppColors.darkHint : AppColors.lightHint)),
      ],
    );
  }

  void _showCustomKeypad(int setIndex, {required bool isWeight}) {
    setState(() {
      _keypadSetIndex = setIndex;
      _isKeypadForWeight = isWeight;
      // Clear input when keypad opens - user types fresh value
      _keypadInput = '';
    });
  }

  void _closeKeypad() {
    setState(() {
      _keypadSetIndex = null;
      _keypadInput = '';
    });
  }

  void _handleKeypadInput(String value) {
    setState(() {
      if (value == 'backspace') {
        if (_keypadInput.isNotEmpty) {
          _keypadInput = _keypadInput.substring(0, _keypadInput.length - 1);
        }
      } else {
        // Limit input to 4 digits
        if (_keypadInput.length < 4) {
          _keypadInput += value;
        }
      }
    });
  }

  void _handleKeypadNext() {
    if (_keypadSetIndex == null || _keypadInput.isEmpty) return;

    final enteredValue = int.tryParse(_keypadInput) ?? 0;
    if (enteredValue == 0) return;

    final set = _currentExercise!.sets[_keypadSetIndex!];

    if (_isKeypadForWeight) {
      // Update weight and move to reps
      final weightKg = UnitConversion.toStorageUnit(enteredValue.toDouble(), preferredUnit);
      final updatedSet = set.copyWith(
        weightKg: weightKg,
        updatedAt: DateTime.now(),
      );
      _updateSet(_keypadSetIndex!, updatedSet);

      // Move to reps - clear input for fresh entry
      setState(() {
        _isKeypadForWeight = false;
        _keypadInput = '';
      });
    } else {
      // Update reps and complete the set
      final updatedSet = set.copyWith(
        reps: enteredValue,
        isCompleted: true,
        completedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      _updateSet(_keypadSetIndex!, updatedSet);

      // Close keypad and start rest timer
      _closeKeypad();
      _startRestTimer();

      // Auto-advance to next set if available
      if (_keypadSetIndex! < _currentExercise!.sets.length - 1) {
        // Move to next set after a brief delay
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _showCustomKeypad(_keypadSetIndex! + 1, isWeight: true);
          }
        });
      }
    }
  }

  void _selectExercise(Exercise exercise) async {
    final provider = Provider.of<AppProvider>(context, listen: false);

    // Clear manually edited set tracking for new exercise
    _manuallyEditedSetIds.clear();

    // Try to get the last time this exercise was logged with completed sets
    final lastOccurrence = await provider.workoutService.getLastExerciseOccurrence(
      _workout!.userId,
      exercise.id,
    );

    // Load rest timer for this exercise
    final restTimer = provider.getRestTimerForExercise(exercise.id);

    // Auto-generate sets based on history with smart progressive overload
    List<WorkoutSet> initialSets = [];

    if (lastOccurrence != null && lastOccurrence.sets.isNotEmpty) {
      // Use previous workout's structure but apply progressive overload
      final numSets = lastOccurrence.sets.where((s) => s.isCompleted).length;

      for (int i = 0; i < numSets; i++) {
        final recommendedWeight = ProgressiveOverloadService.getNextSetWeight(
          exercise: exercise,
          currentSets: initialSets,
          lastWorkoutPerformance: lastOccurrence,
          setIndex: i,
        );

        final recommendedReps = ProgressiveOverloadService.getNextSetReps(
          exercise: exercise,
          currentSets: initialSets,
          lastWorkoutPerformance: lastOccurrence,
        );

        initialSets.add(WorkoutSet(
          id: const Uuid().v4(),
          setNumber: i + 1,
          weightKg: recommendedWeight, // Already in kg from progressive overload service
          reps: recommendedReps,
          isCompleted: false, // Start uncompleted
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      }
    }

    // If no valid history found, create 3 default sets with smart defaults
    if (initialSets.isEmpty) {
      for (int i = 0; i < 3; i++) {
        final recommendedWeight = ProgressiveOverloadService.getNextSetWeight(
          exercise: exercise,
          currentSets: initialSets,
          lastWorkoutPerformance: null,
          setIndex: i,
        );

        final recommendedReps = ProgressiveOverloadService.getNextSetReps(
          exercise: exercise,
          currentSets: initialSets,
          lastWorkoutPerformance: null,
        );

        initialSets.add(WorkoutSet(
          id: const Uuid().v4(),
          setNumber: i + 1,
          weightKg: recommendedWeight, // Already in kg from progressive overload service
          reps: recommendedReps,
          isCompleted: false, // Start uncompleted
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
      }
    }

    final workoutExercise = WorkoutExercise(
      id: const Uuid().v4(),
      exercise: exercise,
      sets: initialSets,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    setState(() {
      _workout = _workout!.copyWith(
        exercises: [..._workout!.exercises, workoutExercise],
      );
      // DO NOT set _currentExercise or _currentExerciseIndex
      // Stay in exercise selection mode so user can add more exercises
      _currentRestTimerSeconds = restTimer;
    });

    await _saveWorkout();

    // Show confirmation that exercise was added
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${exercise.name} added to workout'),
          backgroundColor: context.colors.success,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _quickAddSet(double weightKg, int reps) {
    final newSet = WorkoutSet(
      id: const Uuid().v4(),
      setNumber: _currentExercise!.sets.length + 1,
      weightKg: weightKg,
      reps: reps,
      isCompleted: true,
      completedAt: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    setState(() {
      _currentExercise = _currentExercise!.copyWith(
        sets: [..._currentExercise!.sets, newSet],
        updatedAt: DateTime.now(),
      );
    });

    _saveWorkout();
    _startRestTimer();
  }

  void _finishWorkout() async {
    await _saveWorkout();
    if (context.mounted) {
      context.go('${AppRoutes.workoutSession}/${widget.workoutId}');
    }
  }
}
