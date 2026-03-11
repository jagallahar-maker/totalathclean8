import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:total_athlete/providers/app_provider.dart';
import 'package:total_athlete/models/theme_config.dart';
import 'package:total_athlete/theme.dart';

class ThemeSelectorScreen extends StatelessWidget {
  const ThemeSelectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final currentConfig = provider.themeConfig;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Appearance',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Appearance Mode Section
          Text(
            'APPEARANCE MODE',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          _buildAppearanceModeCard(
            context,
            provider,
            currentConfig,
          ),

          const SizedBox(height: 32),

          // Color Packs Section (only show if Custom is selected)
          if (currentConfig.appearanceMode == AppearanceMode.custom) ...[
            Text(
              'COLOR PACKS',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            _buildColorPacksGrid(context, provider, currentConfig),
          ],
        ],
      ),
    );
  }

  Widget _buildAppearanceModeCard(
    BuildContext context,
    AppProvider provider,
    ThemeConfig currentConfig,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor,
        ),
      ),
      child: Column(
        children: [
          _buildModeOption(
            context,
            provider,
            currentConfig,
            AppearanceMode.system,
            Icons.brightness_auto,
            'System',
            'Match system settings',
          ),
          const SizedBox(height: 12),
          _buildModeOption(
            context,
            provider,
            currentConfig,
            AppearanceMode.light,
            Icons.wb_sunny,
            'Light',
            'Always use light mode',
          ),
          const SizedBox(height: 12),
          _buildModeOption(
            context,
            provider,
            currentConfig,
            AppearanceMode.dark,
            Icons.nights_stay,
            'Dark',
            'Always use dark mode',
          ),
          const SizedBox(height: 12),
          _buildModeOption(
            context,
            provider,
            currentConfig,
            AppearanceMode.custom,
            Icons.palette,
            'Custom',
            'Choose a color pack',
          ),
        ],
      ),
    );
  }

  Widget _buildModeOption(
    BuildContext context,
    AppProvider provider,
    ThemeConfig currentConfig,
    AppearanceMode mode,
    IconData icon,
    String title,
    String subtitle,
  ) {
    final isSelected = currentConfig.appearanceMode == mode;
    final accentColor = Theme.of(context).colorScheme.primary;

    return InkWell(
      onTap: () {
        provider.updateThemeConfig(
          currentConfig.copyWith(appearanceMode: mode),
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? accentColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? accentColor : Theme.of(context).colorScheme.onSurface,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected ? accentColor : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: accentColor,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorPacksGrid(
    BuildContext context,
    AppProvider provider,
    ThemeConfig currentConfig,
  ) {
    final allPalettes = ColorPacks.getAllPalettes();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: allPalettes.length,
      itemBuilder: (context, index) {
        final palette = allPalettes[index];
        final colorPack = ColorPack.values[index];
        final isSelected = currentConfig.colorPack == colorPack;

        return _buildColorPackCard(
          context,
          provider,
          currentConfig,
          palette,
          colorPack,
          isSelected,
        );
      },
    );
  }

  Widget _buildColorPackCard(
    BuildContext context,
    AppProvider provider,
    ThemeConfig currentConfig,
    ColorPackPalette palette,
    ColorPack colorPack,
    bool isSelected,
  ) {
    return InkWell(
      onTap: () {
        provider.updateThemeConfig(
          currentConfig.copyWith(
            appearanceMode: AppearanceMode.custom,
            colorPack: colorPack,
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? palette.primaryAccent : palette.divider,
            width: isSelected ? 3 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Color preview section
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      palette.background,
                      palette.card,
                      palette.primaryAccent.withOpacity(0.2),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(11),
                    topRight: Radius.circular(11),
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: palette.primaryAccent,
                      boxShadow: [
                        BoxShadow(
                          color: palette.primaryAccent.withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Name and description
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          palette.name,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: palette.primaryText,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle,
                          color: palette.primaryAccent,
                          size: 18,
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    palette.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: palette.secondaryText,
                      fontSize: 11,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
