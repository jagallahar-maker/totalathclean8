import 'package:flutter/material.dart';
import 'package:total_athlete/theme.dart';
import 'package:total_athlete/theme/components.dart';

/// Demo widget showing all token-based components
/// 
/// This demonstrates how changing the active theme updates all components globally
class TokenSystemDemo extends StatelessWidget {
  const TokenSystemDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    
    return Scaffold(
      backgroundColor: tokens.pageBackground,
      appBar: AppBar(
        title: const Text('Theme Token System Demo'),
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.paddingLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Section: Cards
            Text(
              'Cards',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: tokens.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            AppCard(
              child: Text(
                'This card uses tokens.cardBackground and tokens.cardBorder',
                style: TextStyle(color: tokens.textPrimary),
              ),
            ),
            const SizedBox(height: 24),
            
            // Section: Buttons
            Text(
              'Buttons',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: tokens.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            AppPrimaryButton(
              label: 'Primary Button',
              icon: Icons.check,
              onPressed: () {},
            ),
            const SizedBox(height: 12),
            AppSecondaryButton(
              label: 'Secondary Button',
              onPressed: () {},
            ),
            const SizedBox(height: 12),
            AppTextButton(
              label: 'Text Button',
              onPressed: () {},
            ),
            const SizedBox(height: 24),
            
            // Section: Chips
            Text(
              'Chips',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: tokens.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                AppFilterChip(
                  label: 'Selected Chip',
                  selected: true,
                  onTap: () {},
                ),
                AppFilterChip(
                  label: 'Unselected Chip',
                  selected: false,
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Section: Inputs
            Text(
              'Inputs',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: tokens.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            const AppTextField(
              label: 'Text Field',
              hint: 'Enter text',
            ),
            const SizedBox(height: 12),
            const AppSearchField(
              hint: 'Search...',
            ),
            const SizedBox(height: 24),
            
            // Section: Badges
            Text(
              'Badges',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: tokens.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const [
                AppBadge(
                  label: 'Success',
                  variant: BadgeVariant.success,
                  icon: Icons.check,
                ),
                AppBadge(
                  label: 'Warning',
                  variant: BadgeVariant.warning,
                  icon: Icons.warning,
                ),
                AppBadge(
                  label: 'Danger',
                  variant: BadgeVariant.danger,
                  icon: Icons.error,
                ),
                AppCountBadge(count: 5),
              ],
            ),
            const SizedBox(height: 24),
            
            // Section: Token Values
            Text(
              'Token Values (Current Theme)',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: tokens.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TokenRow('Page Background', tokens.pageBackground),
                  _TokenRow('Card Background', tokens.cardBackground),
                  _TokenRow('Accent Solid', tokens.accentSolid),
                  _TokenRow('Success', tokens.success),
                  _TokenRow('Warning', tokens.warning),
                  _TokenRow('Danger', tokens.danger),
                ],
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

class _TokenRow extends StatelessWidget {
  final String label;
  final Color color;
  
  const _TokenRow(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color,
              border: Border.all(color: tokens.borderSubtle),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: tokens.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
