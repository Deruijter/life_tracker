import '../repositories/tracker_repository.dart';

class Occurrence {
  final int id;
  final int trackerId;
  final DateTime datetime;
  final DateTime? endTime;
  final String? text;
  final double? value;

  Occurrence({required this.id, required this.trackerId, required this.datetime, this.endTime, this.text, this.value});

  // Factory constructor to create a Tracker from a Map
  factory Occurrence.fromMap(Map<String, dynamic> data) {
    return Occurrence(
      id: data['occurrence_id'],
      trackerId: data['tracker_id'],
      datetime: DateTime.tryParse(data['datetime'])!, // Shouldn't be able to be null
      endTime: data['end_time'] != null ? DateTime.tryParse(data['end_time']) : null,
      text: data['text'],
      value: data['value']
    );
  }
  
  // Define a copy method to create a deep copy of the object
  Occurrence copy(id, trackerId, datetime, endTime, text, value) {
    return Occurrence(id: id, trackerId: trackerId, datetime: datetime, endTime: endTime, text: text, value: value);
  }

  int getDurationInMinutes() {
    if(endTime == null){
      return DateTime.now().difference(datetime).inMinutes.round();
    }
    return endTime!.difference(datetime).inMinutes.round();
  }

  int getDurationInHours() {
    if(endTime == null){
      return DateTime.now().difference(datetime).inHours.round();
    }
    return endTime!.difference(datetime).inHours.round();
  }
}

