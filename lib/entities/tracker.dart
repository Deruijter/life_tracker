import '../repositories/tracker_repository.dart';

class Tracker {
  final int id;
  final String name;
  final String unit;
  final TrackerType type;
  final int occurrences;
  DateTime? latestOccurrence;

  Tracker({required this.id, required this.name, required this.unit, required this.type, this.occurrences = 0, this.latestOccurrence});

  // Factory constructor to create a Tracker from a Map
  factory Tracker.fromMap(Map<String, dynamic> data) {
    return Tracker(
      id: data['tracker_id'],
      name: data['name'],
      unit: data['unit'],
      type: data['type'].toString().trackerType,
      occurrences: data['occurrences'] ?? 0, // Default to 0 if occurrences is null
      latestOccurrence: data['latest_occurrence'] != null ? DateTime.tryParse(data['latest_occurrence']) : null,
    );
  }
}

class CounterTracker extends Tracker {
  CounterTracker({
    required int id,
    required String name,
    required String unit,
    required TrackerType type,
    int occurrences = 0,
    DateTime? latestOccurrence,
  }) : super(id: id, name: name, unit: unit, type: type, occurrences: occurrences, latestOccurrence: latestOccurrence);

    // Factory constructor to create a Tracker from a Map
  factory CounterTracker.fromMap(Map<String, dynamic> data) {
    return CounterTracker(
      id: data['tracker_id'],
      name: data['name'],
      unit: data['unit'],
      type: data['type'].toString().trackerType,
      occurrences: data['occurrences'] ?? 0, // Default to 0 if occurrences is null
      latestOccurrence: data['latest_occurrence'] != null ? DateTime.tryParse(data['latest_occurrence']) : null,
    );
  }
}

class TimerTracker extends Tracker {
  DateTime? endTime;
  double durationFinished;


  TimerTracker({
    required int id,
    required String name,
    required String unit,
    required TrackerType type,
    int occurrences = 0,
    DateTime? latestOccurrence,
    this.endTime,
    this.durationFinished = 0,
  }) : super(id: id, name: name, unit: unit, type: type, occurrences: occurrences, latestOccurrence: latestOccurrence);

    // Factory constructor to create a Tracker from a Map
  factory TimerTracker.fromMap(Map<String, dynamic> data) {
    return TimerTracker(
      id: data['tracker_id'],
      name: data['name'],
      unit: data['unit'],
      type: data['type'].toString().trackerType,
      occurrences: data['occurrences'] ?? 0, // Default to 0 if occurrences is null
      latestOccurrence: data['latest_occurrence'] != null ? DateTime.tryParse(data['latest_occurrence']) : null,
      endTime: data['end_time'] != null ? DateTime.tryParse(data['end_time']) : null,
      durationFinished: data['duration_finished'] ?? 0,
    );
  }

  bool isRunning(){
    return(latestOccurrence != null && endTime == null ? true : false);
  }
}

class TextTracker extends Tracker {
  String? text;
  
  TextTracker({
    required int id,
    required String name,
    required String unit,
    required TrackerType type,
    int occurrences = 0,
    DateTime? latestOccurrence,
    required this.text,
  }) : super(id: id, name: name, unit: unit, type: type, occurrences: occurrences, latestOccurrence: latestOccurrence);

    // Factory constructor to create a Tracker from a Map
  factory TextTracker.fromMap(Map<String, dynamic> data) {
    return TextTracker(
      id: data['tracker_id'],
      name: data['name'],
      unit: data['unit'],
      type: data['type'].toString().trackerType,
      occurrences: data['occurrences'] ?? 0, // Default to 0 if occurrences is null
      latestOccurrence: data['latest_occurrence'] != null ? DateTime.tryParse(data['latest_occurrence']) : null,
      text: data['text'],
    );
  }
}

class MonitorTracker extends Tracker {
  double? value;

  MonitorTracker({
    required int id,
    required String name,
    required String unit,
    required TrackerType type,
    int occurrences = 0,
    DateTime? latestOccurrence,
    required this.value,
  }) : super(id: id, name: name, unit: unit, type: type, occurrences: occurrences, latestOccurrence: latestOccurrence);

    // Factory constructor to create a Tracker from a Map
  factory MonitorTracker.fromMap(Map<String, dynamic> data) {
    return MonitorTracker(
      id: data['tracker_id'],
      name: data['name'],
      unit: data['unit'],
      type: data['type'].toString().trackerType,
      occurrences: data['occurrences'] ?? 0, // Default to 0 if occurrences is null
      latestOccurrence: data['latest_occurrence'] != null ? DateTime.tryParse(data['latest_occurrence']) : null,
      value: data['value'],
    );
  }
}

