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
}