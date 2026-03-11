# Theme Token System Documentation

## Overview

The **Theme Token System** provides a centralized, semantic approach to styling UI components across the entire app. All visual properties (colors, gradients, spacing, shadows) are defined in a single source of truth, ensuring consistency and making theme changes propagate globally.

---

## Core Concepts

### 1. **Tokens vs. Components**

- **Tokens** = Semantic color/style values (e.g., `cardBackground`, `accentSolid`)
- **Components** = Pre-built UI elements that consume tokens (e.g., `AppCard`, `AppPrimaryButton`)

### 2. **No Hardcoded Colors**

❌ **Never do this:**
```dart
Container(
  color: Color(0xFF1C1C1E),
  border: Border.all(color: Colors.grey),
)
```

✅ **Always do this:**
```dart
final tokens = context.tokens;
Container(
  color: tokens.cardBackground,
  border: Border.all(color: tokens.cardBorder),
)
```

---

## Available Tokens

Access tokens via `context.tokens`:

```dart
final tokens = context.tokens;
```

### Page Tokens
```dart
tokens.pageBackground      // Main scaffold background
```

### Card Tokens
```dart
tokens.cardBackground      // Card background color
tokens.cardBorder         // Card border color
tokens.cardGradient       // Optional gradient (null if theme doesn't support)
```

### Chip Tokens
```dart
tokens.chipBackground           // Unselected chip background
tokens.chipSelectedBackground   // Selected chip background (solid)
tokens.chipSelectedGradient     // Selected chip gradient (optional)
tokens.chipBorder              // Chip border
tokens.chipText                // Unselected chip text
tokens.chipSelectedText        // Selected chip text
```

### Input Tokens
```dart
tokens.inputBackground      // Input field background
tokens.inputBorder         // Input border (enabled)
tokens.inputBorderFocused  // Input border (focused)
tokens.inputText          // Input text color
tokens.inputHint          // Placeholder/hint text
```

### Accent Tokens
```dart
tokens.accentSolid        // Primary accent (solid color)
tokens.accentGradient     // Primary accent gradient (optional)
tokens.buttonGradient     // Button-specific gradient (optional)
tokens.progressGradient   // Progress bar gradient (optional)
```

### Accent Scale (for emphasis levels)
```dart
tokens.accentStrong       // Brightest accent
tokens.accentMedium       // Medium accent
tokens.accentSoft         // Subtle accent
tokens.accentHighlight    // Special highlight
```

### State Tokens
```dart
tokens.success           // Green (success states)
tokens.warning           // Amber/Yellow (warning states)
tokens.danger            // Red (error/danger states)
tokens.info              // Blue (info states)
```

### Text Tokens
```dart
tokens.textPrimary       // High contrast text
tokens.textSecondary     // Medium contrast text
tokens.textMuted         // Low contrast text
tokens.textOnAccent      // Text on accent backgrounds
```

### Additional Tokens
```dart
tokens.icon              // Icon color
tokens.divider           // Divider line color
tokens.borderSubtle      // Very subtle borders
```

---

## Pre-Built Components

All components automatically use tokens. Import from:

```dart
import 'package:total_athlete/theme/components.dart';
```

### Buttons

```dart
// Primary button
AppPrimaryButton(
  label: 'Start Workout',
  icon: Icons.play_arrow,
  onPressed: () {},
)

// Secondary button (outline)
AppSecondaryButton(
  label: 'Cancel',
  onPressed: () {},
)

// Text button
AppTextButton(
  label: 'Learn More',
  onPressed: () {},
)

// Icon button
AppIconButton(
  icon: Icons.close,
  onPressed: () {},
  useAccent: true, // Use accent color
)

// Floating action button
AppFAB(
  icon: Icons.add,
  label: 'New Workout', // Optional
  onPressed: () {},
)
```

### Cards

```dart
AppCard(
  level: CardLevel.standard, // or .subtle, .elevated, .flat, .glass
  child: YourContent(),
)
```

### Chips

```dart
AppFilterChip(
  label: 'Push',
  selected: true,
  onTap: () {},
)

AppFilterChipCompact(
  label: 'Pull',
  selected: false,
  onTap: () {},
)
```

### Inputs

```dart
// Text field
AppTextField(
  label: 'Exercise Name',
  hint: 'Enter name',
  controller: myController,
  onChanged: (value) {},
)

// Number input (for workout logging)
AppNumberInput(
  hint: '0',
  width: 80,
  controller: weightController,
)

// Search field
AppSearchField(
  hint: 'Search exercises',
  controller: searchController,
  onChanged: (query) {},
)
```

### Badges

```dart
// Status badge
AppBadge(
  label: 'Completed',
  variant: BadgeVariant.success,
  icon: Icons.check,
)

// Pill (category tag)
AppPill(
  label: 'Strength',
  selected: true,
  onTap: () {},
)

// Count badge
AppCountBadge(
  count: 5,
)
```

### Modals

```dart
// Show dialog
showDialog(
  context: context,
  builder: (context) => AppModal(
    title: 'Confirm Action',
    content: Text('Are you sure?'),
    actions: [
      AppTextButton(label: 'Cancel', onPressed: () => Navigator.pop(context)),
      AppPrimaryButton(label: 'Confirm', onPressed: () {}),
    ],
  ),
);

// Show bottom sheet
showAppBottomSheet(
  context: context,
  title: 'Select Exercise',
  content: ExerciseList(),
);

// Show confirmation dialog
final confirmed = await showAppConfirmDialog(
  context: context,
  title: 'Delete Workout',
  message: 'This action cannot be undone.',
);
```

---

## Creating Custom Components

When building custom widgets, always use tokens:

```dart
class MyCustomWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    
    return Container(
      decoration: BoxDecoration(
        color: tokens.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: tokens.cardBorder),
        gradient: tokens.cardGradient, // Optional, may be null
      ),
      child: Text(
        'Hello',
        style: TextStyle(color: tokens.textPrimary),
      ),
    );
  }
}
```

---

## Testing Theme Changes

To verify the token system works correctly:

1. **Change Active Theme**
   - Go to Settings → Theme Selector
   - Switch between themes (Titanium, Crimson, Midnight, etc.)

2. **Verify Changes Propagate**
   - All components should update instantly
   - No hardcoded colors should remain
   - Gradients should appear/disappear based on theme

3. **Check All States**
   - Unselected chips
   - Selected chips
   - Focused inputs
   - Completed sets
   - Error states
   - Success states

---

## Benefits

✅ **Single Source of Truth**
- Change one token → all components update

✅ **Semantic Naming**
- `tokens.cardBackground` is clearer than `Color(0xFF1C1C1E)`

✅ **Theme Flexibility**
- Supports themes with/without gradients
- Supports custom color packs
- Supports light/dark modes

✅ **Type Safety**
- Compiler catches missing tokens
- IntelliSense autocomplete

✅ **Maintainability**
- Easy to add new themes
- Easy to adjust global styles
- Reduces code duplication

---

## Migration Guide

If you find any hardcoded colors:

### Before
```dart
Container(
  color: Color(0xFF1C1C1E),
  decoration: BoxDecoration(
    border: Border.all(color: Colors.grey.withOpacity(0.2)),
    gradient: LinearGradient(
      colors: [Color(0xFF6C7A89), Color(0xFF8B95A3)],
    ),
  ),
)
```

### After
```dart
final tokens = context.tokens;
Container(
  color: tokens.cardBackground,
  decoration: BoxDecoration(
    border: Border.all(color: tokens.cardBorder),
    gradient: tokens.cardGradient,
  ),
)
```

---

## FAQ

**Q: What if a token is null?**
A: Gradients are optional. Check for null before using:
```dart
gradient: tokens.cardGradient, // May be null
```

**Q: Can I override a token for one component?**
A: Yes, but only if absolutely necessary:
```dart
AppCard(
  backgroundColor: Colors.red, // Override
  child: ...,
)
```

**Q: How do I add a new token?**
A: 
1. Add to `ThemeTokens` class in `theme_tokens.dart`
2. Add to `ThemeTokensContext` extension mapping
3. Update all theme builders to provide the token

**Q: Do I need to use pre-built components?**
A: No, but recommended. You can use tokens directly in custom widgets.

---

## Summary

The **Theme Token System** ensures:
- ✅ No hardcoded colors anywhere
- ✅ Consistent styling across all components
- ✅ Global theme changes propagate instantly
- ✅ Easy to maintain and extend
- ✅ Type-safe and developer-friendly

Always use `context.tokens` for colors and styles!
