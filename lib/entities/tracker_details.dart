import '../repositories/tracker_repository.dart';

class TrackerDetails {
  final int id;
  final String name;
  final String unit;
  final TrackerType type;
  final int occurrencesToday;
  final int occurrencesYesterday;
  final int occurrencesThisWeek;
  final int occurrencesThisMonth;
  final int occurrencesThisYear;
  final int occurrencesTotal;

  TrackerDetails({required this.id, 
  required this.name, 
  required this.unit, 
  required this.type,
  this.occurrencesToday = 0,
  this.occurrencesYesterday = 0,
  this.occurrencesThisWeek = 0,
  this.occurrencesThisMonth = 0,
  this.occurrencesThisYear = 0,
  this.occurrencesTotal = 0,});

  // Factory constructor to create a Tracker from a Map
  factory TrackerDetails.fromMap(Map<String, dynamic> data) {
    return TrackerDetails(
      id: data['tracker_id'],
      name: data['name'],
      unit: data['unit'],
      type: data['type'].toString().trackerType,
      occurrencesToday: data['occurrences_today'] ?? 0, // Default to 0 if occurrences is null
      occurrencesYesterday: data['occurrences_yesterday'] ?? 0, // Default to 0 if occurrences is null
      occurrencesThisWeek: data['occurrences_this_week'] ?? 0, // Default to 0 if occurrences is null
      occurrencesThisMonth: data['occurrences_this_month'] ?? 0, // Default to 0 if occurrences is null
      occurrencesThisYear: data['occurrences_this_year'] ?? 0, // Default to 0 if occurrences is null
      occurrencesTotal: data['occurrences_total'] ?? 0, // Default to 0 if occurrences is null
    );
  }
}