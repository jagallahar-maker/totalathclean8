# Theme and Layout Compression Fixes

## PART 1: Theme Fixes - COMPLETED ✓

### Programs Screen (`lib/screens/programs_screen.dart`)
**Changes Made:**
1. ✅ Back arrow: Changed from `AppColors.darkPrimary/lightPrimary` → `context.colors.primaryAccent` (line 40)
2. ✅ Add button (+): Changed from `AppColors.darkPrimary/lightPrimary` → `context.colors.primaryAccent` (line 64)
3. ✅ Hypertrophy pill: Updated `_getGoalColor()` to use `context.colors.primaryAccent` for hypertrophy goal (line 520)
4. ✅ Program type cards: Icons now use `context.colors.primaryAccent` (line 1028)
5. ✅ Routine detail screen:
   - Play icon: `context.colors.primaryAccent` (line 973)
   - Remove icon: `context.colors.error` (semantic red, line 976)
   - Drag handle: `context.colors.secondaryText` (neutral, line 962)

**Status:** All program screen theme elements migrated to theme token system.

---

## PART 2: Workout Screen Compression - TODO

### Required Changes in `lib/screens/log_exercise_screen.dart`:

#### A. Best Set Ever Card (lines 1347-1454)
**Current issues:**
- Uses hardcoded `AppColors.darkPrimary/lightPrimary`
- Too much vertical padding
- Too tall overall

**Required fixes:**
```dart
Container(
  margin: const EdgeInsets.only(bottom: 8),  // was 12
  padding: const EdgeInsets.all(10),  // was AppSpacing.paddingMd (16)
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [
        context.colors.primaryAccent.withValues(alpha: 0.15),  // was AppColors.darkPrimary
        context.colors.card,  // was AppColors.darkSurface
      ],
      ...
    ),
    border: Border.all(
      color: context.colors.primaryAccent.withValues(alpha: 0.3),  // was AppColors.darkPrimary
      width: 1.5,
    ),
  ),
  child: Column(
    children: [
      Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),  // was 6
            ...
            child: Icon(
              Icons.emoji_events_rounded,
              size: 16,  // was 18
              color: context.colors.primaryAccent,  // was AppColors.darkPrimary
            ),
          ),
          const SizedBox(width: 6),  // was 8
          Text(
            'Best Set Ever',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(  // was titleSmall
              fontWeight: FontWeight.bold,
              color: context.colors.primaryAccent,  // was AppColors.darkPrimary
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),  // was 12
      Container(
        padding: const EdgeInsets.all(8),  // was 12
        ...
        child: Row(
          children: [
            Column(
              children: [
                Text(..., style: Theme.of(context).textTheme.labelSmall),  // was bodySmall
                const SizedBox(height: 4),  // was 6
                Text(
                  ...,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(  // was titleLarge
                    color: context.colors.primaryAccent,  // was AppColors.darkPrimary
                  ),
                ),
              ],
            ),
            Container(height: 32, ...),  // was 40
            ...
          ],
        ),
      ),
    ],
  ),
)
```

**Space saved:** ~24-30px vertical height

---

#### B. Next Session Card (lines 1456-1580)
**Current issues:**
- Uses hardcoded accent colors for UI elements
- Should use `context.colors.primaryAccent` for card styling
- Keep semantic green only for increases
- Too much vertical padding

**Required fixes:**
```dart
Container(
  margin: const EdgeInsets.only(bottom: 8),  // was 12
  padding: const EdgeInsets.all(10),  // was AppSpacing.paddingMd (16)
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [
        context.colors.primaryAccent.withValues(alpha: 0.15),  // NOT semantic colors
        context.colors.card,
      ],
      ...
    ),
    border: Border.all(
      color: context.colors.primaryAccent.withValues(alpha: 0.3),  // NOT semantic
      width: 1.5,
    ),
  ),
  child: Column(
    children: [
      Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),  // was 6
            decoration: BoxDecoration(
              color: context.colors.primaryAccent.withValues(alpha: 0.2),  // NOT semantic
              ...
            ),
            child: Icon(
              ...,
              size: 16,  // was 18
              color: context.colors.primaryAccent,  // NOT semantic
            ),
          ),
          const SizedBox(width: 6),  // was 8
          Text(
            'Next Session',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(  // was titleSmall
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),  // was 12
      Container(
        padding: const EdgeInsets.all(8),  // was 12
        ...
        child: Row(
          children: [
            Text('Use', ...),
            Text(
              weight,
              style: TextStyle(
                color: isIncrease 
                  ? context.colors.success  // SEMANTIC green for increase
                  : context.colors.primaryText,  // neutral otherwise
              ),
            ),
            ...
          ],
        ),
      ),
    ],
  ),
)
```

**Key rule:** Card frame = theme accent. Number color when increasing = semantic green.

**Space saved:** ~24-30px vertical height

---

#### C. View Full Progress Button (lines 1308-1342)
**Current issues:**
- Uses hardcoded `AppColors.darkPrimary/lightPrimary`
- Too much vertical padding/margin

**Required fixes:**
```dart
Container(
  margin: const EdgeInsets.only(bottom: 8),  // was 16
  padding: const EdgeInsets.symmetric(vertical: 8),  // was 12
  decoration: BoxDecoration(
    ...
    border: Border.all(
      color: context.colors.primaryAccent.withValues(alpha: 0.3),  // was AppColors.darkPrimary
    ),
  ),
  child: Row(
    children: [
      Text(
        'View Full Progress',
        style: TextStyle(
          color: context.colors.primaryAccent,  // was AppColors.darkPrimary
          fontWeight: FontWeight.bold,
        ),
      ),
      ...
      Icon(
        Icons.arrow_forward_rounded,
        color: context.colors.primaryAccent,  // was AppColors.darkPrimary
      ),
    ],
  ),
)
```

**Space saved:** ~12px vertical height

---

#### D. Header Area Compression (lines 190-270)
**Current spacing:**
- Top padding: 16px
- Timer to stats: 16px
- Stats to mode selector: 16px
- Mode selector bottom: 16px

**Required changes:**
```dart
Column(
  children: [
    // Timer
    const SizedBox(height: 12),  // was 16
    WorkoutTimerDisplay(...),
    const SizedBox(height: 10),  // was 16
    // Stats
    Container(padding: EdgeInsets.all(10), ...),  // was 12
    const SizedBox(height: 10),  // was 16
    // Set mode selector
    Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),  // was (12, 8)
      ...
    ),
    const SizedBox(height: 8),  // was 12
  ],
)
```

**Space saved:** ~20px vertical height

---

#### E. Add Set Button (bottom CTA)
**Required change:**
```dart
ElevatedButton.icon(
  ...
  style: ElevatedButton.styleFrom(
    minimumSize: const Size(double.infinity, 48),  // was 56
    ...
  ),
)
```

**Space saved:** ~8px vertical height

---

**Total space saved in workout screen:** ~88-110px vertical space
**Result:** 1-2 additional set rows visible when keypad is open

---

## PART 3: Keypad Compression - TODO

### Required Changes in `lib/widgets/custom_workout_keypad.dart`:

#### Current dimensions:
- Header padding: 12px vertical, 8px horizontal
- Header height: ~60px
- Key height: 56px
- Gap between keys: 6px
- Total keypad: ~280px

#### Target dimensions:
```dart
// Header
Container(
  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),  // was (12, 8)
  child: Row(
    children: [
      IconButton(
        icon: Icon(Icons.close_rounded, size: 18),  // was 20
        ...
      ),
      ...
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),  // was (16, 8)
        ...
        child: Text(
          ...,
          style: TextTheme.titleMedium,  // was headlineSmall
        ),
      ),
    ],
  ),
)

// Keypad grid
Container(
  padding: const EdgeInsets.all(6),  // was 8
  child: Column(
    children: [
      Row(...),  // 7 8 9
      const SizedBox(height: 4),  // was 6
      Row(...),  // 4 5 6
      const SizedBox(height: 4),  // was 6
      Row(...),  // 1 2 3
      const SizedBox(height: 4),  // was 6
      Row(...),  // backspace 0 next
    ],
  ),
)

// Key buttons
Container(
  height: 48,  // was 56
  ...
  child: icon != null
    ? Icon(icon, size: 22)  // was 24
    : Text(..., style: TextTheme.titleLarge),  // was headlineSmall
)
```

**Space saved:** ~40-50px vertical height
**Total keypad height:** ~230-240px (was ~280px)

---

## Summary

**Total Compression:**
- Workout screen header: ~20px
- Best Set Ever card: ~28px
- Next Session card: ~28px
- View Progress button: ~12px
- Add Set button: ~8px
- Keypad: ~45px

**Grand total:** ~140px more visible workout content when keypad is open

This allows **2-3 additional set rows** to remain visible above the keypad.

---

## Implementation Priority

1. ✅ **DONE:** Programs screen theme migration
2. **TODO:** Workout screen card compression + theme fixes
3. **TODO:** Keypad compression

**Estimated additional set rows visible:** 2-3 rows
