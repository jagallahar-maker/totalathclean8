import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:total_athlete/providers/app_provider.dart';
import 'package:total_athlete/models/theme_config.dart';
import 'package:total_athlete/theme.dart';
import 'package:total_athlete/models/workout.dart';
import 'package:total_athlete/models/workout_exercise.dart';
import 'package:total_athlete/utils/format_utils.dart';
import 'package:total_athlete/services/audio_cue_service.dart';
import 'package:total_athlete/widgets/workout_date_picker.dart';
import 'package:total_athlete/widgets/pr_celebration_overlay.dart';
import 'package:total_athlete/widgets/workout_timer_display.dart';
import 'package:total_athlete/services/crashlytics_service.dart';

class WorkoutSessionScreen extends StatefulWidget {
  final String workoutId;

  const WorkoutSessionScreen({super.key, required this.workoutId});

  @override
  State<WorkoutSessionScreen> createState() => _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends State<WorkoutSessionScreen> with WidgetsBindingObserver {
  Workout? _workout;
  Timer? _autosaveTimer;
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _exerciseKeys = {};
  bool _isRecoveredSession = false;
  bool _isLoading = true;
  
  // Periodic autosave interval (like a video game autosave)
  static const Duration _periodicAutosaveInterval = Duration(seconds: 20);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadWorkout();
    _startPeriodicAutosave();
    _setupPrCelebration();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (state == AppLifecycleState.resumed) {
      // App came back to foreground - reload workout session from storage
      debugPrint('📱 App resumed - reloading workout session from storage');
      _reloadWorkoutFromStorage();
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // App going to background - force autosave
      debugPrint('📱 App paused/inactive - forcing autosave');
      _performAutosave(reason: 'app_background');
    }
  }
  
  /// Reload workout from storage (used when app resumes from background)
  /// This ensures we have the latest session data even if SharedPreferences cache was stale
  Future<void> _reloadWorkoutFromStorage() async {
    if (!mounted) return;
    
    final provider = Provider.of<AppProvider>(context, listen: false);
    
    try {
      // Force reload from SharedPreferences (web-safe)
      final sessionData = await provider.sessionService.loadSessionState();
      
      if (sessionData != null) {
        final reloadedWorkout = sessionData['workout'] as Workout;
        
        // Only update if this is the same workout we're viewing
        if (reloadedWorkout.id == widget.workoutId) {
          setState(() {
            _workout = reloadedWorkout;
          });
          
          // Also update in provider to keep everything in sync
          await provider.updateWorkout(reloadedWorkout, forceAutosave: true);
          
          debugPrint('✅ Workout session reloaded from storage after app resume');
          debugPrint('   - Name: ${reloadedWorkout.name}');
          debugPrint('   - Start time: ${reloadedWorkout.startTime}');
          debugPrint('   - Duration: ${DateTime.now().difference(reloadedWorkout.startTime)}');
          debugPrint('   - Completed sets: ${reloadedWorkout.completedSets}/${reloadedWorkout.totalSets}');
        }
      }
    } catch (e) {
      debugPrint('⚠️ Failed to reload workout from storage: $e');
    }
  }
  
  void _setupPrCelebration() {
    final provider = Provider.of<AppProvider>(context, listen: false);
    provider.setOnPrAchieved(() {
      if (mounted) {
        // Get the current theme's celebration color
        final themeConfig = provider.themeConfig;
        Color celebrationColor;
        
        if (themeConfig.appearanceMode == AppearanceMode.custom && themeConfig.colorPack != null) {
          final palette = ColorPacks.getPalette(themeConfig.colorPack!);
          celebrationColor = palette.celebrationGlow;
        } else {
          // Use default accent color
          celebrationColor = Theme.of(context).colorScheme.primary;
        }
        
        showPrCelebration(context, celebrationColor);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final provider = Provider.of<AppProvider>(context, listen: false);
    provider.setOnPrAchieved(null); // Clear the callback
    _autosaveTimer?.cancel();
    _scrollController.dispose();
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
    
    // Save session state directly (without triggering full workout update)
    await provider.sessionService.saveSessionState(
      _workout!,
      force: reason == 'periodic', // Force periodic saves to ensure regularity
    );
    
    debugPrint('💾 Autosave triggered: $reason');
  }

  Future<void> _loadWorkout() async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final workouts = provider.workouts;
    final workout = workouts.firstWhere((w) => w.id == widget.workoutId);
    
    // Check if this is a recovered session
    // A session is only considered "recovered" if:
    // 1. There's a saved session in storage
    // 2. The saved session matches this workout ID
    // 3. The saved session was created BEFORE this workout instance (timeSinceLastSave > 5 seconds)
    final sessionInfo = await provider.sessionService.getSessionInfo();
    bool isRecovered = false;
    Duration? timeSinceLastSave;
    
    if (sessionInfo != null && sessionInfo['workoutId'] == workout.id) {
      timeSinceLastSave = sessionInfo['timeSinceLastSave'] as Duration?;
      // Only treat as recovered if the session was saved more than 5 seconds ago
      // (this prevents showing recovery banner for brand new workouts)
      if (timeSinceLastSave != null && timeSinceLastSave.inSeconds > 5) {
        isRecovered = true;
      }
    }
    
    setState(() {
      _workout = workout;
      _isRecoveredSession = isRecovered;
      _isLoading = false;
      // Initialize keys for each exercise
      for (int i = 0; i < workout.exercises.length; i++) {
        if (!_exerciseKeys.containsKey(i)) {
          _exerciseKeys[i] = GlobalKey();
        }
      }
    });
    
    // Show recovery notification if session was recovered
    if (isRecovered && mounted && timeSinceLastSave != null) {
      // Use theme tokens for the recovery banner
      final themeConfig = provider.themeConfig;
      Color bannerColor;
      
      if (themeConfig.appearanceMode == AppearanceMode.custom && themeConfig.colorPack != null) {
        final palette = ColorPacks.getPalette(themeConfig.colorPack!);
        bannerColor = palette.success;
      } else {
        bannerColor = Theme.of(context).brightness == Brightness.dark 
            ? AppColors.darkSuccess 
            : AppColors.lightSuccess;
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Session recovered from ${_formatTimeSince(timeSinceLastSave)} ago'),
          backgroundColor: bannerColor,
          duration: const Duration(seconds: 3),
        ),
      );
    }
    
    // Log workout context to Crashlytics
    final crashlytics = CrashlyticsService();
    await crashlytics.setWorkoutContext(
      workoutId: workout.id,
      workoutName: workout.name,
      exerciseCount: workout.exercises.length,
    );
    await crashlytics.logScreen('WorkoutSession');
  }
  
  String _formatTimeSince(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m';
    } else {
      return 'moments';
    }
  }

  Future<void> _refreshWorkout() async {
    await _loadWorkout();
    // Scroll to next unfinished exercise after refresh
    _scrollToNextUnfinishedExercise();
  }
  
  void _scrollToNextUnfinishedExercise() {
    if (_workout == null) return;
    
    // Find the first exercise that is not completed
    final nextExerciseIndex = _workout!.exercises.indexWhere((ex) {
      final completedSets = ex.sets.where((set) => set.isCompleted).length;
      final totalSets = ex.sets.length;
      return completedSets < totalSets;
    });
    
    if (nextExerciseIndex >= 0 && _exerciseKeys.containsKey(nextExerciseIndex)) {
      // Wait for build to complete
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final key = _exerciseKeys[nextExerciseIndex];
        if (key?.currentContext != null) {
          Scrollable.ensureVisible(
            key!.currentContext!,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            alignment: 0.2, // Position near top of viewport
          );
        }
      });
    }
  }

  Future<void> _saveWorkout() async {
    if (_workout == null) return;
    final provider = Provider.of<AppProvider>(context, listen: false);
    await provider.updateWorkout(_workout!);
    // Session state is automatically saved in provider.updateWorkout()
  }

  void _showRenameDialog() {
    final colors = context.colors;
    final TextEditingController nameController = TextEditingController(text: _workout!.name);
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: colors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: Text(
          'Rename Workout',
          style: TextStyle(color: colors.primaryText),
        ),
        content: TextField(
          controller: nameController,
          autofocus: true,
          style: TextStyle(color: colors.primaryText),
          decoration: InputDecoration(
            hintText: 'Enter workout name',
            hintStyle: TextStyle(color: colors.hint),
            filled: true,
            fillColor: colors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: colors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: colors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: colors.primaryAccent, width: 2),
            ),
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              setState(() {
                _workout = _workout!.copyWith(
                  name: value.trim(),
                  updatedAt: DateTime.now(),
                );
              });
              _saveWorkout();
              Navigator.of(dialogContext).pop();
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: colors.secondaryText),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final newName = nameController.text.trim();
              if (newName.isNotEmpty) {
                setState(() {
                  _workout = _workout!.copyWith(
                    name: newName,
                    updatedAt: DateTime.now(),
                  );
                });
                _saveWorkout();
                Navigator.of(dialogContext).pop();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _finishWorkout() async {
    if (_workout == null) return;

    final provider = Provider.of<AppProvider>(context, listen: false);

    // Filter out exercises with no completed sets
    final exercisesWithCompletedSets = _workout!.exercises.where((ex) {
      return ex.sets.any((set) => set.isCompleted);
    }).map((ex) {
      // For each exercise, keep only completed sets
      final completedSets = ex.sets.where((set) => set.isCompleted).toList();
      return ex.copyWith(sets: completedSets);
    }).toList();

    // Check if there are any completed sets
    final hasCompletedSets = exercisesWithCompletedSets.isNotEmpty;

    if (!hasCompletedSets) {
      // No completed sets - show discard confirmation
      _showExitConfirmation(hasCompletedSets: false);
      return;
    }

    // Has completed sets - show save/discard confirmation
    _showExitConfirmation(hasCompletedSets: true, exercisesWithCompletedSets: exercisesWithCompletedSets);
  }

  void _showExitConfirmation({
    required bool hasCompletedSets,
    List<WorkoutExercise>? exercisesWithCompletedSets,
  }) {
    final colors = context.colors;
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: colors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: Text(
          hasCompletedSets ? 'Exit Workout' : 'Discard Workout?',
          style: TextStyle(color: colors.primaryText),
        ),
        content: Text(
          hasCompletedSets
              ? 'You have completed ${exercisesWithCompletedSets!.fold<int>(0, (sum, ex) => sum + ex.sets.length)} sets across ${exercisesWithCompletedSets.length} exercise${exercisesWithCompletedSets.length == 1 ? '' : 's'}. What would you like to do?'
              : 'You haven\'t completed any sets. This workout will be discarded.',
          style: TextStyle(color: colors.secondaryText),
        ),
        actions: [
          if (hasCompletedSets) ...[
            // Discard Workout
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _discardWorkout();
              },
              child: Text(
                'Discard',
                style: TextStyle(color: colors.error),
              ),
            ),
            // Resume Later (keep workout active)
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _resumeLater();
              },
              child: Text(
                'Resume Later',
                style: TextStyle(color: colors.secondaryText),
              ),
            ),
            // Finish Workout (complete and save to history)
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _saveAndFinishWorkout(exercisesWithCompletedSets!);
              },
              child: const Text('Finish Workout'),
            ),
          ] else ...[
            // No completed sets - just show OK to discard
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _discardWorkout();
              },
              child: Text(
                'OK',
                style: TextStyle(color: colors.secondaryText),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _saveAndFinishWorkout(List<WorkoutExercise> exercisesWithCompletedSets) async {
    final provider = Provider.of<AppProvider>(context, listen: false);

    // Use original start time to ensure accurate duration/calories
    final originalStartTime = await provider.sessionService.getOriginalStartTime() ?? _workout!.startTime;

    // Save workout with only completed sets
    final completedWorkout = _workout!.copyWith(
      exercises: exercisesWithCompletedSets,
      startTime: originalStartTime, // Preserve original start time
      endTime: DateTime.now(),
      isCompleted: true,
      updatedAt: DateTime.now(),
    );

    await provider.updateWorkout(completedWorkout);
    // Session state is automatically cleared in provider.updateWorkout()

    // Play workout complete audio cue
    await AudioCueService().playWorkoutComplete(provider.currentUser);

    if (mounted) {
      // Navigate back to home
      context.go('/');
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Workout saved! ${exercisesWithCompletedSets.length} exercise${exercisesWithCompletedSets.length == 1 ? '' : 's'} logged.'),
          backgroundColor: context.colors.success,
        ),
      );
    }
  }

  void _resumeLater() async {
    // Just save current state and return to home
    // Do NOT mark workout as completed
    // This keeps the workout active and "Continue Workout" visible
    await _performAutosave(reason: 'resume_later');

    if (mounted) {
      context.go('/');
      
      // Show informational message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Workout paused. Tap "Continue Workout" to resume.'),
          backgroundColor: context.colors.primaryAccent,
        ),
      );
    }
  }

  void _discardWorkout() async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    await provider.deleteWorkout(_workout!.id);
    // Session state is automatically cleared in provider.deleteWorkout()

    if (mounted) {
      context.go('/');
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

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final preferredUnit = Provider.of<AppProvider>(context).preferredUnit;

    // Show loading state while checking for recovered session
    if (_isLoading || _workout == null) {
      return Scaffold(
        backgroundColor: colors.background,
        body: Center(child: CircularProgressIndicator(color: colors.primaryAccent)),
      );
    }

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: AppSpacing.paddingLg,
              decoration: BoxDecoration(
                color: colors.card,
                border: Border(bottom: BorderSide(color: colors.divider)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: _finishWorkout,
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: () => _showRenameDialog(),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      _workout!.name,
                                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Icon(
                                    Icons.edit_rounded,
                                    size: 16,
                                    color: colors.secondaryText,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            WorkoutDatePicker(
                              selectedDate: _workout!.startTime,
                              onDateChanged: (date) async {
                                final provider = Provider.of<AppProvider>(context, listen: false);
                                setState(() {
                                  _workout = _workout!.copyWith(
                                    startTime: date,
                                    updatedAt: DateTime.now(),
                                  );
                                });
                                // Update both workout and session start time
                                await _saveWorkout();
                                await provider.sessionService.updateStartTime(date);
                              },
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: _finishWorkout,
                        child: Text(
                          'Finish',
                          style: TextStyle(
                            color: colors.success,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Session timer
                  Consumer<AppProvider>(
                    builder: (context, provider, _) => WorkoutTimerDisplay(
                      timeText: _formatDuration(provider.sessionDuration),
                      icon: Icons.timer_outlined,
                      isDark: isDark,
                      isCompact: false,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Workout stats
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(context, 'Exercises', '${_workout!.exercises.length}'),
                        Container(width: 1, height: 32, color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
                        _buildStatItem(context, 'Completed Sets', '${_workout!.completedSets}/${_workout!.totalSets}'),
                        Container(width: 1, height: 32, color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
                        _buildStatItem(context, 'Volume', FormatUtils.formatWeight(_workout!.totalVolume, preferredUnit)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Exercise list
            Expanded(
              child: _workout!.exercises.isEmpty
                  ? _buildEmptyState(isDark)
                  : ListView.builder(
                      controller: _scrollController,
                      padding: AppSpacing.paddingLg,
                      itemCount: _workout!.exercises.length,
                      itemBuilder: (context, index) {
                        final workoutExercise = _workout!.exercises[index];
                        return _buildExerciseCard(workoutExercise, index, isDark, preferredUnit);
                      },
                    ),
            ),
            // Add exercise button
            Container(
              padding: AppSpacing.paddingLg,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                border: Border(top: BorderSide(color: isDark ? AppColors.darkDivider : AppColors.lightDivider)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await context.push('/log-exercise/${widget.workoutId}');
                    // Refresh workout when returning from exercise selection
                    _refreshWorkout();
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Exercise'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: isDark ? AppColors.darkHint : AppColors.lightHint)),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fitness_center_rounded,
            size: 80,
            color: isDark ? AppColors.darkHint : AppColors.lightHint,
          ),
          const SizedBox(height: 16),
          Text(
            'No exercises yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap "Add Exercise" to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark ? AppColors.darkHint : AppColors.lightHint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStatus(WorkoutExercise workoutExercise, bool isDark, String preferredUnit) {
    final completedSets = workoutExercise.sets.where((set) => set.isCompleted).toList();
    final totalSets = workoutExercise.sets.length;
    final isComplete = completedSets.length == totalSets && totalSets > 0;
    
    if (isComplete) {
      return Row(
        children: [
          Icon(
            Icons.check_rounded,
            size: 16,
            color: isDark ? AppColors.darkSuccess : AppColors.lightSuccess,
          ),
          const SizedBox(width: 6),
          Text(
            'Completed',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark ? AppColors.darkSuccess : AppColors.lightSuccess,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    } else if (completedSets.isEmpty) {
      return Row(
        children: [
          Icon(
            Icons.radio_button_unchecked,
            size: 16,
            color: isDark ? AppColors.darkHint : AppColors.lightHint,
          ),
          const SizedBox(width: 6),
          Text(
            'Not started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark ? AppColors.darkHint : AppColors.lightHint,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      );
    } else {
      // Show most recent completed set
      final lastSet = completedSets.last;
      final displayWeight = FormatUtils.formatWeight(lastSet.weightKg, preferredUnit);
      
      return Row(
        children: [
          Icon(
            Icons.history,
            size: 16,
            color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
          ),
          const SizedBox(width: 6),
          Text(
            'Last: $displayWeight × ${lastSet.reps}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }
  }

  Widget _buildExerciseCard(WorkoutExercise workoutExercise, int index, bool isDark, String preferredUnit) {
    final completedSets = workoutExercise.completedSets;
    final totalSets = workoutExercise.sets.length;
    final isComplete = completedSets == totalSets && totalSets > 0;
    final hasStarted = completedSets > 0;
    
    // Find if this is the next unfinished exercise
    final nextUnfinishedIndex = _workout!.exercises.indexWhere((ex) {
      final completed = ex.sets.where((set) => set.isCompleted).length;
      final total = ex.sets.length;
      return completed < total;
    });
    final isNextUp = index == nextUnfinishedIndex && !isComplete;

    return GestureDetector(
      key: _exerciseKeys[index],
      onTap: () async {
        await context.push('/log-exercise/${widget.workoutId}?exerciseIndex=$index');
        // Refresh workout when returning from exercise
        _refreshWorkout();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: AppSpacing.paddingMd,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: isComplete
                ? (isDark ? AppColors.darkSuccess : AppColors.lightSuccess)
                : isNextUp
                    ? context.colors.primaryAccent
                    : (isDark ? AppColors.darkDivider : AppColors.lightDivider),
            width: (isComplete || isNextUp) ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isNextUp ? 0.1 : 0.05),
              blurRadius: isNextUp ? 8 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Next up indicator
            if (isNextUp)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: context.colors.primaryAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.flag_rounded,
                      size: 14,
                      color: context.colors.primaryAccent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'NEXT UP',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: context.colors.primaryAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                // Status indicator
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isComplete
                        ? (isDark ? AppColors.darkSuccess : AppColors.lightSuccess)
                        : isNextUp
                            ? context.colors.primaryAccent
                            : hasStarted
                                ? context.colors.primaryAccent.withValues(alpha: 0.2)
                                : (isDark ? AppColors.darkDivider : AppColors.lightDivider),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isComplete
                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                        : Text(
                            '${index + 1}',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isNextUp || hasStarted
                                  ? Colors.white
                                  : (isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workoutExercise.exercise.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.museum_rounded,
                            size: 14,
                            color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            FormatUtils.formatMuscleGroup(workoutExercise.exercise.primaryMuscleGroup.name),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDark ? AppColors.darkHint : AppColors.lightHint,
                  size: 28,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: isDark ? AppColors.darkDivider : AppColors.lightDivider, height: 1),
            const SizedBox(height: 12),
            // Progress summary
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Set progress
                Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      size: 16,
                      color: isComplete
                          ? (isDark ? AppColors.darkSuccess : AppColors.lightSuccess)
                          : hasStarted
                              ? context.colors.primaryAccent
                              : (isDark ? AppColors.darkHint : AppColors.lightHint),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$completedSets/$totalSets sets',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isComplete
                            ? (isDark ? AppColors.darkSuccess : AppColors.lightSuccess)
                            : hasStarted
                                ? context.colors.primaryAccent
                                : (isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Last set or status
                _buildProgressStatus(workoutExercise, isDark, preferredUnit),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
