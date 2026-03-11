import 'package:flutter/material.dart';
import 'package:total_athlete/models/workout_set.dart';
import 'package:total_athlete/models/exercise.dart';
import 'package:total_athlete/models/theme_config.dart';
import 'package:total_athlete/theme.dart';
import 'package:total_athlete/theme/theme_tokens.dart';
import 'package:total_athlete/utils/unit_conversion.dart';

class CompactSetRow extends StatelessWidget {
  final int index;
  final WorkoutSet workoutSet;
  final Exercise exercise;
  final Function(WorkoutSet) onUpdate;
  final VoidCallback onDelete;
  final VoidCallback onToggleComplete;
  final VoidCallback onTapWeight;
  final VoidCallback onTapReps;
  final String preferredUnit;
  final bool isEditingWeight;
  final bool isEditingReps;
  final String liveInput;

  const CompactSetRow({
    super.key,
    required this.index,
    required this.workoutSet,
    required this.exercise,
    required this.onUpdate,
    required this.onDelete,
    required this.onToggleComplete,
    required this.onTapWeight,
    required this.onTapReps,
    required this.preferredUnit,
    this.isEditingWeight = false,
    this.isEditingReps = false,
    this.liveInput = '',
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isCompleted = workoutSet.isCompleted;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: tokens.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: isCompleted
              ? tokens.accentSolid
              : tokens.cardBorder,
          width: isCompleted ? 1.5 : 0.5,
        ),
      ),
      child: Row(
        children: [
          // Set Number (smaller)
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isCompleted
                  ? tokens.accentSolid
                  : tokens.cardBackground,
              shape: BoxShape.circle,
              border: Border.all(
                color: isCompleted 
                    ? tokens.accentSolid 
                    : tokens.cardBorder,
                width: isCompleted ? 2 : 0.5,
              ),
            ),
            child: Center(
              child: Text(
                '$index',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isCompleted
                      ? tokens.textOnAccent
                      : tokens.textSecondary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Weight (tappable)
          Expanded(
            flex: 3,
            child: GestureDetector(
              onTap: onTapWeight,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: tokens.inputBackground,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isEditingWeight 
                        ? tokens.inputBorderFocused 
                        : tokens.inputBorder,
                    width: isEditingWeight ? 1.5 : 0.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      preferredUnit.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9,
                        color: tokens.inputHint,
                      ),
                    ),
                    Text(
                      isEditingWeight
                          ? (liveInput.isEmpty ? '0' : liveInput)
                          : UnitConversion.kgToDisplayUnit(workoutSet.weightKg, preferredUnit).round().toString(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isEditingWeight ? tokens.inputBorderFocused : tokens.inputText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // x separator
          Text(
            '×',
            style: TextStyle(
              fontSize: 16,
              color: tokens.textMuted,
            ),
          ),
          const SizedBox(width: 8),
          // Reps (tappable)
          Expanded(
            flex: 3,
            child: GestureDetector(
              onTap: onTapReps,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: tokens.inputBackground,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isEditingReps 
                        ? tokens.inputBorderFocused 
                        : tokens.inputBorder,
                    width: isEditingReps ? 1.5 : 0.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'REPS',
                      style: TextStyle(
                        fontSize: 9,
                        color: tokens.inputHint,
                      ),
                    ),
                    Text(
                      isEditingReps
                          ? (liveInput.isEmpty ? '0' : liveInput)
                          : workoutSet.reps.toString(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isEditingReps ? tokens.inputBorderFocused : tokens.inputText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Actions (smaller)
          IconButton(
            onPressed: onDelete,
            icon: Icon(
              Icons.delete_outline_rounded,
              color: tokens.danger,
              size: 18,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 6),
          IconButton(
            onPressed: onToggleComplete,
            icon: Icon(
              isCompleted ? Icons.check_circle_rounded : Icons.panorama_fish_eye_rounded,
              color: tokens.accentSolid,
              size: 24,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
