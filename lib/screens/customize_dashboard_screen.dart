import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:total_athlete/models/dashboard_config.dart';
import 'package:total_athlete/providers/app_provider.dart';
import 'package:total_athlete/theme.dart';

class CustomizeDashboardScreen extends StatefulWidget {
  final bool isAnalyticsDashboard;

  const CustomizeDashboardScreen({
    super.key,
    this.isAnalyticsDashboard = false,
  });

  @override
  State<CustomizeDashboardScreen> createState() => _CustomizeDashboardScreenState();
}

class _CustomizeDashboardScreenState extends State<CustomizeDashboardScreen> {
  late DashboardConfig _config;
  bool _hasChanges = false;
  int? _draggingIndex;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<AppProvider>(context, listen: false);
    _config = widget.isAnalyticsDashboard
        ? provider.getAnalyticsDashboardConfig()
        : provider.getDashboardConfig();
  }

  void _toggleWidget(DashboardWidgetType type, bool isVisible) {
    setState(() {
      _config = _config.toggleWidget(type, isVisible);
      _hasChanges = true;
    });
  }

  void _reorderWidgets(int oldIndex, int newIndex) {
    setState(() {
      _config = _config.reorderWidgets(oldIndex, newIndex);
      _hasChanges = true;
      _draggingIndex = null;
    });
  }

  Future<void> _saveChanges() async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    if (widget.isAnalyticsDashboard) {
      await provider.updateAnalyticsDashboardConfig(_config);
    } else {
      await provider.updateDashboardConfig(_config);
    }
    setState(() {
      _hasChanges = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Dashboard layout saved'),
          backgroundColor: context.colors.success,
        ),
      );
    }
  }

  Future<void> _resetToDefault() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = context.colors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: Text(
          'Reset to Default?',
          style: TextStyle(
            color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'This will restore all widgets to their default visibility and order.',
          style: TextStyle(
            color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Reset',
              style: TextStyle(
                color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _config = widget.isAnalyticsDashboard 
            ? DashboardConfig.defaultAnalyticsConfig()
            : DashboardConfig.defaultConfig();
        _hasChanges = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = context.colors;

    return WillPopScope(
      onWillPop: () async {
        if (_hasChanges) {
          final shouldSave = await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              backgroundColor: colors.card,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              title: Text(
                'Save Changes?',
                style: TextStyle(
                  color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Text(
                'You have unsaved changes. Would you like to save them?',
                style: TextStyle(
                  color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    'Discard',
                    style: TextStyle(
                      color: isDark ? AppColors.darkError : AppColors.lightError,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(
                    'Save',
                    style: TextStyle(
                      color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );

          if (shouldSave == true) {
            await _saveChanges();
          }
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: context.colors.background,
        appBar: AppBar(
          backgroundColor: context.colors.card,
          elevation: 0,
          title: Text(
            widget.isAnalyticsDashboard
                ? 'Customize Analytics'
                : 'Customize Dashboard',
            style: TextStyle(
              color: context.colors.primaryText,
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_rounded,
              color: context.colors.primaryText,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            if (_hasChanges)
              TextButton(
                onPressed: _saveChanges,
                child: Text(
                  'Save',
                  style: TextStyle(
                    color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Instructions
              Container(
                padding: AppSpacing.paddingLg,
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Toggle widgets on/off or long-press drag handle to reorder',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _resetToDefault,
                      icon: Icon(
                        Icons.refresh_rounded,
                        size: 18,
                      ),
                      label: Text('Reset to Default'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                        side: BorderSide(
                          color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(
                height: 1,
                color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
              ),

              // Widget list with drag-and-drop
              Expanded(
                child: ListView(
                  padding: AppSpacing.paddingLg,
                  children: [
                    // Visible widgets (draggable)
                    ..._buildDraggableWidgets(isDark),
                    
                    // Hidden widgets section
                    if (_config.widgets.any((w) => !w.isVisible)) ...[
                      const SizedBox(height: 24),
                      Divider(color: isDark ? AppColors.darkDivider : AppColors.lightDivider),
                      const SizedBox(height: 16),
                      Text(
                        'Hidden Widgets',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._config.widgets.where((w) => !w.isVisible).map((widget) {
                        return _WidgetConfigTile(
                          key: ValueKey(widget.type),
                          config: widget,
                          onToggle: (isVisible) => _toggleWidget(widget.type, isVisible),
                          isDark: isDark,
                          isHidden: true,
                        );
                      }).toList(),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDraggableWidgets(bool isDark) {
    final visibleWidgets = _config.visibleWidgets;
    final widgets = <Widget>[];

    for (int i = 0; i < visibleWidgets.length; i++) {
      final widget = visibleWidgets[i];
      
      // Add drag target before each item (for dropping above)
      widgets.add(_DragTargetIndicator(
        index: i,
        onAccept: (draggedIndex) {
          if (draggedIndex != i) {
            _reorderWidgets(draggedIndex, i);
          }
        },
        isDragging: _draggingIndex != null,
        isDark: isDark,
      ));

      // Add draggable widget
      widgets.add(_DraggableWidgetTile(
        key: ValueKey(widget.type),
        config: widget,
        index: i,
        onToggle: (isVisible) => _toggleWidget(widget.type, isVisible),
        onDragStarted: () {
          setState(() {
            _draggingIndex = i;
          });
        },
        onDragEnd: () {
          setState(() {
            _draggingIndex = null;
          });
        },
        isDark: isDark,
      ));
    }

    // Add final drag target (for dropping at the end)
    widgets.add(_DragTargetIndicator(
      index: visibleWidgets.length,
      onAccept: (draggedIndex) {
        if (draggedIndex != visibleWidgets.length) {
          _reorderWidgets(draggedIndex, visibleWidgets.length);
        }
      },
      isDragging: _draggingIndex != null,
      isDark: isDark,
    ));

    return widgets;
  }
}

/// Drag target indicator that shows where items can be dropped
class _DragTargetIndicator extends StatelessWidget {
  final int index;
  final Function(int) onAccept;
  final bool isDragging;
  final bool isDark;

  const _DragTargetIndicator({
    required this.index,
    required this.onAccept,
    required this.isDragging,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<int>(
      onWillAccept: (data) => data != null && data != index,
      onAccept: onAccept,
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: isHovering ? 40 : (isDragging ? 4 : 0),
          margin: EdgeInsets.symmetric(
            horizontal: isHovering ? 16 : 0,
            vertical: isHovering ? 8 : 0,
          ),
          decoration: BoxDecoration(
            color: isHovering 
                ? (isDark ? AppColors.darkPrimary : AppColors.lightPrimary).withOpacity(0.3)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: isHovering
                ? Border.all(
                    color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                    width: 2,
                  )
                : null,
          ),
          child: isHovering
              ? Center(
                  child: Icon(
                    Icons.arrow_downward_rounded,
                    color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                    size: 20,
                  ),
                )
              : null,
        );
      },
    );
  }
}

/// Draggable widget tile with ONLY drag handle as interactive drag target
class _DraggableWidgetTile extends StatelessWidget {
  final DashboardWidgetConfig config;
  final int index;
  final Function(bool) onToggle;
  final VoidCallback onDragStarted;
  final VoidCallback onDragEnd;
  final bool isDark;

  const _DraggableWidgetTile({
    super.key,
    required this.config,
    required this.index,
    required this.onToggle,
    required this.onDragStarted,
    required this.onDragEnd,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    // Build the complete tile for feedback
    Widget buildFeedbackTile() {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                Icons.drag_indicator_rounded,
                color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      config.name,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      config.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Switch(
                value: config.isVisible,
                onChanged: null, // Disabled in feedback
                activeColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // ONLY the drag handle is draggable
            LongPressDraggable<int>(
              data: index,
              onDragStarted: onDragStarted,
              onDragEnd: (_) => onDragEnd(),
              feedback: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: Opacity(
                  opacity: 0.9,
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width - 32,
                    child: buildFeedbackTile(),
                  ),
                ),
              ),
              childWhenDragging: Icon(
                Icons.drag_indicator_rounded,
                color: (isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText)
                    .withOpacity(0.3),
              ),
              child: Icon(
                Icons.drag_indicator_rounded,
                color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
              ),
            ),
            const SizedBox(width: 16),
            
            // Title and description - NOT draggable, isolated from pointer events
            Expanded(
              child: IgnorePointer(
                ignoring: false, // Allow text selection if needed
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      config.name,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      config.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            
            // Toggle switch - completely isolated from drag behavior
            Switch(
              value: config.isVisible,
              onChanged: onToggle,
              activeColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
            ),
          ],
        ),
      ),
    );
  }
}

class _WidgetConfigTile extends StatelessWidget {
  final DashboardWidgetConfig config;
  final Function(bool) onToggle;
  final bool isDark;
  final bool isHidden;
  final bool isDragging;

  const _WidgetConfigTile({
    super.key,
    required this.config,
    required this.onToggle,
    required this.isDark,
    this.isHidden = false,
    this.isDragging = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
        ),
        boxShadow: isDragging
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: isHidden
            ? Icon(
                Icons.visibility_off_rounded,
                color: isDark ? AppColors.darkHint : AppColors.lightHint,
              )
            : Icon(
                Icons.drag_indicator_rounded,
                color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
              ),
        title: Text(
          config.name,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: isHidden
                ? (isDark ? AppColors.darkHint : AppColors.lightHint)
                : (isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText),
          ),
        ),
        subtitle: Text(
          config.description,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
          ),
        ),
        trailing: Switch(
          value: config.isVisible,
          onChanged: onToggle,
          activeColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
        ),
      ),
    );
  }
}
