import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../entities/tracker.dart';
import '../entities/tracker_details.dart';
import '../widgets/app_drawer.dart';
import '../repositories/tracker_repository.dart';
import '../helpers/date_helper.dart';
import '../helpers/statistics_helper.dart';
import 'package:intl/intl.dart';
import 'dart:math';

class TrackerDetailsScreen extends StatefulWidget {
  final TrackerDetails? trackerDetails;

  const TrackerDetailsScreen({super.key, this.trackerDetails});

  @override
  _TrackerDetailsScreenState createState() => _TrackerDetailsScreenState();
}

class _TrackerDetailsScreenState extends State<TrackerDetailsScreen> {
  @override
  void initState() {
    super.initState();
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
      body: Padding(
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
          ],
        ),
      ),
    );
  }
}
