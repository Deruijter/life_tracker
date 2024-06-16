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

class TrackerService{
  Future<int> addOccurrence(Tracker tracker, {DateTime? datetime}) async{
    datetime ??= DateTime.now();
    //LocationService locationService = Provider.of<LocationService>(context, listen: false);
    LocationData? currentLocation = LocationService().currentLocation;

    int id = await TrackerRepository.instance.addOccurrence(
      tracker.id,
      datetime,
      currentLocation?.latitude,
      currentLocation?.longitude,
    );

    return id;
  }

  Future<DateTime> addOccurrenceTimer(Tracker tracker, {DateTime? startTime}) async{
    startTime ??= DateTime.now();

    int occurrenceId = await addOccurrence(tracker, datetime: startTime);
    await TrackerRepository.instance.addOccurrenceTimerStart(
      occurrenceId,
    );

    return startTime;
  }

  Future<DateTime> addOccurrenceTimerEnd(Tracker tracker, {DateTime? endTime}) async{
    endTime ??= DateTime.now();

    await TrackerRepository.instance.addOccurrenceTimerEnd(
      tracker.id,
      endTime
    );
    return endTime;
  }

  Future<int> timerDuration(TimerTracker tracker, DateTime startDate, DateTime endDate) async {
    int duration = await TrackerRepository.instance.getTrackerDurationFinishedBetweenDates(tracker.id, startDate, endDate);
    return duration;
  }

  Future<String> addOccurrenceText(Tracker tracker, String text, {DateTime? startTime}) async{
    startTime ??= DateTime.now();

    int occurrenceId = await addOccurrence(tracker, datetime: startTime);
    await TrackerRepository.instance.addOccurrenceText(
      occurrenceId,
      text
    );

    return text;
  }

  Future<double> addOccurrenceMonitor(Tracker tracker, double value, {DateTime? startTime}) async{
    startTime ??= DateTime.now();

    int occurrenceId = await addOccurrence(tracker, datetime: startTime);
    await TrackerRepository.instance.addOccurrenceMonitorValue(
      occurrenceId,
      value
    );

    return value;
  }

  void updateOccurrence(int occurrenceId, DateTime datetime) async {
    TrackerRepository.instance.updateOccurrence(occurrenceId, datetime);
  }
  void updateOccurrenceTimer(int occurrenceId, DateTime datetime, DateTime endTime) async {
    updateOccurrence(occurrenceId, datetime);
    TrackerRepository.instance.updateOccurrenceTimerEnd(occurrenceId, endTime);
  }
  void updateOccurrenceText(int occurrenceId, DateTime datetime, String text) async {
    updateOccurrence(occurrenceId, datetime);
    TrackerRepository.instance.updateOccurrenceText(occurrenceId, text);
  }
  void updateOccurrenceMonitor(int occurrenceId, DateTime datetime, double value) async {
    updateOccurrence(occurrenceId, datetime);
    TrackerRepository.instance.updateOccurrenceMonitor(occurrenceId, value);
  }

  void deleteOccurrence(int occurrenceId){
    TrackerRepository.instance.deleteOccurrence(occurrenceId);
  }

  // GETTERS
  Future<Tracker> getTracker(int trackerId) async {
    Tracker tracker = await TrackerRepository.instance.getTrackerWithOccurrences(trackerId);
    return tracker;
  }

  Future<TrackerDetails> getTrackerDetails(int trackerId) async {
    TrackerDetails trackerDetails = await TrackerRepository.instance.getTrackerDetails(trackerId);
    return trackerDetails;
  }

  Future<List<Occurrence>> getOccurrencesByTrackerId(int trackerId) async {
    List<Occurrence> occurrences = await TrackerRepository.instance.getOccurrencesByTrackerId(trackerId);
    return occurrences;
  }
}