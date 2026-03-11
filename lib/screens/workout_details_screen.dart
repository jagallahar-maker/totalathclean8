import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:total_athlete/providers/app_provider.dart';
import 'package:total_athlete/theme.dart';
import 'package:total_athlete/utils/format_utils.dart';
import 'package:total_athlete/models/workout.dart';
import 'package:total_athlete/models/workout_exercise.dart';
import 'package:total_athlete/widgets/workout_date_picker.dart';
import 'package:total_athlete/utils/load_score_calculator.dart';

class WorkoutDetailsScreen extends StatefulWidget {
  final String workoutId;

  const WorkoutDetailsScreen({super.key, required this.workoutId});

  @override
  State<WorkoutDetailsScreen> createState() => _WorkoutDetailsScreenState();
}

class _WorkoutDetailsScreenState extends State<WorkoutDetailsScreen> {

  Future<void> _showDatePicker(BuildContext context, Workout workout, AppProvider provider) async {
    final colors = context.colors;
    final now = DateTime.now();
    
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: workout.startTime,
      firstDate: DateTime(2020),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: colors.primaryAccent,
              onPrimary: colors.onPrimary,
              surface: colors.card,
              onSurface: colors.primaryText,
            ),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate != null) {
      // Preserve the time from the current workout
      final newDateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        workout.startTime.hour,
        workout.startTime.minute,
        workout.startTime.second,
      );
      
      // Update the workout with the new date
      final updatedWorkout = workout.copyWith(
        startTime: newDateTime,
        endTime: workout.endTime != null
            ? DateTime(
                selectedDate.year,
                selectedDate.month,
                selectedDate.day,
                workout.endTime!.hour,
                workout.endTime!.minute,
                workout.endTime!.second,
              )
            : null,
        updatedAt: DateTime.now(),
      );
      
      await provider.updateWorkout(updatedWorkout);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Workout date updated to ${FormatUtils.formatDate(newDateTime)}'),
            backgroundColor: colors.success,
          ),
        );
      }
    }
  }

  Future<void> _confirmDeleteWorkout(BuildContext context, Workout workout, AppProvider provider) async {
    final colors = context.colors;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: colors.card,
          title: Text(
            'Delete Workout?',
            style: TextStyle(color: colors.primaryText),
          ),
          content: Text(
            'This will permanently remove this workout and all associated sets and statistics.',
            style: TextStyle(color: colors.secondaryText),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel', style: TextStyle(color: colors.secondaryText)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Delete', style: TextStyle(color: colors.error)),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      await provider.deleteWorkout(workout.id);
      
      if (context.mounted) {
        // Navigate back to history after deletion
        context.pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Workout deleted'),
            backgroundColor: colors.success,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final preferredUnit = provider.preferredUnit;
    final userBodyweightKg = provider.getMostRecentBodyweightKg();
    final colors = context.colors;
    
    final workout = provider.workouts.firstWhere(
      (w) => w.id == widget.workoutId,
      orElse: () => throw Exception('Workout not found'),
    );

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.card,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text('Workout Details', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: colors.primaryText),
            color: colors.card,
            onSelected: (value) async {
              if (value == 'delete') {
                await _confirmDeleteWorkout(context, workout, provider);
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_rounded, color: colors.error, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      'Delete Workout',
                      style: TextStyle(color: colors.error),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.paddingLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Workout Header Card
              Container(
                padding: AppSpacing.paddingLg,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colors.primaryAccent, colors.primaryAccent.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  boxShadow: [
                    BoxShadow(
                      color: colors.primaryAccent.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      workout.name,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: colors.onPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        // Editable Date Picker
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: InkWell(
                            onTap: () => _showDatePicker(context, workout, provider),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.calendar_today_rounded,
                                    size: 14,
                                    color: colors.onPrimary.withOpacity(0.9),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    FormatUtils.formatDate(workout.startTime),
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: colors.onPrimary.withOpacity(0.9),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.edit_rounded,
                                    size: 12,
                                    color: colors.onPrimary.withOpacity(0.7),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.access_time_rounded,
                          size: 16,
                          color: colors.onPrimary.withOpacity(0.9),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          FormatUtils.formatDuration(workout.duration),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colors.onPrimary.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Stats Grid
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Volume',
                      value: FormatUtils.formatVolume(workout.totalVolume, preferredUnit),
                      icon: Icons.fitness_center_rounded,
                      colors: colors,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'Sets',
                      value: '${workout.completedSets}',
                      icon: Icons.format_list_numbered_rounded,
                      colors: colors,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Exercises',
                      value: '${workout.exercises.length}',
                      icon: Icons.list_alt_rounded,
                      colors: colors,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'Calories',
                      value: FormatUtils.formatCalories(workout.getCaloriesBurned(userBodyweightKg: userBodyweightKg)),
                      icon: Icons.local_fire_department_rounded,
                      colors: colors,
                      valueColor: colors.success,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Load Score Card (full width)
              _LoadScoreCard(
                workout: workout,
                colors: colors,
              ),

              const SizedBox(height: 24),

              // Exercises List Header
              Text(
                'Exercises',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // Exercises List
              ...workout.exercises.map((workoutExercise) => _ExerciseCard(
                workoutExercise: workoutExercise,
                colors: colors,
                preferredUnit: preferredUnit,
              )),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final AppThemeColors colors;
  final Color? valueColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.colors,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: colors.primaryAccent,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.hint,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final WorkoutExercise workoutExercise;
  final AppThemeColors colors;
  final String preferredUnit;

  const _ExerciseCard({
    required this.workoutExercise,
    required this.colors,
    required this.preferredUnit,
  });

  @override
  Widget build(BuildContext context) {
    final completedSets = workoutExercise.sets.where((s) => s.isCompleted).toList();
    final exerciseVolume = workoutExercise.totalVolume;

    return GestureDetector(
      onTap: () {
        context.push(
          '/exercise-progress/${workoutExercise.exercise.id}?name=${Uri.encodeComponent(workoutExercise.exercise.name)}',
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: AppSpacing.paddingMd,
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: colors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Exercise Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
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
                      Text(
                        '${completedSets.length} sets • ${FormatUtils.formatVolume(exerciseVolume, preferredUnit)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: colors.secondaryText,
                  size: 20,
                ),
              ],
            ),

            if (completedSets.isNotEmpty) ...[
              const SizedBox(height: 12),
              Divider(
                color: colors.divider,
                thickness: 0.5,
              ),
              const SizedBox(height: 8),

              // Sets List
              ...completedSets.asMap().entries.map((entry) {
                final index = entry.key;
                final set = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: colors.primaryAccent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colors.primaryAccent,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Row(
                          children: [
                            Text(
                              FormatUtils.formatWeight(set.weightKg, preferredUnit),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '×',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colors.hint,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${set.reps} reps',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        FormatUtils.formatVolume(set.weightKg * set.reps, preferredUnit),
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: colors.secondaryText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }
}

class _LoadScoreCard extends StatelessWidget {
  final Workout workout;
  final AppThemeColors colors;

  const _LoadScoreCard({
    required this.workout,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final loadScore = workout.loadScore;
    final loadScoreLabel = LoadScoreCalculator.getLoadScoreLabel(loadScore);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loadScoreColorHex = LoadScoreCalculator.getLoadScoreColor(loadScore, isDark);
    final loadScoreColor = Color(int.parse(loadScoreColorHex.replaceFirst('#', '0xFF')));

    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.divider),
      ),
      child: Row(
        children: [
          // Icon and Label
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: loadScoreColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(
                    Icons.trending_up_rounded,
                    size: 22,
                    color: loadScoreColor,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Load Score',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.hint,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      loadScore > 0 ? loadScore.toStringAsFixed(0) : '--',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Difficulty Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: loadScoreColor,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Text(
              loadScoreLabel,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
