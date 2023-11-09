import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../counter.dart';
import '../counter_details.dart';
import '../widgets/app_drawer.dart';
import '../helpers/database_helper.dart';
import '../helpers/date_helper.dart';
import '../helpers/statistics_helper.dart';

class CounterDetailsScreen extends StatefulWidget {
  final CounterDetails? counterDetails;

  const CounterDetailsScreen({super.key, this.counterDetails});

  @override
  _CounterDetailsScreenState createState() => _CounterDetailsScreenState();
}

class _CounterDetailsScreenState extends State<CounterDetailsScreen> {
  @override
  void initState() {
    super.initState();
  }

  Future<List<BarChartGroupData>> getHistogramData(counterId) async{
    String dateYesterdayStart = DateHelper().getDateYesterdayStart();
    String dateTodayEnd = DateHelper().getDateTodayEnd();
    List<Map<String, dynamic>> todayOccurrences = await DatabaseHelper.instance
        .getOccurrencesForCounterByDate(counterId, dateYesterdayStart, dateTodayEnd);

    List<int> occurrencesByHour = StatisticsHelper().binOccurrencesByHour(todayOccurrences, DateTime.parse(dateYesterdayStart), DateTime.parse(dateTodayEnd));
    
    return List.generate(occurrencesByHour.length, (index) {
      return BarChartGroupData(
        x: index, // The x-axis position (can represent the day number)
        barRods: [
          BarChartRodData(
            y: occurrencesByHour[index].toDouble(), // The y-axis value for the bar's height
            colors: [Colors.blue], // The color of the bar
          ),
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final counterId = widget.counterDetails?.id ?? 0;
    return Scaffold(
     appBar: AppBar(
       title: Text('Counter Details'),
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
            Text('Name: ${widget.counterDetails?.name}', style: Theme.of(context).textTheme.headline6),
            SizedBox(height: 8),
            Text('Unit: ${widget.counterDetails?.unit}', style: Theme.of(context).textTheme.subtitle1),
            Divider(height: 32),
            Text('Occurrences Today: ${widget.counterDetails?.occurrencesToday}'),
            Text('Occurrences Yesterday: ${widget.counterDetails?.occurrencesYesterday}'),
            Text('Occurrences This Week: ${widget.counterDetails?.occurrencesThisWeek}'),
            Text('Occurrences This Month: ${widget.counterDetails?.occurrencesThisMonth}'),
            Text('Occurrences This Year: ${widget.counterDetails?.occurrencesThisYear}'),
            Text('Occurrences Total: ${widget.counterDetails?.occurrencesToday}'),
            Divider(height: 32),
            Expanded(
              child: FutureBuilder<List<BarChartGroupData>>(
                future: getHistogramData(counterId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error loading histogram data'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text('No histogram data available'));
                  }

                  // Once the data is available, build the BarChart
                  return LineChart(
                    snapshot.data!,
                      // Configure the rest of your chart styling and data here
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
