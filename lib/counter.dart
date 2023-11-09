class Counter {
  final int id;
  final String name;
  final String unit;
  final int occurrences;

  Counter({required this.id, required this.name, required this.unit, this.occurrences = 0});

  // Factory constructor to create a Counter from a Map
  factory Counter.fromMap(Map<String, dynamic> data) {
    return Counter(
      id: data['counter_id'],
      name: data['name'],
      unit: data['unit'],
      occurrences: data['occurrences'] ?? 0, // Default to 0 if occurrences is null
    );
  }
}