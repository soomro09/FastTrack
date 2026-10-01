class FastingLog {
  final int? id;
  final DateTime startTime;
  final DateTime endTime;
  final int targetDurationHours;
  final bool isCompleted;

  FastingLog({
    this.id,
    required this.startTime,
    required this.endTime,
    required this.targetDurationHours,
    required this.isCompleted,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'targetDurationHours': targetDurationHours,
      'isCompleted': isCompleted ? 1 : 0,
    };
  }

  factory FastingLog.fromMap(Map<String, dynamic> map) {
    return FastingLog(
      id: map['id'],
      startTime: DateTime.parse(map['startTime']),
      endTime: DateTime.parse(map['endTime']),
      targetDurationHours: map['targetDurationHours'],
      isCompleted: map['isCompleted'] == 1,
    );
  }
}
