import 'package:location/location.dart';
import 'dart:io' show Platform;

class LocationService {
  final Location location = Location();

  Future<LocationData?> getLocation() async {
    if (Platform.isAndroid || Platform.isIOS) {
      bool serviceEnabled;
      PermissionStatus permissionGranted;

      // Check if location services are enabled.
      serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await location.requestService();
        if (!serviceEnabled) {
          return null; // If not enabled even after the prompt, return.
        }
      }

      // Check for location permissions; if not granted, request them.
      permissionGranted = await location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          return null; // If permission not granted, return.
        }
      }

      // Get the current location of the user.
      return await location.getLocation();
      
    } else {
      return LocationData.fromMap({
        'latitude': 123.456, // Provide mock latitude
        'longitude': 78.90, // Provide mock longitude
        // ... add other fields if needed
      });
    }
  }
}
