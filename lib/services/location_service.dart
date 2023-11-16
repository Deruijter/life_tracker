import 'dart:async';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'dart:io' show Platform;

class LocationService extends ChangeNotifier {
  static final LocationService _instance = LocationService._internal();

  factory LocationService() => _instance;

  LocationService._internal() {
    // Your existing constructor logic
    if (Platform.isLinux) {
      currentLocation = LocationData.fromMap({
        'latitude': 67.89, // Mocked latitude
        'longitude': 123.45, // Mocked longitude
      });
    } else {
      startListening();
    }
  }

  Location location = Location();
  LocationData? currentLocation;
  
  StreamSubscription<LocationData>? _locationStreamSubscription;

  void startListening() {
    _locationStreamSubscription = location.onLocationChanged.listen((LocationData newLocation) {
      currentLocation = newLocation;
      notifyListeners(); // Notify all listening widgets to rebuild
    });
  }

  void stopListening() {
    _locationStreamSubscription?.cancel();
    _locationStreamSubscription = null;
  }

  @override
  void dispose() {
    _locationStreamSubscription?.cancel();
    super.dispose();
  }
}
