import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:total_athlete/theme.dart';

class BottomNavScaffold extends StatelessWidget {
final Widget child;

const BottomNavScaffold({super.key, required this.child});

@override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: Builder(
        builder: (context) {
          final colors = context.colors;
          final currentLocation = GoRouterState.of(context).uri.toString();
          
          return Container(
            decoration: BoxDecoration(
              color: colors.card,
              border: Border(top: BorderSide(color: colors.divider, width: 1)),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _NavItem(
                      icon: Icons.home_rounded,
                      label: 'Home',
                      isSelected: currentLocation == '/',
                      onTap: () => context.go('/'),
                    ),
                    _NavItem(
                      icon: Icons.history_rounded,
                      label: 'History',
                      isSelected: currentLocation == '/history',
                      onTap: () => context.go('/history'),
                    ),
                    _NavItem(
                      icon: Icons.analytics_rounded,
                      label: 'Progress',
                      isSelected: currentLocation == '/progress',
                      onTap: () => context.go('/progress'),
                    ),
                    _NavItem(
                      icon: Icons.scale_rounded,
                      label: 'Weight',
                      isSelected: currentLocation == '/bodyweight',
                      onTap: () => context.go('/bodyweight'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
}
}

class _NavItem extends StatelessWidget {
final IconData icon;
final String label;
final bool isSelected;
final VoidCallback onTap;

const _NavItem({required this.icon, required this.label, required this.isSelected, required this.onTap});

@override
Widget build(BuildContext context) {
final colors = context.colors;
final color = isSelected ? colors.primaryAccent : colors.secondaryText;

return GestureDetector(
onTap: onTap,
behavior: HitTestBehavior.opaque,
child: Container(
padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
Icon(icon, color: color, size: 24),
const SizedBox(height: 4),
Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
],
),
),
);
}
}
