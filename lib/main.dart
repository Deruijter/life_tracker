import 'package:flutter/material.dart';
import 'package:life_tracker/screens/tracker_details_screen.dart';
import 'screens/overview_screen.dart';
import 'screens/create_edit_tracker_screen.dart';
import 'screens/manage_trackers_screen.dart';
import 'screens/extra_options_screen.dart';
import 'services/location_service.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:window_manager/window_manager.dart';
import 'providers/theme_provider.dart';
import 'dart:io' show Platform;

void main() {
  if (Platform.isLinux) {
    // Initialize FFI loader for Linux development
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(lightTheme),
      child: MyApp(),
    ),
  );

  if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
    windowManager.setSize(Size(1080/2.5, 1920/2.5));
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
        title: 'Statistics Tracker',
        theme: themeProvider.themeData,
        home: const MyHomePage(),
        onGenerateRoute: (RouteSettings settings) {
          switch (settings.name) {
            case '/overview':
              return MaterialPageRoute(builder: (context) => OverviewScreen());
            case '/createEditTracker':
              // Extract the arguments from the settings object
              final args = settings.arguments as Map<String, dynamic>?;
              return MaterialPageRoute(
                builder: (context) => CreateEditTrackerScreen(
                  initialTracker: args?['initialTracker'], // Pass the argument to the screen
                ),
              );
            case '/manageTrackers':
              return MaterialPageRoute(builder: (context) => ManageTrackersScreen());
            case '/trackerDetails':
              // Extract the arguments from the settings object
              final args = settings.arguments as Map<String, dynamic>?;
              return MaterialPageRoute(
                builder: (context) => TrackerDetailsScreen(
                  trackerDetails: args?['trackerDetails'], // Pass the argument to the screen
                ),
              );
            case '/extraOptions':
              return MaterialPageRoute(builder: (context) => ExtraOptionsScreen());
            // Add more routes as needed
            default:
              // If there is no route defined for settings.name, return a route to a 404 screen or similar
              //return MaterialPageRoute(builder: (context) => UndefinedScreen(name: settings.name));
          }
        });
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
  
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return const OverviewScreen(); // Return the OverviewScreen directly
  }
}
