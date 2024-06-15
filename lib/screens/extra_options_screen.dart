import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../repositories/tracker_repository.dart';
import '../entities/tracker.dart';
import '../helpers/ui_helper.dart';
import '../widgets/app_drawer.dart';

class ExtraOptionsScreen extends StatefulWidget {
  @override
  _ExtraOptionsScreenState createState() => _ExtraOptionsScreenState();
}

class _ExtraOptionsScreenState extends State<ExtraOptionsScreen> {

  @override
  void initState() {
    super.initState();
    setState(() {});
  }

  Future<String> _exportDatabaseToJSON() async {
    String result = await TrackerRepository.instance.exportDatabaseToJSON();
    return result;
  }
  
  Future<void> _importDatabaseFromJSON(BuildContext context) async {
    // Show the loading dialog
    UIHelper.showLoadingDialog(context);

    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
    if (result != null) {
      String filePath = result.files.single.path!;
      await TrackerRepository.instance.replaceDatabaseFromJSON(filePath);

      // Dismiss the loading dialog
      Navigator.of(context).pop();

      // Show success message
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Import Complete'),
            content: const Text('Database successfully imported!'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(), // Dismisses the dialog
                child: const Text('Close'),
              ),
            ],
          );
        },
      );
    } else {
      // Dismiss the loading dialog
      Navigator.of(context).pop();

      // Show cancellation message
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('File selection cancelled.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    List<TrackerType> trackerTypes = TrackerType.values;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Extra options'),
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
          ElevatedButton(
            onPressed: () async {
              String result = await _exportDatabaseToJSON();
              if (!mounted) return;
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Created back-up'),
                    content: Text('Success: $result'),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false), // Dismisses the dialog and returns false
                        child: const Text('Close'),
                      ),
                    ],
                  );
                },
              );
            },
            child: const Text('Create back-up'),
          ),          
          ElevatedButton(
            onPressed: () => _importDatabaseFromJSON(context),
            child: const Text('Import Database'),
          ),
        ],
      ),
    );
  }
}
