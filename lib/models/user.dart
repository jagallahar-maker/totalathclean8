class User {
  final String id;
  final String name;
  final String email;
  final double? currentWeight; // Always stored in kg, converted for display
  final double? goalWeight; // Always stored in kg, converted for display
  final String? avatarInitials;
  final String preferredUnit; // 'kg' or 'lb' - display preference only
  final double smithMachineBarWeightKg; // Smith machine bar weight in kg
  final double smithMachineBarWeightLb; // Smith machine bar weight in lb
  final double? heightCm; // Height in centimeters
  
  // Set mode preferences (for Add Set behavior)
  final double progressiveIncrementKg; // Weight increment for progressive mode in kg (default: 2.5 kg)
  final double progressiveIncrementLb; // Weight increment for progressive mode in lb (default: 5 lb)
  final double backoffPercentage; // Percentage reduction for backoff mode (default: 10%)
  
  // Audio cue preferences
  final bool audioWorkoutStart; // Sound when workout starts
  final bool audioWorkoutComplete; // Sound when workout completes
  final bool audioSetStart; // Sound when starting a set (default off - can be intrusive)
  final bool audioSetComplete; // Sound when completing a set
  final bool audioRestStart; // Sound when rest timer starts (default off)
  final bool audioRestComplete; // Sound when rest timer completes
  
  // Rest timer settings
  final int defaultRestTimerSeconds; // Default rest time in seconds (default: 90)
  final Map<String, int> exerciseRestTimers; // Per-exercise rest timer overrides (exerciseId -> seconds)
  
  // Dashboard customization
  final Map<String, dynamic>? dashboardConfig; // Serialized DashboardConfig
  final Map<String, dynamic>? analyticsDashboardConfig; // Serialized DashboardConfig for analytics screen
  
  // Theme customization
  final Map<String, dynamic>? themeConfig; // Serialized ThemeConfig
  
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.currentWeight,
    this.goalWeight,
    this.avatarInitials,
    this.preferredUnit = 'kg', // Default to kg
    this.smithMachineBarWeightKg = 15.0, // Default smith machine bar weight in kg
    this.smithMachineBarWeightLb = 33.0, // Default smith machine bar weight in lb
    this.heightCm,
    this.progressiveIncrementKg = 2.5, // Default 2.5 kg increment
    this.progressiveIncrementLb = 5.0, // Default 5 lb increment
    this.backoffPercentage = 10.0, // Default 10% backoff
    this.audioWorkoutStart = true, // Default enabled
    this.audioWorkoutComplete = true, // Default enabled
    this.audioSetStart = false, // Default disabled - can be distracting
    this.audioSetComplete = true, // Default enabled
    this.audioRestStart = false, // Default disabled - can be distracting
    this.audioRestComplete = true, // Default enabled
    this.defaultRestTimerSeconds = 90, // Default 90 seconds (1:30)
    this.exerciseRestTimers = const {}, // No per-exercise overrides by default
    this.dashboardConfig,
    this.analyticsDashboardConfig,
    this.themeConfig,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'currentWeight': currentWeight,
    'goalWeight': goalWeight,
    'avatarInitials': avatarInitials,
    'preferredUnit': preferredUnit,
    'smithMachineBarWeightKg': smithMachineBarWeightKg,
    'smithMachineBarWeightLb': smithMachineBarWeightLb,
    'heightCm': heightCm,
    'progressiveIncrementKg': progressiveIncrementKg,
    'progressiveIncrementLb': progressiveIncrementLb,
    'backoffPercentage': backoffPercentage,
    'audioWorkoutStart': audioWorkoutStart,
    'audioWorkoutComplete': audioWorkoutComplete,
    'audioSetStart': audioSetStart,
    'audioSetComplete': audioSetComplete,
    'audioRestStart': audioRestStart,
    'audioRestComplete': audioRestComplete,
    'defaultRestTimerSeconds': defaultRestTimerSeconds,
    'exerciseRestTimers': exerciseRestTimers,
    'dashboardConfig': dashboardConfig,
    'analyticsDashboardConfig': analyticsDashboardConfig,
    'themeConfig': themeConfig,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'] as String,
    name: json['name'] as String,
    email: json['email'] as String,
    currentWeight: json['currentWeight'] as double?,
    goalWeight: json['goalWeight'] as double?,
    avatarInitials: json['avatarInitials'] as String?,
    preferredUnit: json['preferredUnit'] as String? ?? 'kg',
    smithMachineBarWeightKg: json['smithMachineBarWeightKg'] as double? ?? 15.0,
    smithMachineBarWeightLb: json['smithMachineBarWeightLb'] as double? ?? 33.0,
    heightCm: json['heightCm'] as double?,
    progressiveIncrementKg: json['progressiveIncrementKg'] as double? ?? 2.5,
    progressiveIncrementLb: json['progressiveIncrementLb'] as double? ?? 5.0,
    backoffPercentage: json['backoffPercentage'] as double? ?? 10.0,
    audioWorkoutStart: json['audioWorkoutStart'] as bool? ?? true,
    audioWorkoutComplete: json['audioWorkoutComplete'] as bool? ?? true,
    audioSetStart: json['audioSetStart'] as bool? ?? false,
    audioSetComplete: json['audioSetComplete'] as bool? ?? true,
    audioRestStart: json['audioRestStart'] as bool? ?? false,
    audioRestComplete: json['audioRestComplete'] as bool? ?? true,
    defaultRestTimerSeconds: json['defaultRestTimerSeconds'] as int? ?? 90,
    exerciseRestTimers: json['exerciseRestTimers'] != null
        ? Map<String, int>.from(json['exerciseRestTimers'] as Map)
        : {},
    dashboardConfig: json['dashboardConfig'] as Map<String, dynamic>?,
    analyticsDashboardConfig: json['analyticsDashboardConfig'] as Map<String, dynamic>?,
    themeConfig: json['themeConfig'] as Map<String, dynamic>?,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );

  User copyWith({
    String? id,
    String? name,
    String? email,
    double? currentWeight,
    double? goalWeight,
    String? avatarInitials,
    String? preferredUnit,
    double? smithMachineBarWeightKg,
    double? smithMachineBarWeightLb,
    double? heightCm,
    double? progressiveIncrementKg,
    double? progressiveIncrementLb,
    double? backoffPercentage,
    bool? audioWorkoutStart,
    bool? audioWorkoutComplete,
    bool? audioSetStart,
    bool? audioSetComplete,
    bool? audioRestStart,
    bool? audioRestComplete,
    int? defaultRestTimerSeconds,
    Map<String, int>? exerciseRestTimers,
    Map<String, dynamic>? dashboardConfig,
    Map<String, dynamic>? analyticsDashboardConfig,
    Map<String, dynamic>? themeConfig,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => User(
    id: id ?? this.id,
    name: name ?? this.name,
    email: email ?? this.email,
    currentWeight: currentWeight ?? this.currentWeight,
    goalWeight: goalWeight ?? this.goalWeight,
    avatarInitials: avatarInitials ?? this.avatarInitials,
    preferredUnit: preferredUnit ?? this.preferredUnit,
    smithMachineBarWeightKg: smithMachineBarWeightKg ?? this.smithMachineBarWeightKg,
    smithMachineBarWeightLb: smithMachineBarWeightLb ?? this.smithMachineBarWeightLb,
    heightCm: heightCm ?? this.heightCm,
    progressiveIncrementKg: progressiveIncrementKg ?? this.progressiveIncrementKg,
    progressiveIncrementLb: progressiveIncrementLb ?? this.progressiveIncrementLb,
    backoffPercentage: backoffPercentage ?? this.backoffPercentage,
    audioWorkoutStart: audioWorkoutStart ?? this.audioWorkoutStart,
    audioWorkoutComplete: audioWorkoutComplete ?? this.audioWorkoutComplete,
    audioSetStart: audioSetStart ?? this.audioSetStart,
    audioSetComplete: audioSetComplete ?? this.audioSetComplete,
    audioRestStart: audioRestStart ?? this.audioRestStart,
    audioRestComplete: audioRestComplete ?? this.audioRestComplete,
    defaultRestTimerSeconds: defaultRestTimerSeconds ?? this.defaultRestTimerSeconds,
    exerciseRestTimers: exerciseRestTimers ?? this.exerciseRestTimers,
    dashboardConfig: dashboardConfig ?? this.dashboardConfig,
    analyticsDashboardConfig: analyticsDashboardConfig ?? this.analyticsDashboardConfig,
    themeConfig: themeConfig ?? this.themeConfig,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
