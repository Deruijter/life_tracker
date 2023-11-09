import 'package:flutter/material.dart';
import '../helpers/database_helper.dart';
import '../counter.dart';
import '../widgets/app_drawer.dart';


 class ManageCountersScreen extends StatefulWidget {
  const ManageCountersScreen({super.key});

  @override
  _ManageCountersScreenState createState() => _ManageCountersScreenState();
}


class _ManageCountersScreenState extends State<ManageCountersScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();
  
  // This list would actually come from your database.
  List<Counter> _counters = []; 
    @override
  void initState() {
    super.initState();
    _loadCounters();
  }


  _loadCounters() async {
    List<Counter> countersList = await DatabaseHelper.instance.getCountersWithOccurrences();
    setState(() {
      _counters = countersList;
    });
  }

  @override
  Widget build(BuildContext context) {
   return Scaffold(
     appBar: AppBar(
       title: const Text('Manage counters'),
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
               return Card( // Wrap each item in a Card for better visual structure.
                 margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                 child: Padding(
                   padding: const EdgeInsets.all(8.0),
                   child: Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       // Left side: Counter name, occurrences, and unit.
                       Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
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
                       // Right side: Minus and Plus buttons.
                       Row(
                         children: [
                           IconButton(
                             icon: const Icon(Icons.settings),
                             onPressed: () {
                              Navigator.pushNamed(context, '/createEditCounter', arguments: {'initialCounter': counter});
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
