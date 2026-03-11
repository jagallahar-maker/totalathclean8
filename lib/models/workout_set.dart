class WorkoutSet {
  final String id;
  final int setNumber;
  final double weightKg; // ALWAYS stored in kilograms
  final int reps;
  final bool isCompleted;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  WorkoutSet({
    required this.id,
    required this.setNumber,
    required this.weightKg,
    required this.reps,
    this.isCompleted = false,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  // Only count volume if set is completed and has valid weight/reps > 0
  // Volume is always in kg
  double get volume {
    if (!isCompleted || weightKg <= 0 || reps <= 0) return 0;
    return weightKg * reps;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'setNumber': setNumber,
    'weightKg': weightKg,
    'reps': reps,
    'isCompleted': isCompleted,
    'completedAt': completedAt?.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory WorkoutSet.fromJson(Map<String, dynamic> json) {
    // Migration logic: handle old 'weight' + 'unit' format
    double weightInKg;
    if (json.containsKey('weightKg')) {
      // New format - weight already in kg
      weightInKg = (json['weightKg'] as num).toDouble();
    } else if (json.containsKey('weight')) {
      // Old format - convert to kg if needed
      final weight = (json['weight'] as num).toDouble();
      final unit = json['unit'] as String? ?? 'kg';
      weightInKg = unit == 'lb' ? weight * 0.453592 : weight;
    } else {
      weightInKg = 0.0;
    }

    return WorkoutSet(
      id: json['id'] as String,
      setNumber: json['setNumber'] as int,
      weightKg: weightInKg,
      reps: json['reps'] as int,
      isCompleted: json['isCompleted'] as bool? ?? false,
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt'] as String) : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  WorkoutSet copyWith({
    String? id,
    int? setNumber,
    double? weightKg,
    int? reps,
    bool? isCompleted,
    DateTime? completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => WorkoutSet(
    id: id ?? this.id,
    setNumber: setNumber ?? this.setNumber,
    weightKg: weightKg ?? this.weightKg,
    reps: reps ?? this.reps,
    isCompleted: isCompleted ?? this.isCompleted,
    completedAt: completedAt ?? this.completedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
