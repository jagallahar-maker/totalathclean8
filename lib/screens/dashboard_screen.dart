import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:total_athlete/providers/app_provider.dart';
import 'package:total_athlete/theme.dart';
import 'package:total_athlete/theme/app_theme.dart';
import 'package:total_athlete/utils/format_utils.dart';
import 'package:total_athlete/services/data_reset_service.dart';
import 'package:total_athlete/services/crashlytics_service.dart';
import 'package:total_athlete/models/dashboard_config.dart';
import 'package:total_athlete/screens/customize_dashboard_screen.dart';

class DashboardScreen extends StatefulWidget {
const DashboardScreen({super.key});

@override
State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
@override
void initState() {
super.initState();
// Log screen view
CrashlyticsService().logScreen('Dashboard');
}

@override
Widget build(BuildContext context) {
final provider = Provider.of<AppProvider>(context);
final user = provider.currentUser;
final colors = context.colors;
final isDark = Theme.of(context).brightness == Brightness.dark;
final preferredUnit = provider.preferredUnit;

// Today's data
final todayWorkouts = provider.getTodaysWorkouts();
final todayVolume = todayWorkouts.fold<double>(0.0, (sum, w) => sum + w.totalVolume);
final todaySets = todayWorkouts.fold<int>(0, (sum, w) => sum + w.completedSets);
final userBodyweightKg = provider.getMostRecentBodyweightKg();
final todayCalories = todayWorkouts.fold<double>(0.0, (sum, w) => sum + w.getCaloriesBurned(userBodyweightKg: userBodyweightKg));
final musclesTrainedToday = provider.getMusclesTrainedToday();

// Weekly data
final weeklyMuscleGroupSets = provider.getWeeklyMuscleGroupSets();
final lastWorkoutDates = provider.getLastWorkoutByMuscleGroup();

// PRs and trends
final recentPRs = provider.personalRecords.take(3).toList();
final volumeTrend = provider.getVolumeTrend(7);

// Insights
final insights = provider.getTrainingInsights();

// Get dashboard configuration
final dashboardConfig = provider.getDashboardConfig();

// Widget types that should NEVER appear on Home screen (Progress screen only)
const homeExcludedTypes = {
  DashboardWidgetType.strengthProgress,
  DashboardWidgetType.recoveryStatus,
  DashboardWidgetType.trainingInsights,
};

// Filter out widgets that are not applicable to Home screen
final visibleWidgets = dashboardConfig.visibleWidgets
    .where((w) => !homeExcludedTypes.contains(w.type))
    .toList();

return Scaffold(
backgroundColor: colors.background,
body: SafeArea(
child: SingleChildScrollView(
physics: const AlwaysScrollableScrollPhysics(),
padding: AppSpacing.paddingLg,
child: Column(
crossAxisAlignment: CrossAxisAlignment.stretch,
mainAxisSize: MainAxisSize.min,
children: [
// Header
Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
'Training Analytics',
style: Theme.of(context).textTheme.headlineMedium?.copyWith(
fontWeight: FontWeight.w800,
color: colors.primaryAccent,
),
),
const SizedBox(height: 4),
Text(
'Welcome back, ${user?.name.split(' ').first ?? 'Athlete'}',
style: Theme.of(context).textTheme.bodyMedium?.copyWith(
color: colors.secondaryText,
),
),
],
),
),
const SizedBox(width: 8),
Row(
mainAxisSize: MainAxisSize.min,
children: [
// Customize dashboard button
IconButton(
onPressed: () {
Navigator.of(context).push(
MaterialPageRoute(
builder: (context) => const CustomizeDashboardScreen(isAnalyticsDashboard: false),
),
);
},
icon: Icon(
Icons.tune_rounded,
color: colors.icon,
),
padding: EdgeInsets.zero,
constraints: const BoxConstraints(),
iconSize: 24,
),
const SizedBox(width: 8),
// Settings button
IconButton(
onPressed: () => context.push('/settings'),
icon: Icon(
Icons.settings_rounded,
color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
),
padding: EdgeInsets.zero,
constraints: const BoxConstraints(),
iconSize: 24,
),
const SizedBox(width: 8),
// Avatar with reset trigger
GestureDetector(
                onLongPress: () => _showResetDialog(context, provider),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: colors.primaryAccent,
                  child: Text(
                    user?.avatarInitials ?? 'JD',
                    style: TextStyle(
                      color: colors.onPrimary,
fontWeight: FontWeight.bold,
fontSize: 14,
),
),
),
),
],
),
],
),
const SizedBox(height: 24),

// Quick Action Button
GestureDetector(
onTap: () => context.push('/start-workout'),
child: Container(
decoration: BoxDecoration(
color: colors.primaryAccent,
borderRadius: BorderRadius.circular(AppRadius.lg),
boxShadow: [
BoxShadow(
color: colors.primaryAccent.withValues(alpha: 0.3),
blurRadius: 8,
offset: const Offset(0, 4),
),
],
),
padding: AppSpacing.paddingLg,
child: Row(
children: [
Icon(
Icons.play_circle_filled_rounded,
color: colors.onPrimary,
size: 32,
),
const SizedBox(width: 16),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
'Start Workout',
style: Theme.of(context).textTheme.titleMedium?.copyWith(
fontWeight: FontWeight.bold,
color: colors.onPrimary,
),
),
const SizedBox(height: 4),
Text(
'Track your training session',
style: Theme.of(context).textTheme.bodySmall?.copyWith(
color: colors.onPrimary,
),
),
],
),
),
Icon(
Icons.arrow_forward_ios_rounded,
color: colors.onPrimary,
size: 16,
),
],
),
),
),
const SizedBox(height: 12),

const SizedBox(height: 24),

// Dynamic widgets based on user configuration with drag-and-drop reordering
...visibleWidgets.asMap().entries.map((entry) {
final index = entry.key;
final widgetConfig = entry.value;

return Column(
crossAxisAlignment: CrossAxisAlignment.stretch,
children: [
_DraggableDashboardWidget(
key: ValueKey(widgetConfig.type),
index: index,
widgetConfig: widgetConfig,
visibleWidgets: visibleWidgets,
onSwap: (index1, index2) => _swapWidgets(provider, dashboardConfig, index1, index2),
child: _buildDashboardWidget(
widgetConfig.type,
context,
provider,
isDark,
todayVolume: todayVolume,
todaySets: todaySets,
todayCalories: todayCalories,
musclesTrainedToday: musclesTrainedToday,
weeklyMuscleGroupSets: weeklyMuscleGroupSets,
recentPRs: recentPRs,
volumeTrend: volumeTrend,
lastWorkoutDates: lastWorkoutDates,
insights: insights,
),
),
const SizedBox(height: 24),
],
);
}).toList(),
],
),
),
),
);
}

Widget _buildDashboardWidget(
DashboardWidgetType type,
BuildContext context,
AppProvider provider,
bool isDark, {
required double todayVolume,
required int todaySets,
required double todayCalories,
required Set<String> musclesTrainedToday,
required Map<String, int> weeklyMuscleGroupSets,
required List recentPRs,
required List<double> volumeTrend,
required Map<String, DateTime> lastWorkoutDates,
required List<String> insights,
}) {
switch (type) {
case DashboardWidgetType.todayTraining:
return Column(
crossAxisAlignment: CrossAxisAlignment.stretch,
children: [
SectionHeader(title: 'Today\'s Training Output', isDark: isDark),
const SizedBox(height: 12),
TodayTrainingCard(
volume: todayVolume,
sets: todaySets,
calories: todayCalories,
musclesTrainedToday: musclesTrainedToday,
isDark: isDark,
),
],
);

case DashboardWidgetType.weeklyMuscleStatus:
return Column(
crossAxisAlignment: CrossAxisAlignment.stretch,
children: [
SectionHeader(title: 'Weekly Muscle Status', isDark: isDark),
const SizedBox(height: 12),
WeeklyMuscleStatusCard(
muscleGroupSets: weeklyMuscleGroupSets,
isDark: isDark,
),
],
);

// Removed from Home screen (still available on Progress screen):
// - Strength Trend (strengthProgress)
// - Recovery Status (recoveryStatus)
// - Training Insights (trainingInsights)

// All other widget types return empty container (not applicable to Home screen)
default:
return const SizedBox.shrink();
}
}

void _showResetDialog(BuildContext context, AppProvider provider) {
final isDark = Theme.of(context).brightness == Brightness.dark;
final colors = context.colors;

showDialog(
context: context,
builder: (context) => AlertDialog(
backgroundColor: colors.card,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(AppRadius.lg),
),
title: Row(
children: [
Icon(
Icons.warning_rounded,
color: isDark ? AppColors.darkError : AppColors.lightError,
size: 28,
),
const SizedBox(width: 12),
Text(
'Reset All Data?',
style: TextStyle(
color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
fontWeight: FontWeight.bold,
),
),
],
),
content: Column(
mainAxisSize: MainAxisSize.min,
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
'This will permanently delete:',
style: TextStyle(
color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
fontWeight: FontWeight.w600,
),
),
const SizedBox(height: 12),
...[
'All workout history',
'Completed workout sessions',
'Exercise progress data',
'Personal records',
'Bodyweight history',
'Bodyweight goals',
'Draft workouts',
'Dashboard analytics',
].map((item) => Padding(
padding: const EdgeInsets.only(bottom: 8),
child: Row(
children: [
Icon(
Icons.close_rounded,
size: 16,
color: isDark ? AppColors.darkError : AppColors.lightError,
),
const SizedBox(width: 8),
Expanded(
child: Text(
item,
style: TextStyle(
color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
),
),
),
],
),
)),
const SizedBox(height: 16),
Container(
padding: AppSpacing.paddingMd,
decoration: BoxDecoration(
color: (isDark ? AppColors.darkSuccess : AppColors.lightSuccess)
.withValues(alpha: 0.1),
borderRadius: BorderRadius.circular(AppRadius.md),
),
child: Row(
children: [
Icon(
Icons.check_circle_outline_rounded,
size: 18,
color: isDark ? AppColors.darkSuccess : AppColors.lightSuccess,
),
const SizedBox(width: 8),
Expanded(
child: Text(
'Routines and exercises will be kept',
style: TextStyle(
color: isDark ? AppColors.darkSuccess : AppColors.lightSuccess,
fontSize: 13,
fontWeight: FontWeight.w600,
),
),
),
],
),
),
],
),
actions: [
TextButton(
onPressed: () => Navigator.of(context).pop(),
child: Text(
'Cancel',
style: TextStyle(
color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
fontWeight: FontWeight.bold,
),
),
),
TextButton(
onPressed: () async {
Navigator.of(context).pop();
await _performReset(context, provider);
},
child: Text(
'Reset Data',
style: TextStyle(
color: isDark ? AppColors.darkError : AppColors.lightError,
fontWeight: FontWeight.bold,
),
),
),
],
),
);
}

Future<void> _performReset(BuildContext context, AppProvider provider) async {
final isDark = Theme.of(context).brightness == Brightness.dark;
final colors = context.colors;

// Show loading dialog
showDialog(
context: context,
barrierDismissible: false,
builder: (context) => AlertDialog(
backgroundColor: colors.card,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(AppRadius.lg),
),
content: Row(
children: [
CircularProgressIndicator(
valueColor: AlwaysStoppedAnimation(
isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
),
),
const SizedBox(width: 16),
Text(
'Resetting data...',
style: TextStyle(
color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
),
),
],
),
),
);

// Perform reset
final resetService = DataResetService();
final success = await resetService.resetAllUserData();

// Force complete reload of all app data (including user with cleared goals)
await provider.forceReloadAllData();

// Get verification counts
final counts = await resetService.getDataCounts();

// Close loading dialog
if (context.mounted) {
Navigator.of(context).pop();
}

// Show debug verification dialog
if (context.mounted) {
_showDebugDialog(context, isDark, success, counts);
}
}

void _swapWidgets(AppProvider provider, DashboardConfig config, int index1, int index2) {
final updatedConfig = config.swapWidgets(index1, index2);
provider.updateDashboardConfig(updatedConfig);
}

void _showDebugDialog(BuildContext context, bool isDark, bool success, Map<String, int> counts) {
final colors = context.colors;
showDialog(
context: context,
builder: (context) => AlertDialog(
backgroundColor: colors.card,
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(AppRadius.lg),
),
title: Row(
children: [
Icon(
success ? Icons.check_circle_rounded : Icons.error_rounded,
color: success
? (isDark ? AppColors.darkSuccess : AppColors.lightSuccess)
: (isDark ? AppColors.darkError : AppColors.lightError),
size: 28,
),
const SizedBox(width: 12),
Expanded(
child: Text(
success ? 'Reset Complete' : 'Reset Failed',
style: TextStyle(
color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
fontWeight: FontWeight.bold,
),
),
),
],
),
content: Column(
mainAxisSize: MainAxisSize.min,
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
'Data Verification:',
style: TextStyle(
color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
fontWeight: FontWeight.w600,
fontSize: 14,
),
),
const SizedBox(height: 12),
_buildCountRow(context, isDark, 'Workouts', counts['workouts'] ?? -1),
_buildCountRow(context, isDark, 'Bodyweight Logs', counts['bodyweight_logs'] ?? -1),
_buildCountRow(context, isDark, 'Personal Records', counts['personal_records'] ?? -1),
_buildCountRow(context, isDark, 'Draft Workouts', counts['draft_workouts'] ?? -1),
_buildCountRow(context, isDark, 'User Goals', counts['user_goals'] ?? -1),
const SizedBox(height: 16),
Container(
padding: AppSpacing.paddingMd,
decoration: BoxDecoration(
color: success
? (isDark ? AppColors.darkSuccess : AppColors.lightSuccess).withValues(alpha: 0.1)
: (isDark ? AppColors.darkError : AppColors.lightError).withValues(alpha: 0.1),
borderRadius: BorderRadius.circular(AppRadius.md),
),
child: Row(
children: [
Icon(
success ? Icons.info_outline_rounded : Icons.warning_rounded,
size: 18,
color: success
? (isDark ? AppColors.darkSuccess : AppColors.lightSuccess)
: (isDark ? AppColors.darkError : AppColors.lightError),
),
const SizedBox(width: 8),
Expanded(
child: Text(
success
? 'All counts should be zero'
: 'Reset failed - data may still exist',
style: TextStyle(
color: success
? (isDark ? AppColors.darkSuccess : AppColors.lightSuccess)
: (isDark ? AppColors.darkError : AppColors.lightError),
fontSize: 13,
fontWeight: FontWeight.w600,
),
),
),
],
),
),
],
),
actions: [
TextButton(
onPressed: () => Navigator.of(context).pop(),
child: Text(
'Close',
style: TextStyle(
color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
fontWeight: FontWeight.bold,
),
),
),
],
),
);
}

Widget _buildCountRow(BuildContext context, bool isDark, String label, int count) {
final isZero = count == 0;
final hasError = count < 0;

return Padding(
padding: const EdgeInsets.only(bottom: 8),
child: Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
Text(
label,
style: TextStyle(
color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
fontSize: 13,
),
),
Row(
children: [
Text(
hasError ? 'Error' : count.toString(),
style: TextStyle(
color: hasError
? (isDark ? AppColors.darkError : AppColors.lightError)
: isZero
? (isDark ? AppColors.darkSuccess : AppColors.lightSuccess)
: (isDark ? AppColors.darkError : AppColors.lightError),
fontWeight: FontWeight.bold,
fontSize: 13,
),
),
const SizedBox(width: 8),
Icon(
hasError
? Icons.error_outline_rounded
: isZero
? Icons.check_circle_outline_rounded
: Icons.warning_rounded,
size: 16,
color: hasError
? (isDark ? AppColors.darkError : AppColors.lightError)
: isZero
? (isDark ? AppColors.darkSuccess : AppColors.lightSuccess)
: (isDark ? AppColors.darkError : AppColors.lightError),
),
],
),
],
),
);
}
}

class SectionHeader extends StatelessWidget {
final String title;
final bool isDark;

const SectionHeader({super.key, required this.title, required this.isDark});

@override
Widget build(BuildContext context) {
return Text(
title,
style: Theme.of(context).textTheme.titleMedium?.copyWith(
fontWeight: FontWeight.bold,
color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
),
);
}
}

class TodayTrainingCard extends StatelessWidget {
final double volume;
final int sets;
final double calories;
final Set<String> musclesTrainedToday;
final bool isDark;

const TodayTrainingCard({
super.key,
required this.volume,
required this.sets,
required this.calories,
required this.musclesTrainedToday,
required this.isDark,
});

@override
Widget build(BuildContext context) {
final preferredUnit = Provider.of<AppProvider>(context).preferredUnit;
final colors = context.colors;
return AppCard(
level: CardLevel.glass,
padding: AppSpacing.paddingLg,
child: Column(
crossAxisAlignment: CrossAxisAlignment.stretch,
children: [
Row(
children: [
Expanded(
child: MetricTile(
icon: Icons.assessment_rounded,
color: colors.primaryAccent,
label: 'Volume',
value: FormatUtils.formatVolume(volume, preferredUnit),
isDark: isDark,
),
),
const SizedBox(width: 12),
Expanded(
child: MetricTile(
icon: Icons.fitness_center_rounded,
color: colors.accentMedium,
label: 'Sets',
value: sets.toString(),
isDark: isDark,
),
),
],
),
const SizedBox(height: 12),
Row(
children: [
Expanded(
child: MetricTile(
icon: Icons.local_fire_department_rounded,
color: colors.error,
label: 'Calories',
value: FormatUtils.formatCalories(calories),
isDark: isDark,
),
),
const SizedBox(width: 12),
Expanded(
child: MetricTile(
icon: Icons.list_rounded,
color: colors.accentStrong,
label: 'Muscles',
value: musclesTrainedToday.length.toString(),
isDark: isDark,
),
),
],
),
if (musclesTrainedToday.isNotEmpty) ...[
const SizedBox(height: 16),
Wrap(
spacing: 8,
runSpacing: 8,
children: musclesTrainedToday
.map((muscle) => Chip(
label: Text(
muscle,
style: Theme.of(context).textTheme.labelSmall,
),
backgroundColor: colors.primaryAccent.withValues(alpha: 0.1),
side: BorderSide.none,
padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
))
.toList(),
),
],
],
),
);
}
}

class MetricTile extends StatelessWidget {
final IconData icon;
final Color color;
final String label;
final String value;
final bool isDark;

const MetricTile({
super.key,
required this.icon,
required this.color,
required this.label,
required this.value,
required this.isDark,
});

@override
Widget build(BuildContext context) {
return Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Row(
children: [
Icon(icon, color: color, size: 16),
const SizedBox(width: 6),
Text(
label,
style: Theme.of(context).textTheme.labelMedium?.copyWith(
color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
),
),
],
),
const SizedBox(height: 8),
Text(
value,
style: Theme.of(context).textTheme.titleLarge?.copyWith(
fontWeight: FontWeight.bold,
),
),
],
);
}
}

class WeeklyMuscleStatusCard extends StatelessWidget {
final Map<String, int> muscleGroupSets;
final bool isDark;

const WeeklyMuscleStatusCard({
super.key,
required this.muscleGroupSets,
required this.isDark,
});

@override
Widget build(BuildContext context) {
final colors = context.colors;

// Define target weekly volume for each muscle group
final targets = {
'Chest': 16,
'Back': 16,
'Legs': 20,
'Shoulders': 12,
'Arms': 14,
};

final muscleColors = {
'Chest': colors.primaryAccent,
'Back': colors.accentMedium,
'Legs': colors.accentStrong,
'Shoulders': colors.accentSoft,
'Arms': colors.accentHighlight,
};

return Container(
decoration: BoxDecoration(
color: colors.card,
borderRadius: BorderRadius.circular(AppRadius.lg),
border: Border.all(color: colors.divider),
),
padding: AppSpacing.paddingLg,
child: Column(
crossAxisAlignment: CrossAxisAlignment.stretch,
children: targets.entries.map((entry) {
final muscle = entry.key;
final target = entry.value;
final sets = muscleGroupSets[muscle] ?? 0;
final color = muscleColors[muscle] ?? colors.primaryAccent;

return Padding(
padding: const EdgeInsets.only(bottom: 16),
child: MuscleProgressBar(
muscle: muscle,
sets: sets,
target: target,
color: color,
isDark: isDark,
),
);
}).toList(),
),
);
}
}

class MuscleProgressBar extends StatelessWidget {
final String muscle;
final int sets;
final int target;
final Color color;
final bool isDark;

const MuscleProgressBar({
super.key,
required this.muscle,
required this.sets,
required this.target,
required this.color,
required this.isDark,
});

@override
Widget build(BuildContext context) {
final colors = context.colors;
final percent = (sets / target).clamp(0.0, 1.0);
final isComplete = sets >= target;

return Column(
crossAxisAlignment: CrossAxisAlignment.stretch,
children: [
Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
Text(
muscle,
style: Theme.of(context).textTheme.bodyMedium?.copyWith(
fontWeight: FontWeight.w600,
),
),
Row(
children: [
Text(
'$sets/$target',
style: Theme.of(context).textTheme.bodySmall?.copyWith(
color: isComplete ? colors.primaryAccent : colors.secondaryText,
fontWeight: FontWeight.bold,
),
),
const SizedBox(width: 4),
Text(
'sets',
style: Theme.of(context).textTheme.bodySmall?.copyWith(
color: colors.secondaryText,
),
),
],
),
],
),
const SizedBox(height: 8),
Container(
height: 10,
decoration: BoxDecoration(
color: colors.divider,
borderRadius: BorderRadius.circular(AppRadius.full),
),
child: ClipRRect(
borderRadius: BorderRadius.circular(AppRadius.full),
child: Align(
alignment: Alignment.centerLeft,
child: FractionallySizedBox(
widthFactor: percent,
child: Container(
height: 10,
decoration: BoxDecoration(
color: color,
borderRadius: BorderRadius.circular(AppRadius.full),
),
),
),
),
),
),
],
);
}
}

class StrengthTrendCard extends StatelessWidget {
final List recentPRs;
final List<double> volumeTrend;
final bool isDark;
final VoidCallback onViewAll;

const StrengthTrendCard({
super.key,
required this.recentPRs,
required this.volumeTrend,
required this.isDark,
required this.onViewAll,
});

@override
Widget build(BuildContext context) {
final preferredUnit = Provider.of<AppProvider>(context).preferredUnit;
final colors = context.colors;
return Container(
decoration: BoxDecoration(
color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
borderRadius: BorderRadius.circular(AppRadius.lg),
border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
),
padding: AppSpacing.paddingLg,
child: Column(
crossAxisAlignment: CrossAxisAlignment.stretch,
children: [
// Volume trend chart
Text(
'Volume Trend (Last 7 Workouts)',
style: Theme.of(context).textTheme.bodyMedium?.copyWith(
fontWeight: FontWeight.w600,
),
),
const SizedBox(height: 16),
SizedBox(
height: 120,
child: volumeTrend.length >= 2
? VolumeTrendChart(volumeData: volumeTrend, isDark: isDark)
: Center(
child: Text(
'Complete more workouts to see trends',
style: Theme.of(context).textTheme.bodySmall?.copyWith(
color: isDark ? AppColors.darkHint : AppColors.lightHint,
),
),
),
),
const SizedBox(height: 24),

// Recent PRs
Row(
mainAxisAlignment: MainAxisAlignment.spaceBetween,
children: [
Text(
'Recent Personal Records',
style: Theme.of(context).textTheme.bodyMedium?.copyWith(
fontWeight: FontWeight.w600,
),
),
GestureDetector(
onTap: onViewAll,
child: Text(
'View All',
style: Theme.of(context).textTheme.labelMedium?.copyWith(
color: colors.primaryAccent,
fontWeight: FontWeight.bold,
),
),
),
],
),
const SizedBox(height: 12),
if (recentPRs.isEmpty)
Padding(
padding: const EdgeInsets.symmetric(vertical: 16),
child: Center(
child: Text(
'No personal records yet',
style: Theme.of(context).textTheme.bodySmall?.copyWith(
color: isDark ? AppColors.darkHint : AppColors.lightHint,
),
),
),
)
else
...recentPRs.map((pr) => PRListItem(
exerciseName: pr.exerciseName,
weight: '${pr.weight.toStringAsFixed(pr.weight % 1 == 0 ? 0 : 1)} ${pr.unit}',
reps: pr.reps,
oneRM: FormatUtils.formatWeight(pr.estimatedOneRepMax, preferredUnit, storedUnit: 'kg'),
date: FormatUtils.formatDate(pr.achievedDate),
isDark: isDark,
)),
],
),
);
}
}

class VolumeTrendChart extends StatelessWidget {
final List<double> volumeData;
final bool isDark;

const VolumeTrendChart({
super.key,
required this.volumeData,
required this.isDark,
});

@override
Widget build(BuildContext context) {
final colors = context.colors;
final spots = volumeData
.asMap()
.entries
.map((e) => FlSpot(e.key.toDouble(), e.value / 1000))
.toList();

return LineChart(
LineChartData(
gridData: const FlGridData(show: false),
titlesData: const FlTitlesData(show: false),
borderData: FlBorderData(show: false),
lineBarsData: [
LineChartBarData(
spots: spots,
isCurved: true,
color: colors.accentStrong,
barWidth: 3,
dotData: FlDotData(
show: true,
getDotPainter: (spot, percent, barData, index) {
return FlDotCirclePainter(
radius: 4,
color: colors.accentStrong,
strokeWidth: 2,
strokeColor: colors.card,
);
},
),
belowBarData: BarAreaData(
show: true,
color: colors.accentStrong.withValues(alpha: 0.1),
),
),
],
),
);
}
}

class PRListItem extends StatelessWidget {
final String exerciseName;
final String weight;
final int reps;
final String oneRM;
final String date;
final bool isDark;

const PRListItem({
super.key,
required this.exerciseName,
required this.weight,
required this.reps,
required this.oneRM,
required this.date,
required this.isDark,
});

@override
Widget build(BuildContext context) {
final colors = context.colors;
return Container(
margin: const EdgeInsets.only(bottom: 8),
padding: AppSpacing.paddingMd,
decoration: BoxDecoration(
color: colors.background,
borderRadius: BorderRadius.circular(AppRadius.md),
),
child: Row(
children: [
Container(
width: 44,
height: 44,
decoration: BoxDecoration(
color: colors.primaryAccent.withValues(alpha: 0.15),
borderRadius: BorderRadius.circular(AppRadius.md),
),
child: Icon(
Icons.emoji_events_rounded,
color: colors.primaryAccent,
size: 22,
),
),
const SizedBox(width: 12),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
exerciseName,
style: Theme.of(context).textTheme.bodyMedium?.copyWith(
fontWeight: FontWeight.bold,
),
maxLines: 1,
overflow: TextOverflow.ellipsis,
),
const SizedBox(height: 2),
Text(
date,
style: Theme.of(context).textTheme.bodySmall?.copyWith(
color: colors.secondaryText,
),
),
],
),
),
Column(
crossAxisAlignment: CrossAxisAlignment.end,
children: [
Text(
'$weight × $reps',
style: Theme.of(context).textTheme.bodyLarge?.copyWith(
fontWeight: FontWeight.bold,
color: colors.accentStrong,
),
),
Text(
'1RM: $oneRM',
style: Theme.of(context).textTheme.labelSmall?.copyWith(
color: colors.secondaryText,
),
),
],
),
],
),
);
}
}

class RecoveryIndicatorCard extends StatelessWidget {
final Map<String, DateTime> lastWorkoutDates;
final bool isDark;

const RecoveryIndicatorCard({
super.key,
required this.lastWorkoutDates,
required this.isDark,
});

String _getRecoveryStatus(int daysSinceLastWorkout) {
if (daysSinceLastWorkout == 0) return 'Worked Today';
if (daysSinceLastWorkout == 1) return 'Recovering';
if (daysSinceLastWorkout <= 2) return 'Recovered';
if (daysSinceLastWorkout <= 4) return 'Well Rested';
return 'Deloaded';
}

Color _getRecoveryColor(int daysSinceLastWorkout, bool isDark) {
if (daysSinceLastWorkout == 0) return isDark ? AppColors.darkError : AppColors.lightError;
if (daysSinceLastWorkout <= 2) return isDark ? AppColors.darkSecondary : AppColors.lightSecondary;
if (daysSinceLastWorkout <= 4) return isDark ? AppColors.darkSuccess : AppColors.lightSuccess;
return isDark ? AppColors.darkHint : AppColors.lightHint;
}

@override
Widget build(BuildContext context) {
final muscles = ['Chest', 'Back', 'Legs', 'Shoulders', 'Arms'];

return Container(
decoration: BoxDecoration(
color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
borderRadius: BorderRadius.circular(AppRadius.lg),
border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
),
padding: AppSpacing.paddingLg,
child: Column(
crossAxisAlignment: CrossAxisAlignment.stretch,
children: muscles.map((muscle) {
final lastWorkout = lastWorkoutDates[muscle];
final daysSince = lastWorkout != null
? DateTime.now().difference(lastWorkout).inDays
: 999;
final status = _getRecoveryStatus(daysSince);
final color = _getRecoveryColor(daysSince, isDark);

return Padding(
padding: const EdgeInsets.only(bottom: 12),
child: Row(
children: [
Expanded(
flex: 2,
child: Text(
muscle,
style: Theme.of(context).textTheme.bodyMedium?.copyWith(
fontWeight: FontWeight.w600,
),
),
),
Expanded(
flex: 3,
child: Row(
children: [
Container(
width: 8,
height: 8,
decoration: BoxDecoration(
color: color,
shape: BoxShape.circle,
),
),
const SizedBox(width: 8),
Expanded(
child: Text(
status,
style: Theme.of(context).textTheme.bodySmall?.copyWith(
color: color,
fontWeight: FontWeight.w600,
),
),
),
],
),
),
Text(
lastWorkout != null
? (daysSince == 0 ? 'Today' : '$daysSince days ago')
: 'Not trained',
style: Theme.of(context).textTheme.bodySmall?.copyWith(
color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
),
),
],
),
);
}).toList(),
),
);
}
}

class TrainingInsightsCard extends StatelessWidget {
final List<String> insights;
final bool isDark;

const TrainingInsightsCard({
super.key,
required this.insights,
required this.isDark,
});

@override
Widget build(BuildContext context) {
  final colors = context.colors;
  return Container(
    decoration: BoxDecoration(
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      border: Border.all(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
    ),
    padding: AppSpacing.paddingLg,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: insights.asMap().entries.map((entry) {
        final index = entry.key;
        final insight = entry.value;
        
        return Padding(
          padding: EdgeInsets.only(bottom: index < insights.length - 1 ? 16 : 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: colors.primaryAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  Icons.lightbulb_outline_rounded,
                  color: colors.primaryAccent,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  insight,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    ),
  );
}
}

class _DraggableDashboardWidget extends StatefulWidget {
final int index;
final DashboardWidgetConfig widgetConfig;
final List<DashboardWidgetConfig> visibleWidgets;
final Function(int index1, int index2) onSwap;
final Widget child;

const _DraggableDashboardWidget({
super.key,
required this.index,
required this.widgetConfig,
required this.visibleWidgets,
required this.onSwap,
required this.child,
});

@override
State<_DraggableDashboardWidget> createState() => _DraggableDashboardWidgetState();
}

class _DraggableDashboardWidgetState extends State<_DraggableDashboardWidget> {
bool _isDragging = false;
int? _lastSwappedIndex;
int? _lastSwapDirection; // Track direction of last swap: 1 = down, -1 = up
final GlobalKey _widgetKey = GlobalKey();

// Hysteresis thresholds to prevent jitter at boundaries
static const double _swapThresholdDown = 0.6; // Must cross 60% when dragging down
static const double _swapThresholdUp = 0.4; // Must cross 40% when dragging up

@override
Widget build(BuildContext context) {
return DragTarget<_DragData>(
onWillAcceptWithDetails: (details) {
final dragData = details.data;
final draggedIndex = dragData.index;

// Don't process if dragging over itself
if (draggedIndex == widget.index) {
return false;
}

// Get the render box to calculate position within this target
final renderBox = _widgetKey.currentContext?.findRenderObject() as RenderBox?;
if (renderBox == null) return true;

final targetHeight = renderBox.size.height;
final localOffset = renderBox.globalToLocal(details.offset);
final relativePosition = localOffset.dy / targetHeight; // 0.0 to 1.0

// Calculate if we've crossed the hysteresis threshold
bool shouldSwap = false;
int swapDirection = 0;

if (draggedIndex < widget.index) {
// Dragging down: Use higher threshold (60%) to prevent immediate reverse
shouldSwap = relativePosition > _swapThresholdDown;
swapDirection = 1; // down
} else {
// Dragging up: Use lower threshold (40%) to prevent immediate reverse
shouldSwap = relativePosition < _swapThresholdUp;
swapDirection = -1; // up
}

// Prevent swap if:
// 1. Already swapped with this exact target index
// 2. Would immediately reverse the last swap (same target, opposite direction)
final wouldReverseLastSwap = (_lastSwappedIndex == draggedIndex &&
_lastSwapDirection != null &&
_lastSwapDirection == -swapDirection);

if (shouldSwap && _lastSwappedIndex != draggedIndex && !wouldReverseLastSwap) {
// Execute the swap
_lastSwappedIndex = draggedIndex;
_lastSwapDirection = swapDirection;
widget.onSwap(draggedIndex, widget.index);
HapticFeedback.selectionClick();
}

return true;
},
onLeave: (data) {
// DO NOT reset swap tracking on leave - this causes jitter when widgets shift
// Only reset on drag end to maintain stable state during reordering
},
onAcceptWithDetails: (details) {
// Reset all swap tracking when drag completes successfully
setState(() {
_lastSwappedIndex = null;
_lastSwapDirection = null;
});
},
builder: (context, candidateData, rejectedData) {
return Container(
key: _widgetKey,
child: LongPressDraggable<_DragData>(
data: _DragData(
index: widget.index,
),
delay: const Duration(milliseconds: 400),
onDragStarted: () {
setState(() {
_isDragging = true;
_lastSwappedIndex = null;
_lastSwapDirection = null;
});
HapticFeedback.mediumImpact();
},
onDragEnd: (details) {
setState(() {
_isDragging = false;
_lastSwappedIndex = null;
_lastSwapDirection = null;
});
},
feedback: Transform.scale(
scale: 1.05,
child: Opacity(
opacity: 0.85,
child: Material(
elevation: 8,
borderRadius: BorderRadius.circular(AppRadius.lg),
child: Container(
width: MediaQuery.of(context).size.width - 32,
child: widget.child,
),
),
),
),
childWhenDragging: Opacity(
opacity: 0.3,
child: widget.child,
),
child: AnimatedScale(
scale: _isDragging ? 0.98 : 1.0,
duration: const Duration(milliseconds: 200),
child: widget.child,
),
),
);
},
);
}
}

/// Data passed during drag to identify which widget is being dragged
class _DragData {
final int index;

_DragData({required this.index});
}

