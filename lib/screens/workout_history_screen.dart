import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:total_athlete/providers/app_provider.dart';
import 'package:total_athlete/theme.dart';
import 'package:total_athlete/theme/app_chips.dart';
import 'package:total_athlete/utils/format_utils.dart';
import 'package:total_athlete/models/workout.dart';
import 'package:total_athlete/utils/load_score_calculator.dart';
import 'package:total_athlete/services/crashlytics_service.dart';

class WorkoutHistoryScreen extends StatefulWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  State<WorkoutHistoryScreen> createState() => _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState extends State<WorkoutHistoryScreen> {
  DateTimeRange? _customDateRange;

  @override
  void initState() {
    super.initState();
    // Log screen view
    CrashlyticsService().logScreen('WorkoutHistory');
  }

  Future<void> _showDateRangePicker() async {
    final now = DateTime.now();
    final firstDate = DateTime(2020, 1, 1);
    final lastDate = now;
    
    final picked = await showDateRangePicker(
      context: context,
      firstDate: firstDate,
      lastDate: lastDate,
      initialDateRange: _customDateRange ?? DateTimeRange(
        start: now.subtract(const Duration(days: 7)),
        end: now,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: context.colors.primaryAccent,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _customDateRange = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final preferredUnit = provider.preferredUnit;
    final userBodyweightKg = provider.getMostRecentBodyweightKg();
    // Only show completed workouts with at least one completed set
    final completedWorkouts = provider.workouts
        .where((w) => w.isCompleted && w.completedSets > 0)
        .toList()
      ..sort((a, b) => b.startTime.compareTo(a.startTime));
    
    // Filter by custom date range if set
    final filteredWorkouts = _customDateRange != null
        ? completedWorkouts.where((w) => 
            w.startTime.isAfter(_customDateRange!.start.subtract(const Duration(days: 1))) && 
            w.startTime.isBefore(_customDateRange!.end.add(const Duration(days: 1)))
          ).toList()
        : completedWorkouts;
    
    final recentWorkouts = (_customDateRange != null ? filteredWorkouts : completedWorkouts.take(7)).toList();

    return Scaffold(
      backgroundColor: context.colors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.paddingLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Workout History', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(
                        _customDateRange != null 
                            ? '${FormatUtils.formatDate(_customDateRange!.start)} - ${FormatUtils.formatDate(_customDateRange!.end)}'
                            : 'Track your consistency', 
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.colors.secondaryText),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: _showDateRangePicker,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _customDateRange != null 
                            ? context.colors.primaryAccent.withOpacity(0.15)
                            : context.colors.card,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: _customDateRange != null 
                              ? context.colors.primaryAccent 
                              : context.colors.border,
                        ),
                      ),
                      child: Icon(
                        Icons.calendar_month_rounded, 
                        color: context.colors.primaryAccent, 
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: context.colors.card,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: Border.all(color: context.colors.border),
                ),
                padding: AppSpacing.paddingLg,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Volume Trend', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                        Text(
                          _customDateRange != null 
                              ? 'Custom Range' 
                              : 'Last 7 Days', 
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: context.colors.secondaryText),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(height: 160, child: VolumeBarChart(workouts: recentWorkouts.reversed.toList())),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    AppFilterChip(label: 'All Workouts', selected: true, onTap: () {}),
                    const SizedBox(width: 8),
                    AppFilterChip(label: 'Push', selected: false, onTap: () {}),
                    const SizedBox(width: 8),
                    AppFilterChip(label: 'Pull', selected: false, onTap: () {}),
                    const SizedBox(width: 8),
                    AppFilterChip(label: 'Legs', selected: false, onTap: () {}),
                    const SizedBox(width: 8),
                    AppFilterChip(label: 'Upper Body', selected: false, onTap: () {}),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ...filteredWorkouts.take(10).map((workout) => WorkoutCard(workout: workout)),
              TextButton(
                onPressed: () {},
                child: Text('Load Older Workouts', style: TextStyle(color: context.colors.secondaryText)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/start-workout'),
        icon: const Icon(Icons.add),
        label: const Text('New Workout'),
      ),
    );
  }
}



class WorkoutCard extends StatelessWidget {
  final Workout workout;

  const WorkoutCard({super.key, required this.workout});

  Future<void> _confirmDelete(BuildContext context, Workout workout) async {
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
      final provider = Provider.of<AppProvider>(context, listen: false);
      await provider.deleteWorkout(workout.id);
      
      if (context.mounted) {
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = Provider.of<AppProvider>(context);
    final preferredUnit = provider.preferredUnit;
    final userBodyweightKg = provider.getMostRecentBodyweightKg();
    final colors = context.colors;
    
    return Dismissible(
      key: Key(workout.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        await _confirmDelete(context, workout);
        return false; // Always return false to prevent auto-dismiss (we handle it manually)
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: colors.error,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        alignment: Alignment.centerRight,
        child: const Icon(
          Icons.delete_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
      child: GestureDetector(
        onTap: () => context.push('/workout-details/${workout.id}'),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: AppSpacing.paddingLg,
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: colors.border),
            boxShadow: AppShadows.cardShadow,
          ),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(workout.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(FormatUtils.formatDate(workout.startTime), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.secondaryText)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: context.colors.primaryAccent, borderRadius: BorderRadius.circular(AppRadius.full)),
                  child: Text(FormatUtils.formatVolume(workout.totalVolume, preferredUnit), style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: colors.divider, thickness: 0.5),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Exercises', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: colors.secondaryText)),
                            Text('${workout.exercises.length}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Sets', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: colors.secondaryText)),
                            Text('${workout.completedSets}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Load Score', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: colors.secondaryText)),
                            Text(
                              workout.loadScore > 0 ? workout.loadScore.toStringAsFixed(0) : '--',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Color(int.parse(LoadScoreCalculator.getLoadScoreColor(workout.loadScore, isDark).replaceFirst('#', '0xFF'))),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: colors.secondaryText, size: 20),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: workout.exercises.take(4).map((e) => ExerciseMiniTag(name: e.exercise.name)).toList(),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

class ExerciseMiniTag extends StatelessWidget {
  final String name;

  const ExerciseMiniTag({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: colors.background, borderRadius: BorderRadius.circular(AppRadius.sm)),
      child: Text(name, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: colors.secondaryText)),
    );
  }
}

class VolumeBarChart extends StatelessWidget {
  final List<Workout> workouts;

  const VolumeBarChart({super.key, required this.workouts});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = context.colors;
    final barGroups = <BarChartGroupData>[];
    
    for (int i = 0; i < 7; i++) {
      final volume = i < workouts.length ? workouts[i].totalVolume / 1000 : 0.0;
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [BarChartRodData(toY: volume, color: colors.primaryAccent, width: 16, borderRadius: const BorderRadius.vertical(top: Radius.circular(4)))],
        ),
      );
    }

    return BarChart(
      BarChartData(
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                return Text(labels[value.toInt()], style: Theme.of(context).textTheme.labelSmall);
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: barGroups,
      ),
    );
  }
}
