import 'package:flutter/material.dart';
import 'package:life_tracker/screens/counter_details_screen.dart';
import 'screens/overview_screen.dart';
import 'screens/create_edit_counter_screen.dart';
import 'screens/manage_counters_screen.dart';
import 'services/location_service2.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io' show Platform;

void main() {
  if (Platform.isLinux) {
    // Initialize FFI loader for Linux development
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => LocationService2(),
      child: MaterialApp(
        title: 'Statistics Tracker',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const MyHomePage(),
        onGenerateRoute: (RouteSettings settings) {
          switch (settings.name) {
            case '/overview':
              return MaterialPageRoute(builder: (context) => OverviewScreen());
            case '/createEditCounter':
              // Extract the arguments from the settings object
              final args = settings.arguments as Map<String, dynamic>?;
              return MaterialPageRoute(
                builder: (context) => CreateEditCounterScreen(
                  initialCounter: args?['initialCounter'], // Pass the argument to the screen
                ),
              );
            case '/manageCounters':
              return MaterialPageRoute(builder: (context) => ManageCountersScreen());
            case '/counterDetails':
              // Extract the arguments from the settings object
              final args = settings.arguments as Map<String, dynamic>?;
              return MaterialPageRoute(
                builder: (context) => CounterDetailsScreen(
                  counterDetails: args?['counterDetails'], // Pass the argument to the screen
                ),
              );
            // Add more routes as needed
            default:
              // If there is no route defined for settings.name, return a route to a 404 screen or similar
              //return MaterialPageRoute(builder: (context) => UndefinedScreen(name: settings.name));
          }
        },
      ),
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
