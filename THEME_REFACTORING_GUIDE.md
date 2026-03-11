# Theme System Refactoring Guide - Total Athlete

## Overview

The app now has a **centralized theme system** that fully applies selected themes (Light, Dark, or Custom Color Packs) across the entire UI.

---

## What Was Changed

### 1. **Enhanced Color Pack Palettes** (`lib/models/theme_config.dart`)

**Added comprehensive color definitions to each color pack:**
- `border` - for card borders and input outlines
- `icon` - for icon colors
- `success`, `warning`, `error` - for status indicators

**Before:** Color packs only had 7 colors  
**After:** Color packs now have 12 colors for complete UI coverage

---

### 2. **Centralized Theme Extension** (`lib/theme.dart`)

**Created `context.colors` extension** that provides theme-aware colors:

```dart
// New way - works with ALL themes (Light, Dark, Custom)
final colors = context.colors;
Container(
  color: colors.background,
  child: Text('Hello', style: TextStyle(color: colors.primaryText)),
)
```

**Key Features:**
- Automatically detects if using Light, Dark, or Custom theme
- Returns correct colors from the active color pack
- Single source of truth for all colors

**Available Color Properties:**
- `background` - Page background
- `card` / `surface` - Card/panel backgrounds
- `primaryAccent` - Primary brand color (buttons, highlights)
- `secondaryAccent` - Secondary accent
- `primaryText` - Main text color
- `secondaryText` - Subdued text
- `divider` / `border` - Lines and borders
- `icon` - Icon colors
- `success` / `warning` / `error` - Status colors
- `onPrimary` / `onSecondary` / `hint` / `onError` - Convenience getters

---

### 3. **Enhanced Custom Theme Builder** (`lib/theme.dart`)

**Updated `buildCustomTheme()` to set ALL theme properties:**

**Now configures:**
- Scaffold background
- Card colors
- Icon theme
- AppBar theme
- Text themes (with color application)
- Button themes (Elevated, Outlined, Text)
- Input field themes
- Chip theme
- Switch theme
- Dialog theme
- Bottom sheet theme
- Snack bar theme

**Result:** Custom themes now affect buttons, dialogs, inputs, chips, switches, and all UI components

---

### 4. **Updated Key Components**

**Already Refactored:**
- ✅ `lib/widgets/bottom_nav.dart` - Uses `colors.card`, `colors.divider`, `colors.primaryAccent`
- ✅ `lib/screens/dashboard_screen.dart` - Partially updated (background, header text)

**Pattern for refactoring other screens:**

```dart
// OLD WAY (hardcoded, doesn't adapt to custom themes)
final isDark = Theme.of(context).brightness == Brightness.dark;
Container(
  color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
  child: Text(
    'Title',
    style: TextStyle(
      color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
    ),
  ),
)

// NEW WAY (theme-aware, works with all themes)
final colors = context.colors;
Container(
  color: colors.card,
  child: Text(
    'Title',
    style: TextStyle(color: colors.primaryText),
  ),
)
```

---

## Refactoring Checklist for Remaining Screens

### Search and Replace Pattern:

1. **Add colors variable at top of build method:**
   ```dart
   final colors = context.colors;
   ```

2. **Replace hardcoded colors:**
   
   | Old Pattern | New Pattern |
   |------------|-------------|
   | `isDark ? AppColors.darkBackground : AppColors.lightBackground` | `colors.background` |
   | `isDark ? AppColors.darkSurface : AppColors.lightSurface` | `colors.card` |
   | `isDark ? AppColors.darkPrimary : AppColors.lightPrimary` | `colors.primaryAccent` |
   | `isDark ? AppColors.darkSecondary : AppColors.lightSecondary` | `colors.secondaryAccent` |
   | `isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText` | `colors.primaryText` |
   | `isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText` | `colors.secondaryText` |
   | `isDark ? AppColors.darkDivider : AppColors.lightDivider` | `colors.divider` |
   | `isDark ? AppColors.darkSuccess : AppColors.lightSuccess` | `colors.success` |
   | `isDark ? AppColors.darkError : AppColors.lightError` | `colors.error` |
   | `isDark ? AppColors.darkHint : AppColors.lightHint` | `colors.hint` |
   | `isDark ? AppColors.darkOnPrimary : AppColors.lightOnPrimary` | `colors.onPrimary` |
   | `isDark ? AppColors.darkOnSecondary : AppColors.lightOnSecondary` | `colors.onSecondary` |

3. **For widget parameters accepting colors:**
   ```dart
   // Before
   MyWidget(isDark: isDark)
   
   // After (if widget only needs colors, not isDark boolean)
   MyWidget(colors: colors)
   // OR pass individual colors: MyWidget(backgroundColor: colors.card)
   ```

---

## Files That Need Refactoring

**High Priority (User-visible screens):**
- [ ] `lib/screens/dashboard_screen.dart` (partially done - finish remaining references)
- [ ] `lib/screens/workout_session_screen.dart`
- [ ] `lib/screens/start_workout_screen.dart`
- [ ] `lib/screens/log_exercise_screen.dart`
- [ ] `lib/screens/settings_screen.dart`
- [ ] `lib/screens/theme_selector_screen.dart`
- [ ] `lib/screens/workout_history_screen.dart`
- [ ] `lib/screens/workout_details_screen.dart`
- [ ] `lib/screens/progress_analytics_screen.dart`
- [ ] `lib/screens/bodyweight_tracker_screen.dart`

**Medium Priority (Widgets):**
- [ ] `lib/widgets/workout_timer_display.dart`
- [ ] `lib/widgets/muscle_heat_map.dart`
- [ ] `lib/widgets/detailed_muscle_heat_map.dart`
- [ ] `lib/widgets/strength_progress_card.dart`
- [ ] `lib/widgets/load_score_trend_card.dart`
- [ ] `lib/widgets/training_consistency_card.dart`
- [ ] `lib/widgets/daily_volume_chart.dart`
- [ ] `lib/widgets/plate_calculator_modal.dart`
- [ ] `lib/widgets/workout_date_picker.dart`

**Lower Priority (Less visual impact):**
- [ ] `lib/screens/exercise_progress_screen.dart`
- [ ] `lib/screens/muscle_detail_screen.dart`
- [ ] `lib/screens/programs_screen.dart`
- [ ] `lib/screens/customize_dashboard_screen.dart`
- [ ] `lib/screens/spreadsheet_import_screen.dart`

---

## Testing Checklist

After refactoring each screen:

1. **Test Light Mode:**
   - Settings > Appearance > Light
   - Verify all text is readable
   - Check all buttons/icons are visible

2. **Test Dark Mode:**
   - Settings > Appearance > Dark
   - Verify contrast is good
   - Check dividers/borders are visible

3. **Test Each Color Pack:**
   - Settings > Appearance > Custom > [Select Pack]
   - **Graphite Performance** (Green)
   - **Midnight Blue** (Cyan)
   - **Ember** (Red)
   - **Titanium** (Blue)
   - **Solar** (Gold)
   - **Aurora** (Magenta)

4. **Verify:**
   - Background color changes
   - Card/panel colors change
   - Accent colors (buttons, highlights) change
   - Text colors remain readable
   - Icons/dividers are visible
   - Charts use theme colors
   - Dialogs/modals use theme colors

---

## Benefits of New System

**Before (Broken):**
- ❌ Custom themes only changed a few accent colors
- ❌ Most UI stayed in default dark/light theme
- ❌ Scattered hardcoded colors throughout codebase
- ❌ Difficult to add new themes

**After (Fixed):**
- ✅ Custom themes apply to ENTIRE app
- ✅ Single source of truth (`context.colors`)
- ✅ Easy to add new color packs
- ✅ Consistent theming across all components
- ✅ Works with buttons, dialogs, inputs, charts, everything

---

## How Themes Are Applied

### Flow:

1. **User selects theme** in Settings > Appearance
2. **ThemeConfig saved** to `currentUser.themeConfig`
3. **main.dart reads config** and builds appropriate `ThemeData`
4. **All widgets** use `context.colors` to get current theme
5. **Theme changes** → `notifyListeners()` → **UI rebuilds** with new colors

### Architecture:

```
User Selection
    ↓
ThemeConfig (stored in User model)
    ↓
main.dart (builds ThemeData from config)
    ↓
context.colors (provides colors from active theme)
    ↓
All UI Components (use colors)
```

---

## Next Steps

1. **Systematically refactor remaining screens** using the pattern above
2. **Test each color pack** after refactoring each screen
3. **Remove `isDark` parameter** from widgets that only need colors
4. **Document any custom color logic** that needs special handling

---

## Quick Reference

**Import needed:**
```dart
import 'package:total_athlete/theme.dart';
```

**Basic usage:**
```dart
@override
Widget build(BuildContext context) {
  final colors = context.colors; // Get current theme colors
  
  return Container(
    color: colors.background,
    child: Card(
      color: colors.card,
      child: Column(
        children: [
          Text('Title', style: TextStyle(color: colors.primaryText)),
          ElevatedButton(
            // Button automatically uses theme.primaryAccent
            onPressed: () {},
            child: Text('Action'),
          ),
        ],
      ),
    ),
  );
}
```

---

**End of Guide**
