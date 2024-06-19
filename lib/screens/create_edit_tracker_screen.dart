import 'package:flutter/material.dart';
import '../repositories/tracker_repository.dart';
import '../entities/tracker.dart';
import '../widgets/app_drawer.dart';

class CreateEditTrackerScreen extends StatefulWidget {
  final Tracker? initialTracker;

  const CreateEditTrackerScreen({super.key, this.initialTracker});

  @override
  _CreateEditTrackerScreenState createState() =>
      _CreateEditTrackerScreenState();
}

class _CreateEditTrackerScreenState extends State<CreateEditTrackerScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();
  bool _isEditMode = false;
  TrackerType _selectedType;

  _CreateEditTrackerScreenState() : _selectedType = TrackerType.counter;

  @override
  void initState() {
    super.initState();
    setState(() {
      if (widget.initialTracker != null) {
        _isEditMode = true;
        _nameController.text = widget.initialTracker!.name;
        _unitController.text = widget.initialTracker!.unit;
        _selectedType = widget.initialTracker!.type;
        print(_selectedType);
      }
    });
  }

  void _saveTracker() async {
    String trackerUnit = _unitController.text;
    if (_selectedType == TrackerType.timer ||
        _selectedType == TrackerType.text) {
      trackerUnit = '';
    }
    if (_isEditMode) {
      await TrackerRepository.instance.updateTracker(
        widget.initialTracker!.id,
        _nameController.text,
        trackerUnit,
      );
    } else {
      await TrackerRepository.instance.addTracker(
        _nameController.text,
        trackerUnit,
        _selectedType.string,
      );
    }
  }

  void _deleteTracker() async {
    if (_isEditMode) {
      await TrackerRepository.instance
          .deleteTrackerAndOccurrences(widget.initialTracker!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    List<TrackerType> trackerTypes = TrackerType.values;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Tracker' : 'Create Tracker'),
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
          if (!_isEditMode)
            SizedBox(
                height: 100,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    mainAxisExtent: 40, // Custom height
                  ),
                  padding: const EdgeInsets.all(8.0),
                  itemCount: trackerTypes.length,
                  itemBuilder: (BuildContext context, int index) {
                    // Get the tracker type for the current index
                    TrackerType type = trackerTypes[index];
                    return GestureDetector(
                      onTap: () => setState(() {
                        _selectedType = type;
                      }),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          color: _selectedType == type
                              ? Colors.blue
                              : Colors.grey[200],
                        ),
                        child: Center(
                          child: Text(
                            type
                                .toString()
                                .split('.')
                                .last, // Display the enum as a string
                            style: TextStyle(
                              color: _selectedType == type
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                )),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
              ),
            ),
          ),
          if (_selectedType == TrackerType.counter ||
              _selectedType == TrackerType.monitor)
            // Unit is only necessary for Counters and Monitors
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _unitController,
                decoration: const InputDecoration(
                  labelText: 'Unit',
                ),
              ),
            ),
          SizedBox(height:32),
          Row(
            children: [
              SizedBox(width: 30),
              if (_isEditMode)
                ElevatedButton(
                  onPressed: () async {
                    // Show a dialog and ask for confirmation
                    bool? confirmDelete = await showDialog<bool>(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Confirm'),
                          content: const Text(
                              'Are you sure you want to delete this tracker?'),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(
                                  false), // Dismisses the dialog and returns false
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
                      _deleteTracker(); // Replace with your delete function
                      Navigator.pushNamed(context, '/manageTrackers');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: const Text('Delete Tracker'),
                ),
              Spacer(),
              ElevatedButton(
                onPressed: () {
                  _saveTracker();
                  Navigator.pushNamed(context, '/manageTrackers');
                },
                child: const Text('Save Tracker'),
              ),
              SizedBox(width: 30),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildTrackerTypeButton(TrackerType type) {
    return GestureDetector(
      onTap: () => setState(() {
        _selectedType = type;
      }),
      child: SizedBox(
        height: 50,
        child: Container(
          decoration: BoxDecoration(
            color: _selectedType == type ? Colors.blue : Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _selectedType == type ? Colors.blue : Colors.grey,
            ),
          ),
          child: Center(
            child: Text(
              type.toString().split('.').last, // Display the enum as a string
              style: TextStyle(
                color: _selectedType == type ? Colors.white : Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
