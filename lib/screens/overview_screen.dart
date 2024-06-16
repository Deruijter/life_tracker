import 'package:flutter/material.dart';
import 'package:life_tracker/services/tracker_service.dart';
import '../repositories/tracker_repository.dart';
import '../entities/tracker.dart';
import '../entities/tracker_details.dart';
import '../widgets/app_drawer.dart';
import '../services/location_service.dart';
import 'package:provider/provider.dart';
import 'package:location/location.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';


 class OverviewScreen extends StatefulWidget {
  const OverviewScreen({super.key});

  @override
  _OverviewScreenState createState() => _OverviewScreenState();
}


class _OverviewScreenState extends State<OverviewScreen> {
  TextEditingController _textFieldController = TextEditingController();
  TextEditingController _valueFieldController = TextEditingController();
  
  // This list would actually come from your database.
  List<Tracker> _trackers = []; 
  @override
  void initState() {
    super.initState();
    _loadTrackers();
  }


  _loadTrackers() async {
    DateTime now = DateTime.now();
    String startDate = DateFormat('yyyy-MM-dd').format(now) + ' 00:00:00';
    DateTime tomorrow = DateTime(now.year, now.month, now.day + 1);
    String endDate = DateFormat('yyyy-MM-dd').format(tomorrow) + ' 00:00:00';
    List<Tracker> trackersList = await TrackerRepository.instance.getTrackersWithOccurrencesByDate(startDate, endDate);
    setState(() {
      _trackers = trackersList;
    });
    await TrackerRepository.instance.printAllTrackers();
  }


  void _addStartOccurrence(Tracker tracker) async{
    // LocationService locationService = Provider.of<LocationService>(context, listen: false);
    // LocationData? currentLocation = locationService.currentLocation;

    // int id = await TrackerRepository.instance.addOccurrence(
    //   trackerId,
    //   currentLocation?.latitude,
    //   currentLocation?.longitude,
    // );
    switch(tracker.type){
      case TrackerType.counter:
        TrackerService().addOccurrence(tracker);
      case TrackerType.timer:
        DateTime latestOccurrence = await TrackerService().addOccurrenceTimer(tracker);
        if(tracker is TimerTracker){ // Check & cast Tracker to TimerTracker
          tracker.endTime = null;
          tracker.latestOccurrence = latestOccurrence;
        }
      case TrackerType.text:
        TrackerService().addOccurrenceText(tracker, _textFieldController.text);
        if(tracker is TextTracker){
          tracker.text = _textFieldController.text;
        }
      case TrackerType.monitor:
        String valueText = _valueFieldController.text;
        valueText = valueText.replaceAll(',', '.'); // incase the user input commas
        double value = double.parse(valueText);
        TrackerService().addOccurrenceMonitor(tracker, value);
        if(tracker is MonitorTracker){
          tracker.value = value;
        }
      default:
    }

    _refreshTracker(tracker);
  }

  void _refreshTracker(Tracker tracker) async{
    int trackerId = tracker.id;

    DateTime now = DateTime.now();
    String startDate = DateFormat('yyyy-MM-dd').format(now) + ' 00:00:00';
    DateTime tomorrow = DateTime(now.year, now.month, now.day + 1);
    String endDate = DateFormat('yyyy-MM-dd').format(tomorrow) + ' 00:00:00';
    int newOccurrenceCount = await TrackerRepository.instance.getTrackerOccurrencesByDate(trackerId, startDate, endDate);

    setState(() {
      final index = _trackers.indexWhere((tracker) => tracker.id == trackerId);
      if (index != -1) {
        if(tracker is CounterTracker){
          _trackers[index] = CounterTracker(
            id: _trackers[index].id,
            name: _trackers[index].name,
            unit: _trackers[index].unit,
            type: _trackers[index].type,
            occurrences: newOccurrenceCount,
          );
        }
        if(tracker is TimerTracker){
          _trackers[index] = TimerTracker(
            id: _trackers[index].id,
            name: _trackers[index].name,
            unit: _trackers[index].unit,
            type: _trackers[index].type,
            occurrences: newOccurrenceCount,
            endTime: tracker.endTime,
            latestOccurrence: tracker.latestOccurrence,
            durationFinished: tracker.durationFinished,
          );
        }
        if(tracker is TextTracker){
          _trackers[index] = TextTracker(
            id: _trackers[index].id,
            name: _trackers[index].name,
            unit: _trackers[index].unit,
            type: _trackers[index].type,
            occurrences: newOccurrenceCount,
            text: tracker.text,
          );
          _textFieldController.text = "";
        }
        if(tracker is MonitorTracker){
          _trackers[index] = MonitorTracker(
            id: _trackers[index].id,
            name: _trackers[index].name,
            unit: _trackers[index].unit,
            type: _trackers[index].type,
            occurrences: newOccurrenceCount,
            value: tracker.value,
          );
          _valueFieldController.text = "";
        }
      }
    });
  }

  void _decrementStopOccurrence(Tracker tracker) async {
    switch(tracker.type){
      case TrackerType.counter:
        await TrackerRepository.instance.deleteNewestOccurrence(tracker.id);
      case TrackerType.timer:
        DateTime endTime = await TrackerService().addOccurrenceTimerEnd(tracker);
        if(tracker is TimerTracker){ // Cast Tracker to TimerTracker
          tracker.endTime = endTime;
          DateTime now = DateTime.now();
          DateTime durationEndTime = tracker.endTime ?? now;
          DateTime durationStartTime = tracker.latestOccurrence ?? now;
          tracker.durationFinished = tracker.durationFinished + ((durationEndTime.difference(durationStartTime).inSeconds)/60);
        }
      default:
    }
    _refreshTracker(tracker);
  }

  void _getTrackerDetails(int trackerId) async {
     TrackerDetails? trackerDetails = await TrackerRepository.instance.getTrackerDetails(trackerId);

     setState((){
      Navigator.pushNamed(context, '/trackerDetails', arguments: {'trackerDetails': trackerDetails});
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
             itemCount: _trackers.length,
             itemBuilder: (ctx, index) {
              final tracker = _trackers[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start, // This aligns children to the start of the Row
                    children: [
                      IconButton(
                        icon: const Icon(Icons.bar_chart, color: Colors.grey),
                        onPressed: () => _getTrackerDetails(tracker.id),
                      ),
                      if(tracker is CounterTracker)
                        Expanded(
                          // Wrap the Column in an Expanded widget to take all remaining space
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start, // Align text to the start (left)
                            children: [
                              Text(
                                tracker.name,
                                style: const TextStyle(
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${tracker.occurrences} ${tracker.unit}',
                                style: TextStyle(
                                  fontSize: 16.0,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      if(tracker is TimerTracker)
                        Expanded(
                          // Wrap the Column in an Expanded widget to take all remaining space
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start, // Align text to the start (left)
                            children: [
                              Text(
                                tracker.name,
                                style: const TextStyle(
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if(!tracker.isRunning())
                                Text(
                                  '${tracker.durationFinished.round()} min.',
                                  //'Last start: ${tracker.latestOccurrence} _ ${tracker.endTime}',
                                  style: TextStyle(
                                    fontSize: 16.0,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              if(tracker.isRunning())
                                Text(
                                  'Running since: ${DateFormat('yyyy-MM-dd kk:mm').format(tracker.latestOccurrence!)}',
                                  style: TextStyle(
                                    fontSize: 16.0,
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      if(tracker is TextTracker)
                        Expanded(
                          // Wrap the Column in an Expanded widget to take all remaining space
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start, // Align text to the start (left)
                            children: [
                              Text(
                                tracker.name,
                                style: const TextStyle(
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${tracker.text}',
                                style: TextStyle(
                                  fontSize: 16.0,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      if(tracker is MonitorTracker)
                        Expanded(
                          // Wrap the Column in an Expanded widget to take all remaining space
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start, // Align text to the start (left)
                            children: [
                              Text(
                                tracker.name,
                                style: const TextStyle(
                                  fontSize: 18.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${tracker.value} ${tracker.unit}',
                                style: TextStyle(
                                  fontSize: 16.0,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      if(tracker.type == TrackerType.counter)
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove, color: Colors.red),
                            onPressed: () => _decrementStopOccurrence(tracker),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add, color: Colors.green),
                            onPressed: () => _addStartOccurrence(tracker),
                          ),
                        ]
                      ),
                      if(tracker is TimerTracker)
                      Row(
                        children: [
                          if(tracker.isRunning()) // If timer is running (i.e. there is an empty occurrence_timer)
                          IconButton(
                            icon: const Icon(Icons.stop, color: Colors.red),
                            onPressed: () => _decrementStopOccurrence(tracker),
                          ),
                          if(!tracker.isRunning()) // If timer NOT running (i.e. there no empty occurrence_timer)
                          IconButton(
                            icon: const Icon(Icons.play_arrow, color: Colors.green),
                            onPressed: () => _addStartOccurrence(tracker),
                          ),
                        ]
                      ),
                      if(tracker is TextTracker)
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.text_increase, color: Colors.green),
                            onPressed: () async{
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: Text('Enter Information'),
                                    content: TextField(
                                      controller: _textFieldController,
                                      decoration: InputDecoration(hintText: ""),
                                    ),
                                    actions: <Widget>[
                                      ElevatedButton(
                                        child: Text('CANCEL'),
                                        onPressed: () {
                                          Navigator.pop(context); // Close the dialog
                                        },
                                      ),
                                      ElevatedButton(
                                        child: Text('CONFIRM'),
                                        onPressed: () {
                                          String text = _textFieldController.text;
                                          _addStartOccurrence(tracker);
                                          Navigator.pop(context); // Close the dialog
                                        },
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                        ]
                      ),
                      if(tracker is MonitorTracker)
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.add, color: Colors.green),
                            onPressed: () async{
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: Text('New value:'),
                                    content: TextField(
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(RegExp(r'^\d*[\.,]?\d*')),
                                      ],
                                      controller: _valueFieldController,
                                      decoration: InputDecoration(hintText: ""),
                                    ),
                                    actions: <Widget>[
                                      ElevatedButton(
                                        child: Text('CANCEL'),
                                        onPressed: () {
                                          Navigator.pop(context); // Close the dialog
                                        },
                                      ),
                                      ElevatedButton(
                                        child: Text('CONFIRM'),
                                        onPressed: () {
                                          String text = _valueFieldController.text;
                                          _addStartOccurrence(tracker);
                                          Navigator.pop(context); // Close the dialog
                                        },
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                        ]
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
