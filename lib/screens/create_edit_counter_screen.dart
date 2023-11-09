import 'package:flutter/material.dart';
import '../helpers/database_helper.dart';
import '../counter.dart';
import '../widgets/app_drawer.dart';


class CreateEditCounterScreen extends StatefulWidget {
  final Counter? initialCounter;

  const CreateEditCounterScreen({super.key, this.initialCounter});

  @override
  _CreateEditCounterScreenState createState() => _CreateEditCounterScreenState();
}

class _CreateEditCounterScreenState extends State<CreateEditCounterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialCounter != null) {
      _isEditMode = true;
      _nameController.text = widget.initialCounter!.name;
      _unitController.text = widget.initialCounter!.unit;
    }
  }

  void _saveCounter() async{
    if (_isEditMode) {
      await DatabaseHelper.instance.updateCounter(
        widget.initialCounter!.id,
        _nameController.text,
        _unitController.text,
      );
    } else {
      await DatabaseHelper.instance.addCounter(
        _nameController.text,
        _unitController.text,
      );
    }
  }

  void _deleteCounter() async{
    if (_isEditMode) {
      await DatabaseHelper.instance.deleteCounterAndOccurrences(
        widget.initialCounter!.id
      );
    }
  }

  @override
  Widget build(BuildContext context) {
   return Scaffold(
     appBar: AppBar(
       title: Text(_isEditMode ? 'Edit Counter' : 'Create Counter'),
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
         Padding(
           padding: const EdgeInsets.all(8.0),
           child: TextField(
             controller: _nameController,
             decoration: const InputDecoration(
               labelText: 'Name',
             ),
           ),
         ),
         Padding(
           padding: const EdgeInsets.all(8.0),
           child: TextField(
             controller: _unitController,
             decoration: const InputDecoration(
               labelText: 'Unit',
             ),
           ),
         ),
         ElevatedButton(
           onPressed: () {
            _saveCounter();
            Navigator.pushNamed(context, '/manageCounters');
           },
           child: const Text('Save Counter'),
         ),
         if(_isEditMode) 
          ElevatedButton (
            onPressed: ()async {
              // Show a dialog and ask for confirmation
              bool? confirmDelete = await showDialog<bool>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Confirm'),
                    content: const Text('Are you sure you want to delete this counter?'),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false), // Dismisses the dialog and returns false
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.red,
                        ), // Dismisses the dialog and returns true
                        child: const Text('Delete'),
                      ),
                    ],
                  );
                },
              );

              // If confirmation is true, proceed with the deletion
              if (confirmDelete == true) {
                _deleteCounter(); // Replace with your delete function
                Navigator.pushNamed(context, '/manageCounters');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete Counter'),
          )
       ],
     ),
   );
 }
}
