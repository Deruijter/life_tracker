import 'package:flutter/material.dart';
import '../repositories/tracker_repository.dart';
import '../entities/tracker.dart';
import '../widgets/app_drawer.dart';


 class ManageTrackersScreen extends StatefulWidget {
  const ManageTrackersScreen({super.key});

  @override
  _ManageTrackersScreenState createState() => _ManageTrackersScreenState();
}


class _ManageTrackersScreenState extends State<ManageTrackersScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();
  
  // This list would actually come from your database.
  List<Tracker> _trackers = []; 
    @override
  void initState() {
    super.initState();
    _loadTrackers();
  }


  _loadTrackers() async {
    List<Tracker> trackersList = await TrackerRepository.instance.getTrackersWithOccurrences();
    setState(() {
      _trackers = trackersList;
    });
  }

  @override
  Widget build(BuildContext context) {
   return Scaffold(
     appBar: AppBar(
       title: const Text('Manage Trackers'),
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
               return Card( // Wrap each item in a Card for better visual structure.
                 margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                 child: Padding(
                   padding: const EdgeInsets.all(8.0),
                   child: Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       // Left side: Tracker name, occurrences, and unit.
                       Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
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
                       // Right side: Minus and Plus buttons.
                       Row(
                         children: [
                           IconButton(
                             icon: const Icon(Icons.settings),
                             onPressed: () {
                              print(tracker.type);
                              Navigator.pushNamed(context, '/createEditTracker', arguments: {'initialTracker': tracker});
                             }
                           ),
                         ],
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
