import '../entities/tracker.dart';
import '../entities/tracker_details.dart';
import '../repositories/tracker_repository.dart';
import '../services/location_service.dart';
import '../helpers/date_helper.dart';
import 'package:provider/provider.dart';
import 'package:location/location.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

class TrackerService{
  void counterIncrement(Tracker tracker) async{
    //LocationService locationService = Provider.of<LocationService>(context, listen: false);
    LocationData? currentLocation = LocationService().currentLocation;

    int id = await TrackerRepository.instance.addOccurrence(
      tracker.id,
      currentLocation?.latitude,
      currentLocation?.longitude,
    );
  }

  Future<DateTime> timerStart(Tracker tracker) async{
    //LocationService locationService = Provider.of<LocationService>(context, listen: false);
    LocationData? currentLocation = LocationService().currentLocation;

    DateTime startTime = await TrackerRepository.instance.addOccurrenceWithOccurrenceTimerStart(
      tracker.id,
      currentLocation?.latitude,
      currentLocation?.longitude,
    );

    return startTime;
  }

  Future<DateTime> timerEnd(Tracker tracker) async{
    DateTime endTime = await TrackerRepository.instance.addOccurrenceWithOccurrenceTimerEnd(
      tracker.id
    );
    return endTime;
  }

  Future<int> timerDuration(TimerTracker tracker, DateTime startDate, DateTime endDate) async {
    int duration = await TrackerRepository.instance.getTrackerDurationFinishedBetweenDates(tracker.id, startDate, endDate);
    return duration;
  }

  Future<String> textAdd(Tracker tracker, String text) async{
    LocationData? currentLocation = LocationService().currentLocation;

    await TrackerRepository.instance.addOccurrenceWithOccurrenceText(
      tracker.id, 
      currentLocation?.latitude,
      currentLocation?.longitude,
      text);

    return text;
  }

  Future<double> monitorAdd(Tracker tracker, double value) async{
    LocationData? currentLocation = LocationService().currentLocation;

    await TrackerRepository.instance.addOccurrenceWithOccurrenceMonitor(
      tracker.id, 
      currentLocation?.latitude,
      currentLocation?.longitude,
      value);

    return value;
  }
}