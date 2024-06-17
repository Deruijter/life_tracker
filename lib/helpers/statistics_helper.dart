import '../entities/occurrence.dart';
import 'package:flutter/material.dart';

class StatisticsHelper {
  List<int> binOccurrencesByHour(
      List<Map<String, dynamic>> occurrences, DateTime start, DateTime end) {
    // Calculate the difference in hours plus one to include the end hour.
    int totalHours = end.difference(start).inHours + 1;

    // Initialize a list for the number of hours with zeros.
    List<int> hourlyOccurrences = List.generate(totalHours, (index) => 0);

    for (var occurrence in occurrences) {
      DateTime occurrenceTime = DateTime.parse(occurrence['datetime']);
      if (occurrenceTime.isAfter(start) && occurrenceTime.isBefore(end)) {
        int hourIndex = occurrenceTime.difference(start).inHours;
        hourlyOccurrences[hourIndex]++;
      }
    }

    return hourlyOccurrences;
  }
  List<int> binOccurrencesByDay(List<Occurrence> occurrences, DateTime start, DateTime end) {
    // Calculate the difference in hours plus one to include the end day.
    int totalDays = end.difference(start).inDays;

    // Initialize a list for the number of hours with zeros.
    List<int> dayOccurrences = List.generate(totalDays, (index) => 0);

    for (var occurrence in occurrences) {
      DateTime occurrenceTime = DateUtils.dateOnly(occurrence.datetime);
      if (occurrenceTime.isAfter(start) && occurrenceTime.isBefore(end)) {
        int dayIndex = occurrenceTime.difference(start).inDays;
        dayOccurrences[dayIndex]++;
      }
    }
    
    return dayOccurrences;
  }

  List<int> binOccurrenceDurationsByDay(
    List<Occurrence> occurrences,
    DateTime timeStart,
    DateTime timeEnd,
  ) {
    // Calculate the number of whole days
    int numberOfDays = timeEnd.difference(timeStart).inDays; //Subtract some days so we don't go out of bounds of the plot
    List<int> dailyDurations = List.filled(numberOfDays, 0);

    // A bit of a hack to make sure we only use whole days and nog 24h differ
    // So basically we set the end date to "tomorrow at 00:00"
    timeStart = DateUtils.dateOnly(timeStart).add(Duration(days: 1));
    timeEnd = DateUtils.dateOnly(timeEnd).add(Duration(days: 1)); 

    for (var occurrence in occurrences) {
      DateTime occurrenceTimeEnd = occurrence.endTime != null ? occurrence.endTime! : DateTime.now();
      // Skip occurrences that are completely outside the time range
      if (occurrenceTimeEnd.isBefore(timeStart) ||
          occurrence.datetime.isAfter(timeEnd)) {
        continue;
      }

      // Adjust the start and end times to fit within the time range
      DateTime occurrenceStart = occurrence.datetime.isBefore(timeStart)
          ? timeStart
          : occurrence.datetime;
      DateTime occurrenceEnd = occurrenceTimeEnd.isAfter(timeEnd)
          ? timeEnd
          : occurrenceTimeEnd;

      DateTime currentStart = occurrenceStart;

      while (currentStart.isBefore(occurrenceEnd)) {
        DateTime currentEnd = DateTime(
          currentStart.year,
          currentStart.month,
          currentStart.day,
          23,
          59,
          59,
        );

        if (currentEnd.isAfter(occurrenceEnd)) {
          currentEnd = occurrenceEnd;
        }

        int dayIndex = currentStart.difference(timeStart).inDays;
        if (dayIndex >= 0 && dayIndex < numberOfDays) {
          dailyDurations[dayIndex] += (currentEnd.difference(currentStart).inSeconds / 60).round(); // Use inSeconds because inMinutes only takes whole minutes
        }

        currentStart = DateTime(
          currentStart.year,
          currentStart.month,
          currentStart.day + 1,
          0,
          0,
          0,
        );
      }
    }

    return dailyDurations;
  }

  double interpolateDateValue(Occurrence o1, Occurrence o2, DateTime targetDate) {
    // Need to figure out how to handle this nicer but this will do for now:
    if (o1.value == null || o2.value == null){
      print("Cannot interpolate null values");
      return 0;
    }
    
    double x1 = o1.datetime.millisecondsSinceEpoch.toDouble();
    double x2 = o2.datetime.millisecondsSinceEpoch.toDouble();
    double x = targetDate.millisecondsSinceEpoch.toDouble();

    double y1 = o1.value!;
    double y2 = o2.value!;
    double y = y1 + (y2 - y1) * ((x - x1) / (x2 - x1));

    return y;
  }
}