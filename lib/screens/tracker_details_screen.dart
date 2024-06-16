import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:life_tracker/services/tracker_service.dart';
import '../entities/tracker.dart';
import '../entities/tracker_details.dart';
import '../entities/occurrence.dart';
import '../widgets/app_drawer.dart';
import '../repositories/tracker_repository.dart';
import '../helpers/date_helper.dart';
import '../helpers/statistics_helper.dart';
import 'package:intl/intl.dart';
import 'dart:math';

class TrackerDetailsScreen extends StatefulWidget {
  final TrackerDetails? trackerDetails;
  final int? trackerId;

  const TrackerDetailsScreen({super.key, this.trackerDetails, this.trackerId});

  @override
  _TrackerDetailsScreenState createState() => _TrackerDetailsScreenState();
}

class _TrackerDetailsScreenState extends State<TrackerDetailsScreen> {
  List<Occurrence> _occurrences = [];
  Tracker? _tracker;

  @override
  void initState() {
    super.initState();
    _getTracker();
    _getOccurrences();
  }

  Future<void> _getTracker() async {
    final trackerId = widget.trackerDetails?.id;
    if (trackerId != null) {
      Tracker? tracker = await TrackerService().getTracker(trackerId);
      setState(() {
        _tracker = tracker;
      });
    }
  }
  Future<void> _getOccurrences() async {
    final trackerId = widget.trackerDetails?.id;
    if (trackerId != null) {
      List<Occurrence> occurrences = await TrackerRepository.instance.getOccurrencesByTrackerId(trackerId);
      setState(() {
        _occurrences = occurrences;
      });
    }
  }

  Future<List<FlSpot>> getLineChartData(trackerId) async{
    String dateYesterdayStart = DateHelper().getDateYesterdayStart();
    String dateTodayEnd = DateHelper().getDateTodayEnd();
    List<Map<String, dynamic>> todayOccurrences = await TrackerRepository.instance
        .getOccurrencesForTrackerByDate(trackerId, dateYesterdayStart, dateTodayEnd);

    List<int> occurrencesByHour = StatisticsHelper().binOccurrencesByHour(todayOccurrences, DateTime.parse(dateYesterdayStart), DateTime.parse(dateTodayEnd));
    
    return List.generate(occurrencesByHour.length, (index) {
      // Create a FlSpot for each hour with the number of occurrences
      return FlSpot(index.toDouble(), occurrencesByHour[index].toDouble());
    });
  }

  void _showManualEntryDialog({Occurrence? occurrence}) {
    DateTime selectedDateTime = occurrence?.time ?? DateTime.now();
    String textInput = occurrence?.text ?? '';
    int durationInput = 0;
    double numericInput = occurrence?.value ?? 0.0;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(occurrence == null ? 'Add Manual Entry' : 'Edit Entry'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      final DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: selectedDateTime,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2101),
                      );
                      if (pickedDate != null) {
                        final TimeOfDay? pickedTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(selectedDateTime),
                        );
                        if (pickedTime != null) {
                          setState(() {
                            selectedDateTime = DateTime(
                              pickedDate.year,
                              pickedDate.month,
                              pickedDate.day,
                              pickedTime.hour,
                              pickedTime.minute,
                            );
                          });
                        }
                      }
                    },
                    child: Text('Select Date & Time'),
                  ),
                  const Divider(height: 32),
                  Text(DateFormat('yyyy-MM-dd – kk:mm').format(selectedDateTime)),
                  // Additional input fields based on tracker type
                  if (widget.trackerDetails?.type == TrackerType.timer)
                    TextField(
                      decoration: const InputDecoration(labelText: 'Duration (minutes)'),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        durationInput = int.tryParse(value) ?? 0;
                      },
                    ),
                  if (widget.trackerDetails?.type == TrackerType.text)
                    TextField(
                      decoration: const InputDecoration(labelText: 'Text'),
                      onChanged: (value) {
                        textInput = value;
                      },
                      controller: TextEditingController(text: textInput),
                    ),
                  if (widget.trackerDetails?.type == TrackerType.monitor)
                    TextField(
                      decoration: const InputDecoration(labelText: 'Value'),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      onChanged: (value) {
                        numericInput = double.tryParse(value) ?? 0.0;
                      },
                      controller: TextEditingController(text: numericInput.toString()),
                    ),
                ],
              );
            },
          ),
          actions: <Widget>[
              if (occurrence != null) // Show delete button only for existing occurrences
                TextButton(
                  onPressed: () async {
                    bool confirmed = await _showDeleteConfirmationDialog();
                    if (confirmed) {
                      _deleteEntry(occurrence.id);
                      Navigator.of(context).pop(); // Close the original dialog
                      _refreshScreen(); // Refresh the screen after deletion
                    }
                  },
                  child: const Text('Delete'),
                ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (occurrence == null) {
                  _addManualEntry(selectedDateTime, textInput, durationInput, numericInput);
                } else {
                  _updateManualEntry(occurrence.id, selectedDateTime, textInput, durationInput, numericInput);
                }
                _refreshScreen(); // Refresh the screen after closing the dialog
                Navigator.of(context).pop();
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _showDeleteConfirmationDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this occurrence?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // Return false if the user cancels
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true), // Return true if the user confirms
              child: const Text('Delete'),
            ),
          ],
        );
      },
    ) ?? false; // Return false if the dialog is dismissed without any selection
  }

  void _addManualEntry(DateTime dateTime, String text, int duration, double value) async {
    if(_tracker == null){
      return;
    }
    Tracker tracker = _tracker!;
    switch(tracker.type){
      case TrackerType.counter:
        await TrackerService().addOccurrence(tracker, datetime: dateTime);
      case TrackerType.timer:
        await TrackerService().addOccurrenceTimer(tracker, startTime: dateTime);
        DateTime endTime = dateTime.add(Duration(minutes: duration));
        await TrackerService().addOccurrenceTimerEnd(tracker, endTime: endTime);
      case TrackerType.text:
        await TrackerService().addOccurrenceText(tracker, text, startTime: dateTime);
      case TrackerType.monitor:
        await TrackerService().addOccurrenceMonitor(tracker, value, startTime: dateTime);
      default:
    }
  }  
  
  void _updateManualEntry(int occurrenceId, DateTime datetime, String text, int duration, double value) async {
    if(_tracker == null){
      return;
    }
    Tracker tracker = _tracker!;
    switch(tracker.type){
      case TrackerType.counter:
        TrackerService().updateOccurrence(occurrenceId, datetime);
      case TrackerType.timer:
        DateTime endTime = datetime.add(Duration(minutes: duration));
        TrackerService().updateOccurrenceTimer(occurrenceId, datetime, endTime);
      case TrackerType.text:
        TrackerService().updateOccurrenceText(occurrenceId, datetime, text);
      case TrackerType.monitor:
        TrackerService().updateOccurrenceMonitor(occurrenceId, datetime, value);
      default:
    }
  }

  void _deleteEntry(int occurrenceId) async {
    TrackerService().deleteOccurrence(occurrenceId);
  }

  void _refreshScreen() {
    _getTracker();
    _getOccurrences();
  }

  @override
  Widget build(BuildContext context) {
    final trackerId = widget.trackerDetails?.id ?? 0;
    return Scaffold(
     appBar: AppBar(
       title: Text('Tracker Details'),
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Name: ${widget.trackerDetails?.name}', style: Theme.of(context).textTheme.headline6),
              SizedBox(height: 8),
              Text('Unit: ${widget.trackerDetails?.unit}', style: Theme.of(context).textTheme.subtitle1),
              Divider(height: 32),
              Text('Occurrences Today: ${widget.trackerDetails?.occurrencesToday}'),
              Text('Occurrences Yesterday: ${widget.trackerDetails?.occurrencesYesterday}'),
              Text('Occurrences This Week: ${widget.trackerDetails?.occurrencesThisWeek}'),
              Text('Occurrences This Month: ${widget.trackerDetails?.occurrencesThisMonth}'),
              Text('Occurrences This Year: ${widget.trackerDetails?.occurrencesThisYear}'),
              Text('Occurrences Total: ${widget.trackerDetails?.occurrencesTotal}'),
              Divider(height: 32),
              ElevatedButton(
                onPressed: _showManualEntryDialog,
                child: Text('Add Manual Entry'),
              ),
              Divider(height: 32),
              Container(
                height: 200,
                child: FutureBuilder<List<FlSpot>>(
                  future: getLineChartData(trackerId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error loading histogram data'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(child: Text('No histogram data available'));
                    }    
                    
                    // Find the maximum y-value in your data
                    double maxYValue = snapshot.data!
                        .map((spot) => spot.y)
                        .reduce(max); // Use 'max' from 'dart:math'
                    maxYValue = maxYValue + 1;

                    // Once the data is available, build the BarChart
                    return LineChart(
                      LineChartData(
                        maxY: maxYValue,
                        minY: 0,
                        minX: 0,
                        maxX: 48,
                        // A grid behind the graph
                        gridData: FlGridData(show: false),
                        // Enable the border
                        borderData: FlBorderData(show: true),
                        // Setup your titles here...
                        titlesData: FlTitlesData(    
                          bottomTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30, // Adjust the space for titles if necessary
                            getTitles: (value) {
                              // Assuming that value 12 represents the midpoint of yesterday
                              // and value 36 represents the midpoint of today
                              switch (value.toInt()) {
                                case 12:
                                  return 'Yesterday';
                                case 36:
                                  return 'Today';
                                default:
                                  return ''; // Returning an empty string will not draw any title
                              }
                            },
                            // Styling for the titles
                            getTextStyles: (context, value) => const TextStyle(
                              color: Color(0xff68737d),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            margin: 10, // Space between the axis and titles
                          ),
                          // Left titles (y-axis)
                          leftTitles: SideTitles(
                            showTitles: true,
                            // Adjust reservedSize to control the space for y-axis titles
                            reservedSize: 0, // Decrease if necessary
                            // ... other SideTitles settings for leftTitles
                          ),
                        ),
                        // The line bars data
                        lineBarsData: [
                          LineChartBarData(
                            spots: snapshot.data!,
                            isCurved: true, // Optional, if you want a curved line
                            curveSmoothness: 0.2,
                            preventCurveOverShooting: true,
                            isStrokeCapRound: true,
                            colors: [Colors.grey],
                            barWidth: 4,
                            dotData: FlDotData(show: false), // Show the dots on the line
                            belowBarData: BarAreaData(show: true, colors: [Colors.grey]), // No fill below the line
                          ),
                          LineChartBarData(
                            // A fake bar chart rod data that spans the entire Y-axis height
                            // to act as the background for "night" times
                            spots: [
                              FlSpot(0, maxYValue),
                              FlSpot(6, maxYValue),
                              FlSpot(6, 0),
                              FlSpot(18, 0),
                              FlSpot(18, maxYValue),
                              FlSpot(30, maxYValue),
                              FlSpot(30, 0),
                              FlSpot(42, 0), 
                              FlSpot(42, maxYValue),
                              FlSpot(48, maxYValue),
                            ],
                            isCurved: false,
                            colors: [Colors.grey.withOpacity(0.9)], // Dark color for the "night" time
                            barWidth: double.infinity, // Make the bar cover the entire chart width
                            isStrokeCapRound: true,
                            dotData: FlDotData(show: false), // Do not show dots
                            belowBarData: BarAreaData(
                              show: true,
                              colors: [Colors.grey.withOpacity(0.2)],
                            ),
                          ),
                        ],  // Define extra lines
                        extraLinesData: ExtraLinesData(
                          // Add a vertical line
                          verticalLines: [
                            VerticalLine(
                              // Assuming your x-axis is hours of the day, set the x value to the current hour
                              x: DateTime.now().hour.toDouble()+24,
                              // Style the line
                              color: Colors.red,
                              strokeWidth: 2,
                              // Optionally, add a dash pattern for the line
                              dashArray: [5, 5],
                            ),
                            VerticalLine(
                              // Assuming your x-axis is hours of the day, set the x value to the current hour
                              x: 24,
                              // Style the line
                              color: Colors.black,
                              strokeWidth: 2,
                            ),
                          ],
                          // You can also define horizontalLines if needed
                        ),
                      ),
                    );
                  },
                ),
              ),
              Divider(height: 32),
              _buildOccurrencesTable(),
            ],
          ),
        ),
      )
    );
  }

  Widget _buildOccurrencesTable() {
    return _occurrences.isEmpty
        ? Center(child: Text('No occurrences available'))
        : SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: _buildColumns(),
              rows: _buildRows(),
            ),
          );
  }

  List<DataColumn> _buildColumns() {
    List<DataColumn> columns = [
      DataColumn(label: Text('ID')),
      DataColumn(label: Text('Date Time')),
    ];

    if (widget.trackerDetails?.type == TrackerType.timer) {
      columns.add(DataColumn(label: Text('End Time')));
    } else if (widget.trackerDetails?.type == TrackerType.text) {
      columns.add(DataColumn(label: Text('Text')));
    } else if (widget.trackerDetails?.type == TrackerType.monitor) {
      columns.add(DataColumn(label: Text('Value')));
    }

    columns.add(DataColumn(label: Text('Actions')));

    return columns;
  }

  List<DataRow> _buildRows() {
    return _occurrences.map((occurrence) {
      List<DataCell> cells = [
        DataCell(Text(occurrence.id.toString())),
        DataCell(Text(DateFormat('yyyy-MM-dd HH:mm').format(occurrence.time))),
      ];

      if (widget.trackerDetails?.type == TrackerType.timer) {
        cells.add(DataCell(Text(occurrence.endTime != null
            ? DateFormat('yyyy-MM-dd HH:mm').format(occurrence.endTime!)
            : 'N/A')));
      } else if (widget.trackerDetails?.type == TrackerType.text) {
        cells.add(DataCell(Text(occurrence.text ?? 'N/A')));
      } else if (widget.trackerDetails?.type == TrackerType.monitor) {
        cells.add(DataCell(Text(occurrence.value != null ? occurrence.value.toString() : 'N/A')));
      }

      cells.add(DataCell(IconButton(
        icon: Icon(Icons.more_vert),
        onPressed: () {
          _showManualEntryDialog(occurrence: occurrence);
        },
      )));

      return DataRow(cells: cells);
    }).toList();
  }
}
