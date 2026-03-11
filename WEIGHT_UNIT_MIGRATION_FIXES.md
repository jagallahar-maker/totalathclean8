# Weight Unit System Migration - Fix Summary

## Problem
The `WorkoutSet` model was migrated to store weights only in kilograms (`weightKg`), but 192 errors remain where code still references the old `weight` and `unit` properties.

## Solution Pattern

### 1. Reading/Displaying Weights
**OLD (broken):**
```dart
set.weight  // ❌ Property doesn't exist
set.unit    // ❌ Property doesn't exist
```

**NEW (correct):**
```dart
set.weightKg  // ✅ Weight is always in kg internally
final userUnit = currentUser?.preferredUnit ?? 'kg';
final displayWeight = UnitConversion.kgToDisplayUnit(set.weightKg, userUnit);
```

### 2. Creating WorkoutSets
**OLD (broken):**
```dart
WorkoutSet(
  id: uuid,
  setNumber: 1,
  weight: 100.0,     // ❌ Parameter doesn't exist
  unit: 'kg',        // ❌ Parameter doesn't exist
  reps: 10,
  isCompleted: false,
  createdAt: now,
  updatedAt: now,
)
```

**NEW (correct):**
```dart
// If weight is already in kg (from ProgressiveOverloadService):
WorkoutSet(
  id: uuid,
  setNumber: 1,
  weightKg: 100.0,   // ✅ Direct value in kg
  reps: 10,
  isCompleted: false,
  createdAt: now,
  updatedAt: now,
)

// If weight is from user input in their preferred unit:
WorkoutSet(
  id: uuid,
  setNumber: 1,
  weightKg: UnitConversion.inputToKg(userInputWeight, userUnit), // ✅ Convert to kg
  reps: 10,
  isCompleted: false,
  createdAt: now,
  updatedAt: now,
)
```

### 3. Filtering Sets
**OLD (broken):**
```dart
sets.where((s) => s.isCompleted && s.weight > 0 && s.reps > 0)
```

**NEW (correct):**
```dart
sets.where((s) => s.isCompleted && s.weightKg > 0 && s.reps > 0)
```

### 4. Calculating Volume
**OLD (broken):**
```dart
final volume = set.weight * set.reps;
```

**NEW (correct):**
```dart
final volume = set.weightKg * set.reps;  // Volume is in kg
```

### 5. Formatting for Display
**OLD (broken):**
```dart
FormatUtils.formatWeight(set.weight, preferredUnit, storedUnit: set.unit)
```

**NEW (correct):**
```dart
FormatUtils.formatWeight(set.weightKg, preferredUnit)
```

### 6. Comparing Weights
**OLD (broken):**
```dart
final weightKg = set.unit == 'kg' ? set.weight : set.weight * 0.453592;
```

**NEW (correct):**
```dart
final weightKg = set.weightKg;  // Already in kg, no conversion needed
```

## Files with Errors (by count)

1. **app_provider.dart** - 50+ errors ✅ FIXED
2. **log_exercise_screen.dart** - 30+ errors
3. **exercise_progress_screen.dart** - 17 errors
4. **workout_service.dart** - 28 errors
5. **programs_screen.dart** - 6 errors
6. **start_workout_screen.dart** - 6 errors
7. **progress_analytics_screen.dart** - 2 errors
8. **workout_details_screen.dart** - 3 errors
9. **workout_session_screen.dart** - 2 errors
10. **spreadsheet_import_service.dart** - 3 errors
11. **weight_migration_service.dart** - 3 errors
12. **strength_progress_card.dart** - 2 errors

## Next Steps

1. Import `UnitConversion` utility in all affected files
2. Replace all `set.weight` → `set.weightKg`
3. Replace all `set.unit` → Get from `user.preferredUnit`
4. Fix WorkoutSet constructor calls to use `weightKg:` parameter
5. Update all filters/where clauses to use `weightKg`
6. Remove `storedUnit:` parameter from FormatUtils calls
