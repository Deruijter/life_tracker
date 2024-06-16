import '../repositories/tracker_repository.dart';

class Occurrence {
  final int id;
  final int trackerId;
  final DateTime time;
  final DateTime? endTime;
  final String? text;
  final double? value;

  Occurrence({required this.id, required this.trackerId, required this.time, this.endTime, this.text, this.value});

  // Factory constructor to create a Tracker from a Map
  factory Occurrence.fromMap(Map<String, dynamic> data) {
    return Occurrence(
      id: data['occurrence_id'],
      trackerId: data['tracker_id'],
      time: DateTime.tryParse(data['datetime'])!, // Shouldn't be able to be null
      endTime: data['end_time'] != null ? DateTime.tryParse(data['end_time']) : null,
      text: data['text'],
      value: data['value']
    );
  }
}

