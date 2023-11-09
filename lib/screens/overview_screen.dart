import 'package:flutter/material.dart';
import '../helpers/database_helper.dart';
import '../counter.dart';
import '../counter_details.dart';
import '../widgets/app_drawer.dart';
import '../services/location_service2.dart';
import 'package:provider/provider.dart';
import 'package:location/location.dart';
import 'package:intl/intl.dart';


 class OverviewScreen extends StatefulWidget {
  const OverviewScreen({super.key});

  @override
  _OverviewScreenState createState() => _OverviewScreenState();
}


class _OverviewScreenState extends State<OverviewScreen> {
  
  // This list would actually come from your database.
  List<Counter> _counters = []; 
  @override
  void initState() {
    super.initState();
    _loadCounters();
  }


  _loadCounters() async {
    DateTime now = DateTime.now();
    String startDate = DateFormat('yyyy-MM-dd').format(now) + ' 00:00:00';
    DateTime tomorrow = DateTime(now.year, now.month, now.day + 1);
    String endDate = DateFormat('yyyy-MM-dd').format(tomorrow) + ' 00:00:00';
    List<Counter> countersList = await DatabaseHelper.instance.getCountersWithOccurrencesByDate(startDate, endDate);
    //List<Counter> countersList = await DatabaseHelper.instance.getCountersWithOccurrences();
    setState(() {
      _counters = countersList;
    });
  }


  void _addOccurrence(int counterId) async{
    LocationService2 locationService = Provider.of<LocationService2>(context, listen: false);
    LocationData? currentLocation = locationService.currentLocation;

    print(currentLocation?.latitude);
    int id = await DatabaseHelper.instance.addOccurrence(
      counterId,
      currentLocation?.latitude,
      currentLocation?.longitude,
    );


    DateTime now = DateTime.now();
    String startDate = DateFormat('yyyy-MM-dd').format(now) + ' 00:00:00';
    DateTime tomorrow = DateTime(now.year, now.month, now.day + 1);
    String endDate = DateFormat('yyyy-MM-dd').format(tomorrow) + ' 00:00:00';
    int newOccurrenceCount = await DatabaseHelper.instance.getCounterOccurrencesByDate(counterId, startDate, endDate);


    setState(() {
      final index = _counters.indexWhere((counter) => counter.id == counterId);
      if (index != -1) {
        _counters[index] = Counter(
          id: _counters[index].id,
          name: _counters[index].name,
          unit: _counters[index].unit,
          occurrences: newOccurrenceCount,
        );
      }
    });
  }


  void _deleteNewestOccurrence(int counterId) async {
    await DatabaseHelper.instance.deleteNewestOccurrence(counterId);

    DateTime now = DateTime.now();
    String startDate = DateFormat('yyyy-MM-dd').format(now) + ' 00:00:00';
    DateTime tomorrow = DateTime(now.year, now.month, now.day + 1);
    String endDate = DateFormat('yyyy-MM-dd').format(tomorrow) + ' 00:00:00';
    int newOccurrenceCount = await DatabaseHelper.instance.getCounterOccurrencesByDate(counterId, startDate, endDate);

    // Here you would normally update the database and set state to update the UI.
    setState(() {
      final index = _counters.indexWhere((counter) => counter.id == counterId);
      if (index != -1) {
        _counters[index] = Counter(
          id: _counters[index].id,
          name: _counters[index].name,
          unit: _counters[index].unit,
          occurrences: newOccurrenceCount,
        );
      }
    });
  }

  void _getCounterDetails(int counterId) async {
     CounterDetails? counterDetails = await DatabaseHelper.instance.getCounterDetails(counterId);

     setState((){
      Navigator.pushNamed(context, '/counterDetails', arguments: {'counterDetails': counterDetails});
     });
  }

  @override
  Widget build(BuildContext context) {
   return Scaffold(
     appBar: AppBar(
       title: const Text('Overview'),
       // The leading widget is on the left side of the app bar
       leading: Builder(
         builder: (BuildContext context) {
           return IconButton(
             icon: const Icon(Icons.menu),
             onPressed: () {
               Scaffold.of(context).openDrawer();
             },
             tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
           );
         },
       ),
     ),
     drawer: const AppDrawer(),
     body: Column(
       children: <Widget>[
         Expanded(
           child: ListView.builder(
             itemCount: _counters.length,
             itemBuilder: (ctx, index) {
               final counter = _counters[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start, // This aligns children to the start of the Row
                    children: [
                      IconButton(
                        icon: const Icon(Icons.bar_chart, color: Colors.grey),
                        onPressed: () => _getCounterDetails(counter.id),
                      ),
                      Expanded(
                        // Wrap the Column in an Expanded widget to take all remaining space
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start, // Align text to the start (left)
                          children: [
                            Text(
                              counter.name,
                              style: const TextStyle(
                                fontSize: 18.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${counter.occurrences} ${counter.unit}',
                              style: TextStyle(
                                fontSize: 16.0,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove, color: Colors.red),
                        onPressed: () => _deleteNewestOccurrence(counter.id),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, color: Colors.green),
                        onPressed: () => _addOccurrence(counter.id),
                      ),
                    ],
                  ),
                ),
              );
             },
           ),
         ),
       ],
     ),
   );
 }
}
