import '../entities/tracker.dart';
import '../entities/tracker_details.dart';
import '../entities/occurrence.dart';
import '../repositories/tracker_repository.dart';
import '../services/location_service.dart';
import '../helpers/date_helper.dart';
import 'package:provider/provider.dart';
import 'package:location/location.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

class OccurrenceService{
  Future<int> getDurationMinutes(List<Occurrence> occurrences, timeStart, timeEnd) async{
    int duration = 0;

    for (var occurrence in occurrences) {
      DateTime occurrenceTimeEnd = occurrence.endTime != null ? occurrence.endTime! : DateTime.now();
      // Skip occurrences that are completely outside the time range
      if (occurrenceTimeEnd.isBefore(timeStart) || occurrence.datetime.isAfter(timeEnd)) {
        continue;
      }

      // Adjust the start and end times to fit within the time range
      DateTime occurrenceStart = occurrence.datetime.isBefore(timeStart)
          ? timeStart : occurrence.datetime;
      DateTime occurrenceEnd = occurrenceTimeEnd.isAfter(timeEnd)
          ? timeEnd : occurrenceTimeEnd;

      duration = duration + (occurrenceEnd.difference(occurrenceStart).inSeconds / 60).round(); // Use inSeconds because inMinutes only takes whole minutes
    }

    return duration;
  }
}