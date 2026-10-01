class WeightLog {
  final int? id;
  final double weight;
  final DateTime date;

  WeightLog({
    this.id,
    required this.weight,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'weight': weight,
      'date': date.toIso8601String(),
    };
  }

  factory WeightLog.fromMap(Map<String, dynamic> map) {
    return WeightLog(
      id: map['id'],
      weight: map['weight'],
      date: DateTime.parse(map['date']),
    );
  }
}
