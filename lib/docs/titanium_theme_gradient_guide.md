# Titanium Theme - Premium Gradient Guide

## Overview
The refined Titanium theme now features soft gradients, subtle borders, and premium glow effects for a smoother, more luxurious feel.

## Color Palette

### Titanium Gradient Scale
```dart
// Primary titanium accent gradient:
#C9C7CC → #A8A5AE → #7E7B8B

// Card background gradient:
#1E232D → #171B23 (darker at bottom)

// Button gradient:
#8E8B97 → #7E7B8B (subtle depth)

// Progress bar gradient:
#C9C7CC → #8E8B97 (soft shimmer)
```

## How to Use Gradients

### 1. Card with Gradient Background
```dart
Container(
  decoration: BoxDecoration(
    gradient: context.gradients?.cardGradient,
    borderRadius: BorderRadius.circular(AppRadius.lg),
    border: Border.all(
      color: colors.softBorder, // rgba(255,255,255,0.05)
      width: 1,
    ),
    boxShadow: AppShadows.subtleGlow, // Premium glow effect
  ),
  child: YourCardContent(),
)
```

### 2. Button with Gradient
```dart
Container(
  decoration: BoxDecoration(
    gradient: context.gradients?.buttonGradient,
    borderRadius: BorderRadius.circular(AppRadius.lg),
    boxShadow: AppShadows.cardShadow,
  ),
  child: Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Padding(
        padding: AppSpacing.paddingMd,
        child: Text('Button'),
      ),
    ),
  ),
)
```

### 3. Progress Bar with Gradient
```dart
Container(
  height: 8,
  decoration: BoxDecoration(
    gradient: context.gradients?.progressGradient,
    borderRadius: BorderRadius.circular(AppRadius.full),
    boxShadow: AppShadows.subtleGlow,
  ),
)
```

### 4. Primary Accent Gradient
```dart
// For highlights, badges, or focal points
Container(
  decoration: BoxDecoration(
    gradient: context.gradients?.primaryGradient,
    borderRadius: BorderRadius.circular(AppRadius.md),
  ),
  child: YourContent(),
)
```

## Premium Effects

### Subtle Borders
Use `colors.softBorder` for refined, barely-visible borders:
```dart
border: Border.all(
  color: colors.softBorder, // rgba(255,255,255,0.05)
  width: 1,
)
```

### Subtle Glow Shadow
Add premium depth without harsh shadows:
```dart
boxShadow: AppShadows.subtleGlow
// Creates: 0 4px 20px rgba(120,120,140,0.18)
```

### Card Shadow
Soft elevation for cards:
```dart
boxShadow: AppShadows.cardShadow
```

### Button Pressed State
Reduced shadow for pressed state:
```dart
boxShadow: AppShadows.buttonPressed
```

## Theme Access

### From Context
```dart
final colors = context.colors;
final gradients = context.gradients;

// Use accent scale
colors.accentStrong    // #A8A5AE - Primary accent
colors.accentMedium    // #8E8B97 - Medium emphasis
colors.accentSoft      // #7E7B8B - Subtle backgrounds
colors.accentHighlight // #C9C7CC - Lightest highlight
```

## Design Principles

1. **Soft Gradients Over Flat Colors**
   - Use gradients for depth and dimension
   - Keep transitions smooth and subtle

2. **Minimal Border Contrast**
   - Use `softBorder` (0.05 opacity) instead of solid colors
   - Let gradients define edges naturally

3. **Glow Instead of Hard Shadows**
   - Use `AppShadows.subtleGlow` for premium feel
   - Avoid harsh drop shadows

4. **Layered Surfaces**
   - Card gradient flows from lighter top to darker bottom
   - Creates natural depth hierarchy

5. **Smooth Transitions**
   - All gradients use 2-3 color stops max
   - Linear gradients for simplicity and elegance

## Example: Complete Card Implementation

```dart
Container(
  margin: AppSpacing.paddingMd,
  decoration: BoxDecoration(
    gradient: context.gradients?.cardGradient ?? LinearGradient(
      colors: [colors.card, colors.background],
    ),
    borderRadius: BorderRadius.circular(AppRadius.lg),
    border: Border.all(
      color: colors.softBorder,
      width: 1,
    ),
    boxShadow: AppShadows.subtleGlow,
  ),
  child: Padding(
    padding: AppSpacing.paddingMd,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Title',
          style: context.textStyles.titleLarge?.copyWith(
            color: colors.primaryText,
          ),
        ),
        SizedBox(height: AppSpacing.sm),
        Container(
          height: 4,
          decoration: BoxDecoration(
            gradient: context.gradients?.progressGradient,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
        ),
      ],
    ),
  ),
)
```

## Migration Tips

### Before (Flat Colors)
```dart
decoration: BoxDecoration(
  color: colors.card,
  border: Border.all(color: colors.border),
)
```

### After (Premium Gradients)
```dart
decoration: BoxDecoration(
  gradient: context.gradients?.cardGradient,
  border: Border.all(color: colors.softBorder),
  boxShadow: AppShadows.subtleGlow,
)
```

## Fallback Handling

Always provide fallbacks for themes without gradient support:
```dart
decoration: BoxDecoration(
  gradient: context.gradients?.cardGradient ?? LinearGradient(
    colors: [colors.card, colors.card], // Fallback to solid color
  ),
)
```

Or use color-only fallback:
```dart
decoration: BoxDecoration(
  color: context.gradients == null ? colors.card : null,
  gradient: context.gradients?.cardGradient,
)
```
