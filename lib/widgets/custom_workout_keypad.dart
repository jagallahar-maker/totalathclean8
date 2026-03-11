import 'package:flutter/material.dart';
import 'package:total_athlete/theme.dart';
import 'package:total_athlete/models/theme_config.dart';

class CustomWorkoutKeypad extends StatelessWidget {
  final int setIndex;
  final bool isKeypadForWeight;
  final String keypadInput;
  final String preferredUnit;
  final VoidCallback onClose;
  final Function(String) onInput;
  final VoidCallback onNext;

  const CustomWorkoutKeypad({
    super.key,
    required this.setIndex,
    required this.isKeypadForWeight,
    required this.keypadInput,
    required this.preferredUnit,
    required this.onClose,
    required this.onInput,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = context.colors;

    return Container(
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: onClose,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Set ${setIndex + 1}',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          isKeypadForWeight ? 'Enter weight (${preferredUnit.toUpperCase()})' : 'Enter reps',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Display input value
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: colors.primaryAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      keypadInput.isEmpty ? '0' : keypadInput,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.primaryAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Keypad
            Container(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  // Row 1: 7 8 9
                  Row(
                    children: [
                      _buildKeypadButton(context, '7', isDark, colors),
                      _buildKeypadButton(context, '8', isDark, colors),
                      _buildKeypadButton(context, '9', isDark, colors),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Row 2: 4 5 6
                  Row(
                    children: [
                      _buildKeypadButton(context, '4', isDark, colors),
                      _buildKeypadButton(context, '5', isDark, colors),
                      _buildKeypadButton(context, '6', isDark, colors),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Row 3: 1 2 3
                  Row(
                    children: [
                      _buildKeypadButton(context, '1', isDark, colors),
                      _buildKeypadButton(context, '2', isDark, colors),
                      _buildKeypadButton(context, '3', isDark, colors),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Row 4: Backspace 0 Next
                  Row(
                    children: [
                      _buildKeypadButton(context, 'backspace', isDark, colors, icon: Icons.backspace_outlined),
                      _buildKeypadButton(context, '0', isDark, colors),
                      _buildKeypadButton(context, 'next', isDark, colors, 
                        icon: isKeypadForWeight ? Icons.arrow_forward_rounded : Icons.check_rounded,
                        isPrimary: true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypadButton(BuildContext context, String value, bool isDark, AppThemeColors colors, {IconData? icon, bool isPrimary = false}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Material(
          color: isPrimary
              ? colors.primaryAccent
              : (isDark ? AppColors.darkBackground : AppColors.lightBackground),
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: InkWell(
            onTap: () {
              if (value == 'next') {
                onNext();
              } else {
                onInput(value);
              }
            },
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Container(
              height: 56,
              alignment: Alignment.center,
              child: icon != null
                  ? Icon(
                      icon,
                      color: isPrimary ? Colors.white : (isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText),
                      size: 24,
                    )
                  : Text(
                      value,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isPrimary ? Colors.white : (isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
