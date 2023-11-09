import 'dart:async';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'dart:io' show Platform;

class LocationService2 extends ChangeNotifier {
  Location location = Location();
  LocationData? currentLocation;
  
  StreamSubscription<LocationData>? _locationStreamSubscription;

  LocationService2() {
    // If you're on Linux, set a mocked location.
    if (Platform.isLinux) {
      currentLocation = LocationData.fromMap({
        'latitude': 67.89, // Mocked latitude
        'longitude': 123.45, // Mocked longitude
      });
      // You don't need to listen for changes because this is a mock.
    } else {
      startListening();
    }
  }

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
