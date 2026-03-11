/// Dashboard widget types that can be customized
enum DashboardWidgetType {
  todayTraining,
  weeklyMuscleStatus,
  loadScoreTrend,
  strengthProgress,
  muscleHeatMap,
  muscleGroupVolume,
  dailyVolume,
  personalRecords,
  trainingConsistency,
  recoveryStatus,
  trainingInsights,
}

/// Configuration for a single dashboard widget
class DashboardWidgetConfig {
  final DashboardWidgetType type;
  final bool isVisible;
  final int order;

  const DashboardWidgetConfig({
    required this.type,
    required this.isVisible,
    required this.order,
  });

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'isVisible': isVisible,
    'order': order,
  };

  factory DashboardWidgetConfig.fromJson(Map<String, dynamic> json) {
    return DashboardWidgetConfig(
      type: DashboardWidgetType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => DashboardWidgetType.todayTraining,
      ),
      isVisible: json['isVisible'] as bool? ?? true,
      order: json['order'] as int? ?? 0,
    );
  }

  DashboardWidgetConfig copyWith({
    DashboardWidgetType? type,
    bool? isVisible,
    int? order,
  }) {
    return DashboardWidgetConfig(
      type: type ?? this.type,
      isVisible: isVisible ?? this.isVisible,
      order: order ?? this.order,
    );
  }

  /// Human-readable widget name
  String get name {
    switch (type) {
      case DashboardWidgetType.todayTraining:
        return 'Today\'s Training Output';
      case DashboardWidgetType.weeklyMuscleStatus:
        return 'Weekly Muscle Status';
      case DashboardWidgetType.loadScoreTrend:
        return 'Load Score Trend';
      case DashboardWidgetType.strengthProgress:
        return 'Strength Progress';
      case DashboardWidgetType.muscleHeatMap:
        return 'Muscle Heat Map';
      case DashboardWidgetType.muscleGroupVolume:
        return 'Muscle Group Volume';
      case DashboardWidgetType.dailyVolume:
        return 'Daily Training Volume';
      case DashboardWidgetType.personalRecords:
        return 'Personal Records';
      case DashboardWidgetType.trainingConsistency:
        return 'Training Consistency';
      case DashboardWidgetType.recoveryStatus:
        return 'Recovery Status';
      case DashboardWidgetType.trainingInsights:
        return 'Training Insights';
    }
  }

  /// Widget description
  String get description {
    switch (type) {
      case DashboardWidgetType.todayTraining:
        return 'Today\'s volume, sets, calories, and muscles trained';
      case DashboardWidgetType.weeklyMuscleStatus:
        return 'Weekly set targets by muscle group';
      case DashboardWidgetType.loadScoreTrend:
        return 'Load score history and intensity trends';
      case DashboardWidgetType.strengthProgress:
        return 'Strength gains for major lifts';
      case DashboardWidgetType.muscleHeatMap:
        return 'Visual muscle activation heat map';
      case DashboardWidgetType.muscleGroupVolume:
        return 'Set distribution by muscle group';
      case DashboardWidgetType.dailyVolume:
        return 'Daily training volume chart';
      case DashboardWidgetType.personalRecords:
        return 'Recent personal records and PRs';
      case DashboardWidgetType.trainingConsistency:
        return 'Workout frequency and consistency';
      case DashboardWidgetType.recoveryStatus:
        return 'Recovery status by muscle group';
      case DashboardWidgetType.trainingInsights:
        return 'AI-generated training recommendations';
    }
  }
}

/// Complete dashboard configuration
class DashboardConfig {
  final List<DashboardWidgetConfig> widgets;

  const DashboardConfig({
    required this.widgets,
  });

  /// Default dashboard configuration with all widgets visible (for main dashboard)
  factory DashboardConfig.defaultConfig() {
    return DashboardConfig(
      widgets: [
        const DashboardWidgetConfig(
          type: DashboardWidgetType.todayTraining,
          isVisible: true,
          order: 0,
        ),
        const DashboardWidgetConfig(
          type: DashboardWidgetType.weeklyMuscleStatus,
          isVisible: true,
          order: 1,
        ),
        // Hidden by default on main dashboard (available on Progress page)
        const DashboardWidgetConfig(
          type: DashboardWidgetType.strengthProgress,
          isVisible: false,
          order: 2,
        ),
        const DashboardWidgetConfig(
          type: DashboardWidgetType.recoveryStatus,
          isVisible: false,
          order: 3,
        ),
        const DashboardWidgetConfig(
          type: DashboardWidgetType.trainingInsights,
          isVisible: false,
          order: 4,
        ),
        const DashboardWidgetConfig(
          type: DashboardWidgetType.loadScoreTrend,
          isVisible: false,
          order: 5,
        ),
        const DashboardWidgetConfig(
          type: DashboardWidgetType.muscleHeatMap,
          isVisible: false,
          order: 6,
        ),
        const DashboardWidgetConfig(
          type: DashboardWidgetType.muscleGroupVolume,
          isVisible: false,
          order: 7,
        ),
        const DashboardWidgetConfig(
          type: DashboardWidgetType.dailyVolume,
          isVisible: false,
          order: 8,
        ),
        const DashboardWidgetConfig(
          type: DashboardWidgetType.personalRecords,
          isVisible: false,
          order: 9,
        ),
        const DashboardWidgetConfig(
          type: DashboardWidgetType.trainingConsistency,
          isVisible: false,
          order: 10,
        ),
      ],
    );
  }

  /// Default analytics dashboard configuration (all analytics widgets visible)
  factory DashboardConfig.defaultAnalyticsConfig() {
    return DashboardConfig(
      widgets: [
        const DashboardWidgetConfig(
          type: DashboardWidgetType.trainingConsistency,
          isVisible: true,
          order: 0,
        ),
        const DashboardWidgetConfig(
          type: DashboardWidgetType.loadScoreTrend,
          isVisible: true,
          order: 1,
        ),
        const DashboardWidgetConfig(
          type: DashboardWidgetType.strengthProgress,
          isVisible: true,
          order: 2,
        ),
        const DashboardWidgetConfig(
          type: DashboardWidgetType.muscleHeatMap,
          isVisible: true,
          order: 3,
        ),
        const DashboardWidgetConfig(
          type: DashboardWidgetType.muscleGroupVolume,
          isVisible: true,
          order: 4,
        ),
        const DashboardWidgetConfig(
          type: DashboardWidgetType.dailyVolume,
          isVisible: true,
          order: 5,
        ),
        const DashboardWidgetConfig(
          type: DashboardWidgetType.personalRecords,
          isVisible: true,
          order: 6,
        ),
        // Not applicable to analytics screen
        const DashboardWidgetConfig(
          type: DashboardWidgetType.todayTraining,
          isVisible: false,
          order: 7,
        ),
        const DashboardWidgetConfig(
          type: DashboardWidgetType.weeklyMuscleStatus,
          isVisible: false,
          order: 8,
        ),
        const DashboardWidgetConfig(
          type: DashboardWidgetType.recoveryStatus,
          isVisible: false,
          order: 9,
        ),
        const DashboardWidgetConfig(
          type: DashboardWidgetType.trainingInsights,
          isVisible: false,
          order: 10,
        ),
      ],
    );
  }

  Map<String, dynamic> toJson() => {
    'widgets': widgets.map((w) => w.toJson()).toList(),
  };

  factory DashboardConfig.fromJson(Map<String, dynamic> json) {
    final widgetsList = json['widgets'] as List?;
    if (widgetsList == null || widgetsList.isEmpty) {
      return DashboardConfig.defaultConfig();
    }

    final widgets = widgetsList
        .map((w) => DashboardWidgetConfig.fromJson(w as Map<String, dynamic>))
        .toList();

    return DashboardConfig(widgets: widgets);
  }

  /// Get visible widgets sorted by order
  List<DashboardWidgetConfig> get visibleWidgets {
    return widgets
        .where((w) => w.isVisible)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }

  /// Update widget visibility
  DashboardConfig toggleWidget(DashboardWidgetType type, bool isVisible) {
    final updatedWidgets = widgets.map((w) {
      if (w.type == type) {
        return w.copyWith(isVisible: isVisible);
      }
      return w;
    }).toList();

    return DashboardConfig(widgets: updatedWidgets);
  }

  /// Reorder widgets (for ReorderableListView with standard index adjustment)
  DashboardConfig reorderWidgets(int oldIndex, int newIndex) {
    final visibleList = visibleWidgets;
    if (oldIndex >= visibleList.length || newIndex >= visibleList.length) {
      return this;
    }

    // Adjust newIndex if moving down (for standard ReorderableListView behavior)
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    // Remove and insert
    final item = visibleList.removeAt(oldIndex);
    visibleList.insert(newIndex, item);

    // Update order values
    final updatedVisible = visibleList.asMap().entries.map((entry) {
      return entry.value.copyWith(order: entry.key);
    }).toList();

    // Merge with hidden widgets
    final hiddenWidgets = widgets.where((w) => !w.isVisible).toList();
    final allWidgets = [...updatedVisible, ...hiddenWidgets];

    return DashboardConfig(widgets: allWidgets);
  }

  /// Swap two widgets directly (for custom drag-and-drop implementation)
  DashboardConfig swapWidgets(int index1, int index2) {
    final visibleList = List<DashboardWidgetConfig>.from(visibleWidgets);
    if (index1 >= visibleList.length || index2 >= visibleList.length) {
      return this;
    }

    // Swap the two items
    final temp = visibleList[index1];
    visibleList[index1] = visibleList[index2];
    visibleList[index2] = temp;

    // Update order values
    final updatedVisible = visibleList.asMap().entries.map((entry) {
      return entry.value.copyWith(order: entry.key);
    }).toList();

    // Merge with hidden widgets
    final hiddenWidgets = widgets.where((w) => !w.isVisible).toList();
    final allWidgets = [...updatedVisible, ...hiddenWidgets];

    return DashboardConfig(widgets: allWidgets);
  }
}
