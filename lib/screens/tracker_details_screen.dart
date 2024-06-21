import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:life_tracker/services/tracker_service.dart';
import '../entities/tracker.dart';
import '../entities/tracker_details.dart';
import '../entities/occurrence.dart';
import '../widgets/app_drawer.dart';
import '../repositories/tracker_repository.dart';
import '../helpers/statistics_helper.dart';
import '../services/occurrence_service.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
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
      List<Occurrence> occurrences =
          await TrackerRepository.instance.getOccurrencesByTrackerId(trackerId);
      setState(() {
        _occurrences = occurrences;
      });
    }
  }

  Future<List<FlSpot>> getLineChartData(trackerId) async {
    DateTime filterDate = DateTime.now().subtract(Duration(days: 29));
    DateTime filterDateEnd = DateTime.now(); // might modify at some point
    // Filtering the list
    List<Occurrence> filteredOccurrences = _occurrences.where((occurrence) {
      return occurrence.datetime.isAfter(filterDate);
    }).toList();

    if (filteredOccurrences.isEmpty) {
      return [];
    }

    int numberOfDays = filterDateEnd.difference(filterDate).inDays + 1;

    if (_tracker?.type == TrackerType.timer) {
      List<int> occurrenceDurationsByDay = StatisticsHelper()
          .binOccurrenceDurationsByDay(
              filteredOccurrences, filterDate, DateTime.now());

      return List.generate(occurrenceDurationsByDay.length, (index) {
        // Create a FlSpot for each hour with the number of occurrences
        return FlSpot(
            index.toDouble() + 1.5, occurrenceDurationsByDay[index].toDouble());
      });
    } else if (_tracker?.type == TrackerType.monitor) {
      // If there was an occurrence before the filterDate, interpolate that value so we can start the graph with that value
      List<Occurrence> oc = _occurrences
          .map((item) => item.copy(item.id, item.trackerId, item.datetime,
              item.endTime, item.text, item.value))
          .toList();
      oc.sort((a, b) => a.datetime.compareTo(b.datetime));
      // Find the latest occurrence before the filterDate
      Occurrence? occurrenceBeforeFilterDate = oc
              .where((occurrence) => occurrence.datetime.isBefore(filterDate))
              .toList()
              .isNotEmpty
          ? oc
              .where((occurrence) => occurrence.datetime.isBefore(filterDate))
              .last
          : null;
      Occurrence? occurrenceAfterFilterDate = oc
              .where((occurrence) => occurrence.datetime.isAfter(filterDate))
              .toList()
              .isNotEmpty
          ? oc
              .where((occurrence) => occurrence.datetime.isAfter(filterDate))
              .first
          : null;

      double interpolateDateValue = 0;
      if (occurrenceBeforeFilterDate != null &&
          occurrenceAfterFilterDate != null) {
        interpolateDateValue = StatisticsHelper().interpolateDateValue(
            occurrenceBeforeFilterDate, occurrenceAfterFilterDate, filterDate);
      }

      List<FlSpot> chartData = [FlSpot(1, interpolateDateValue)];

      chartData.addAll(List.generate(filteredOccurrences.length, (index) {
        double idx = filterDateEnd
                .difference(filteredOccurrences[index].datetime)
                .inSeconds /
            (60 * 60 * 24);
        double val = filteredOccurrences[index].value != null
            ? filteredOccurrences[index].value!
            : 0;
        return FlSpot(numberOfDays - idx - 0.5,
            val); // 0.5 is the offset to make sure 12:00 is visually in the middle of a day.
      }).reversed);
      return chartData;
    } else {
      List<int> occurrencesByDay = StatisticsHelper()
          .binOccurrencesByDay(filteredOccurrences, filterDate, DateTime.now());
      return List.generate(occurrencesByDay.length, (index) {
        return FlSpot(
            index.toDouble() + 1.5, occurrencesByDay[index].toDouble());
      });
    }
  }

  List<FlSpot> getLineChartDataWeekend(maxYValue) {
    DateTime filterDate = DateTime.now().subtract(Duration(days: 30));
    DateTime filterDateEnd = DateTime.now(); // might modify at some point

    int numberOfDays = filterDateEnd.difference(filterDate).inDays + 1;

    bool isWeekend =
        filterDate.add(Duration(days: 1)).weekday == DateTime.saturday ||
            filterDate.weekday == DateTime.sunday;
    List<FlSpot> spots = [FlSpot(1, isWeekend ? maxYValue : 0.0)];

    double previousValue = isWeekend ? maxYValue : 0.0;
    for (int i = 1; i < numberOfDays; i++) {
      DateTime date = filterDate.add(Duration(days: i + 1));
      bool isWeekend =
          date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
      spots.add(FlSpot(i.toDouble(),
          previousValue)); // So that the bar chart is straight; add 0.5 offset so bars are actually centered on the weekends
      spots.add(FlSpot(i.toDouble(), isWeekend ? maxYValue : 0.0));
      previousValue = isWeekend ? maxYValue : 0.0;
    }

    return spots;
  }

  Map<int, String> getMondayLabels() {
    Map<int, String> labels = {};
    DateTime filterDate = DateTime.now().subtract(Duration(days: 30));
    DateTime filterDateEnd = DateTime.now(); // might modify at some point
    int numberOfDays = filterDateEnd.difference(filterDate).inDays + 1;

    for (int i = 0; i < numberOfDays - 1; i++) {
      DateTime date = filterDate.add(Duration(days: i + 1));
      if (date.weekday == DateTime.monday) {
        labels[i] = DateFormat('MMM d').format(date);
      }
    }

    return labels;
  }

  void _showManualEntryDialog({Occurrence? occurrence}) {
    DateTime selectedDateTime = occurrence?.datetime ?? DateTime.now();
    String textInput = occurrence?.text ?? '';
    int durationInput = occurrence?.getDurationInMinutes() ?? 0;
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
                  Text(DateFormat('yyyy-MM-dd – kk:mm')
                      .format(selectedDateTime)),
                  // Additional input fields based on tracker type
                  if (widget.trackerDetails?.type == TrackerType.timer)
                    TextField(
                      decoration: const InputDecoration(
                          labelText: 'Duration (minutes)'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*')),
                      ],
                      onChanged: (value) {
                        durationInput = int.tryParse(value) ?? 0;
                      },
                      controller:
                          TextEditingController(text: durationInput.toString()),
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
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*[\.,]?\d*')),
                      ],
                      onChanged: (value) {
                        numericInput = double.tryParse(value) ?? 0.0;
                      },
                      controller:
                          TextEditingController(text: numericInput.toString()),
                    ),
                ],
              );
            },
          ),
          actions: <Widget>[
            if (occurrence !=
                null) // Show delete button only for existing occurrences
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
                  _addManualEntry(
                      selectedDateTime, textInput, durationInput, numericInput);
                } else {
                  _updateManualEntry(occurrence.id, selectedDateTime, textInput,
                      durationInput, numericInput);
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
              content: const Text(
                  'Are you sure you want to delete this occurrence?'),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context)
                      .pop(false), // Return false if the user cancels
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context)
                      .pop(true), // Return true if the user confirms
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        ) ??
        false; // Return false if the dialog is dismissed without any selection
  }

  void _addManualEntry(
      DateTime dateTime, String text, int duration, double value) async {
    if (_tracker == null) {
      return;
    }
    Tracker tracker = _tracker!;
    switch (tracker.type) {
      case TrackerType.counter:
        await TrackerService().addOccurrence(tracker, datetime: dateTime);
      case TrackerType.timer:
        await TrackerService().addOccurrenceTimer(tracker, startTime: dateTime);
        DateTime endTime = dateTime.add(Duration(minutes: duration));
        await TrackerService().addOccurrenceTimerEnd(tracker, endTime: endTime);
      case TrackerType.text:
        await TrackerService()
            .addOccurrenceText(tracker, text, startTime: dateTime);
      case TrackerType.monitor:
        await TrackerService()
            .addOccurrenceMonitor(tracker, value, startTime: dateTime);
      default:
    }
  }

  void _updateManualEntry(int occurrenceId, DateTime datetime, String text,
      int duration, double value) async {
    if (_tracker == null) {
      return;
    }
    Tracker tracker = _tracker!;
    switch (tracker.type) {
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
                if (widget.trackerDetails?.type == TrackerType.counter)
                  _buildPeriodicInfoTableCounter(),
                if (widget.trackerDetails?.type == TrackerType.timer)
                  _buildPeriodicInfoTableTimer(),
                if (widget.trackerDetails?.type == TrackerType.counter ||
                    widget.trackerDetails?.type == TrackerType.timer)
                  Divider(height: 32),
                if (widget.trackerDetails?.type !=
                    TrackerType
                        .text) // I know, I should wrap these in one if block
                  Text('Past 4 weeks:', textScaleFactor: 1.3),
                if (widget.trackerDetails?.type != TrackerType.text)
                  Divider(height: 12, thickness: 0.01),
                if (widget.trackerDetails?.type != TrackerType.text)
                  _buildChart(trackerId),
                if (widget.trackerDetails?.type != TrackerType.text)
                  Divider(height: 32),
                ElevatedButton(
                  onPressed: _showManualEntryDialog,
                  child: Text('Add Manual Entry'),
                ),
                _buildOccurrencesTable(),
              ],
            ),
          ),
        ));
  }

  Widget _buildChart(trackerId) {
    return Container(
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
              minX: 1,
              maxX: 30,
              // A grid behind the graph
              gridData: FlGridData(show: false),
              // Enable the border
              borderData: FlBorderData(show: true),
              // Setup your titles here...
              titlesData: FlTitlesData(
                bottomTitles: SideTitles(
                  showTitles: true,
                  getTitles: (value) {
                    Map<int, String> mondayLabels = getMondayLabels();
                    return mondayLabels[value.toInt()] ?? '';
                  },
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
                  interval: (maxYValue / 6).round().toDouble() != 0 ? (maxYValue / 6).round().toDouble() : 1,
                  reservedSize:
                      maxYValue >= 100 ? 20 : (maxYValue >= 10 ? 12 : 4),
                  margin: maxYValue >= 100 ? 12 : (maxYValue >= 10 ? 12 : 10),
                ),
              ),
              // The line bars data
              lineBarsData: [
                LineChartBarData(
                  spots: snapshot.data!,
                  isCurved: true, // Optional, if you want a curved line
                  curveSmoothness: 0.2,
                  preventCurveOverShooting: true,
                  isStrokeCapRound: false,
                  colors: [Colors.blue],
                  barWidth: 2,
                  dotData: FlDotData(show: false), // Show the dots on the line
                  belowBarData: BarAreaData(
                      show: true,
                      colors: [Colors.blue.shade50]), // No fill below the line
                ),
                LineChartBarData(
                  // A fake bar chart rod data that spans the entire Y-axis height
                  // to act as the background for "night" times
                  spots: getLineChartDataWeekend(maxYValue),
                  isCurved: false,
                  colors: [
                    Colors.grey.withOpacity(0.9)
                  ], // Dark color for the "night" time
                  barWidth: double
                      .infinity, // Make the bar cover the entire chart width
                  isStrokeCapRound: true,
                  dotData: FlDotData(show: false), // Do not show dots
                  belowBarData: BarAreaData(
                    show: true,
                    colors: [Colors.grey.withOpacity(0.2)],
                  ),
                ),
              ], // Define extra lines
              // extraLinesData: ExtraLinesData(
              //   // Add a vertical line
              //   verticalLines: [
              //     VerticalLine(
              //       // Assuming your x-axis is hours of the day, set the x value to the current hour
              //       x: DateTime.now().hour.toDouble()+24,
              //       // Style the line
              //       color: Colors.red,
              //       strokeWidth: 2,
              //       // Optionally, add a dash pattern for the line
              //       dashArray: [5, 5],
              //     ),
              //     VerticalLine(
              //       // Assuming your x-axis is hours of the day, set the x value to the current hour
              //       x: 24,
              //       // Style the line
              //       color: Colors.black,
              //       strokeWidth: 2,
              //     ),
              //   ],
              //   // You can also define horizontalLines if needed
              // ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPeriodicInfoTableCounter() {
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Name: ${_tracker?.name}',
              style: Theme.of(context).textTheme.headline6),
          SizedBox(height: 8),
          Text('Unit: ${_tracker?.unit}',
              style: Theme.of(context).textTheme.subtitle1),
          SizedBox(height: 8),
          Text('Occurrences Today: ${widget.trackerDetails?.occurrencesToday}'),
          Text(
              'Occurrences Yesterday: ${widget.trackerDetails?.occurrencesYesterday}'),
          Text(
              'Occurrences This Week: ${widget.trackerDetails?.occurrencesThisWeek}'),
          Text(
              'Occurrences This Month: ${widget.trackerDetails?.occurrencesThisMonth}'),
          Text(
              'Occurrences This Year: ${widget.trackerDetails?.occurrencesThisYear}'),
          Text('Occurrences Total: ${widget.trackerDetails?.occurrencesTotal}'),
        ]);
  }

  Widget _buildPeriodicInfoTableTimer() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getDurations(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData) {
          return Center(child: Text('No data available'));
        } else {
          var data = snapshot.data!;
          return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Name: ${_tracker?.name}',
                    style: Theme.of(context).textTheme.headline6),
                SizedBox(height: 8),
                Text('Unit: time',
                    style: Theme.of(context).textTheme.subtitle1),
                SizedBox(height: 8),
                Text(
                    'Today: ${data['durationToday'] <= 60 ? data['durationToday'] : (data['durationToday'] / 60).toStringAsFixed(1)} ${data['durationToday'] <= 60 ? 'minutes' : 'hours'}'),
                Text(
                    'Yesterday: ${data['durationYesterday'] <= 60 ? data['durationYesterday'] : (data['durationYesterday'] / 60).toStringAsFixed(1)} ${data['durationYesterday'] <= 60 ? 'minutes' : 'hours'}'),
                Text(
                    'This Week: ${data['durationThisWeek'] <= 60 ? data['durationThisWeek'] : (data['durationThisWeek'] / 60).toStringAsFixed(0)} ${data['durationThisWeek'] <= 60 ? 'minutes' : 'hours'}'),
                Text(
                    'This Month: ${data['durationThisMonth'] <= 60 ? data['durationThisMonth'] : (data['durationThisMonth'] / 60).toStringAsFixed(0)} ${data['durationThisMonth'] <= 60 ? 'minutes' : 'hours'}'),
                Text(
                    'This Year: ${data['durationThisYear'] <= 60 ? data['durationThisYear'] : (data['durationThisYear'] / 60).toStringAsFixed(0)} ${data['durationThisYear'] <= 60 ? 'minutes' : 'hours'}'),
                Text(
                    'Total: ${data['durationAllTime'] <= 60 ? data['durationAllTime'] : (data['durationAllTime'] / 60).toStringAsFixed(0)} ${data['durationAllTime'] <= 60 ? 'minutes' : 'hours'}'),
              ]);
        }
      },
    );
  }

  Future<Map<String, dynamic>> _getDurations() async {
    DateTime now = DateTime.now();
    DateTime todayEnd = new DateTime(now.year, now.month, now.day, 23, 59, 59);
    DateTime todayStart = new DateTime(now.year, now.month, now.day, 0, 0, 0);
    DateTime yesterdayStart =
        new DateTime(now.year, now.month, now.day, 0, 0, 0)
            .subtract(Duration(days: 1));
    DateTime yesterdayEnd = new DateTime(now.year, now.month, now.day, 0, 0, 0);
    DateTime weekStart = new DateTime(now.year, now.month, now.day, 0, 0, 0)
        .subtract(Duration(days: now.weekday));
    DateTime monthStart = new DateTime(now.year, now.month, 1, 0, 0, 0);
    DateTime yearStart = new DateTime(now.year, 1, 1, 0, 0, 0);
    DateTime epochStart = DateTime.fromMillisecondsSinceEpoch(0);

    return {
      'durationToday': await OccurrenceService()
          .getDurationMinutes(_occurrences, todayStart, todayEnd),
      'durationYesterday': await OccurrenceService()
          .getDurationMinutes(_occurrences, yesterdayStart, yesterdayEnd),
      'durationThisWeek': await OccurrenceService()
          .getDurationMinutes(_occurrences, weekStart, todayEnd),
      'durationThisMonth': await OccurrenceService()
          .getDurationMinutes(_occurrences, monthStart, todayEnd),
      'durationThisYear': await OccurrenceService()
          .getDurationMinutes(_occurrences, yearStart, todayEnd),
      'durationAllTime': await OccurrenceService()
          .getDurationMinutes(_occurrences, epochStart, todayEnd)
    };
  }

  Widget _buildOccurrencesTable() {
    if (_occurrences.isEmpty) {
      return Center(child: Text('No occurrences available'));
    }

    return Table(
      //border: TableBorder.all(),
      columnWidths: {
        0: widget.trackerDetails?.type == TrackerType.counter
            ? FlexColumnWidth(100)
            : IntrinsicColumnWidth(),
        1: widget.trackerDetails?.type != TrackerType.counter
            ? FlexColumnWidth()
            : IntrinsicColumnWidth(),
        2: IntrinsicColumnWidth()
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: _buildRows(),
    );
  }

  TableRow _buildHeader() {
    List<TableCell> cells = [
      TableCell(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 8, 0),
          child: RichText(
        text: TextSpan(
          text: "Date time",
          style: Theme.of(context).textTheme.titleSmall?.copyWith(),
        ),
      )))
    ];

    if (widget.trackerDetails?.type == TrackerType.timer) {
      cells.add(TableCell(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 8, 0),
          child: Center(
              child: RichText(
                text: TextSpan(
                  text: "Minutes",
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(),
        ),
      )))));
    } else if (widget.trackerDetails?.type == TrackerType.text) {
      cells.add(TableCell(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 8, 0),
          child: Center(
              child: RichText(
                text: TextSpan(
                  text: "Text",
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(),
        ),
      )))));
    } else if (widget.trackerDetails?.type == TrackerType.monitor) {
      cells.add(TableCell(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 8, 0),
          child: Center(
              child: RichText(
                text: TextSpan(
                  text: "Value",
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(),
        ),
      )))));
    }

    cells.add(TableCell(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 8, 0),
        child: RichText(
          text: TextSpan(
            text: "Actions",
            style: Theme.of(context).textTheme.titleSmall?.copyWith(),
      ),
    ))));

    TableRow tableRow = TableRow(children: cells);
    return tableRow;
  }

  List<TableRow> _buildRows() {
    List<TableRow> tableHeader = [_buildHeader()];

    List<TableRow> tableRows = _occurrences.map((occurrence) {
      return TableRow(children: [
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.top,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 8, 16),
              child: RichText(
                  text: TextSpan(children: [
                    TextSpan(
                      text: DateFormat("''yy MMM dd").format(occurrence.datetime) + 
                        (widget.trackerDetails?.type == TrackerType.text ? "\n\r" : "  "),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(),
                ),
                TextSpan(
                  text: DateFormat("HH:mm:ss").format(occurrence.datetime),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                )
              ]))),
        ),
        if (widget.trackerDetails?.type == TrackerType.timer)
          TableCell(
            verticalAlignment: TableCellVerticalAlignment.top,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 8, 16),
              child: Center(
                child: RichText(
                  text: TextSpan(children: [
                    TextSpan(
                      text: occurrence.getDurationInMinutes().toString(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(),
                )]),
                )
          ))),
        if (widget.trackerDetails?.type == TrackerType.text)
          TableCell(
            verticalAlignment: TableCellVerticalAlignment.top,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 8, 16),
              child: Center(
            child: Text(occurrence.text ?? 'N/A'),
          ))),
        if (widget.trackerDetails?.type == TrackerType.monitor)
          TableCell(
            verticalAlignment: TableCellVerticalAlignment.top,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 8, 16),
              child: Center(
            child: Text(occurrence.value.toString()),
          ))),
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.top,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
            child: IconButton(
              icon: Icon(Icons.more_vert),
              onPressed: () {
                _showManualEntryDialog(occurrence: occurrence);
              },
            ),
          ),
        )
      ]);
    }).toList();

    tableHeader.addAll(tableRows);

    return tableHeader;
  }
}
