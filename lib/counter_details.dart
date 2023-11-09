class CounterDetails {
  final int id;
  final String name;
  final String unit;
  final int occurrencesToday;
  final int occurrencesYesterday;
  final int occurrencesThisWeek;
  final int occurrencesThisMonth;
  final int occurrencesThisYear;
  final int occurrencesTotal;

  CounterDetails({required this.id, 
  required this.name, 
  required this.unit, 
  this.occurrencesToday = 0,
  this.occurrencesYesterday = 0,
  this.occurrencesThisWeek = 0,
  this.occurrencesThisMonth = 0,
  this.occurrencesThisYear = 0,
  this.occurrencesTotal = 0,});

  // Factory constructor to create a Counter from a Map
  factory CounterDetails.fromMap(Map<String, dynamic> data) {
    return CounterDetails(
      id: data['counter_id'],
      name: data['name'],
      unit: data['unit'],
      occurrencesToday: data['occurrences_today'] ?? 0, // Default to 0 if occurrences is null
      occurrencesYesterday: data['occurrences_yesterday'] ?? 0, // Default to 0 if occurrences is null
      occurrencesThisWeek: data['occurrences_this_week'] ?? 0, // Default to 0 if occurrences is null
      occurrencesThisMonth: data['occurrences_this_month'] ?? 0, // Default to 0 if occurrences is null
      occurrencesThisYear: data['occurrences_this_year'] ?? 0, // Default to 0 if occurrences is null
      occurrencesTotal: data['occurrences_total'] ?? 0, // Default to 0 if occurrences is null
    );
  }
}