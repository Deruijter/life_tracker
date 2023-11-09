import 'package:life_tracker/counter_details.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../location_service.dart';
import 'package:location/location.dart';
import '../counter.dart';
import 'package:intl/intl.dart';
import 'date_helper.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('statistics_tracker.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE counters(
      counter_id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      unit TEXT NOT NULL
    )
    ''');

    await db.execute('''
    CREATE TABLE occurrences(
      occurrence_id INTEGER PRIMARY KEY AUTOINCREMENT,
      counter_id INTEGER,
      datetime DATETIME NOT NULL,
      latitude REAL NULL,
      longitude REAL NULL,
      FOREIGN KEY (counter_id) REFERENCES counters (counter_id)
    )
    ''');
  }

  // Add other database helper methods here...

  Future close() async {
    final db = await instance.database;

    db.close();
  }

  Future addCounter(String name, String unit) async {
    final db = await instance.database;

    // Use a parameterized SQL query to prevent SQL injection.
    var res = await db.rawInsert(
      'INSERT INTO counters (name, unit) VALUES (?, ?)',
      [name, unit], // Use a list to pass parameters.
    );

    return res; // This usually returns the ID of the inserted row.
  }

  Future addOccurrence(int counterId, double? latitude, double? longitude) async {
    final db = await instance.database;

    DateTime now = DateTime.now();
    String nowFormatted = DateFormat('yyyy-MM-dd kk:mm:ss').format(now);

    //LocationData? currentLocation = await LocationService().getLocation();

    print('Adding new occurrence: $counterId; $nowFormatted; $latitude; $longitude');

    // Use a parameterized SQL query to prevent SQL injection.
    var res = await db.rawInsert(
      'INSERT INTO occurrences (counter_id, datetime, latitude, longitude) VALUES (?, ?, ?, ?)',
      [
        counterId,
        nowFormatted,
        latitude, // If currentLocation is null, this evaluates to null
        longitude, // If currentLocation is null, this evaluates to null
      ],
    );


    return res; // This usually returns the ID of the inserted row.
  }

  Future<void> deleteCounterAndOccurrences(int counterId) async {
    final db = await instance.database;

    // Execute a transaction to ensure both operations are completed successfully
    await db.transaction((txn) async {
      // First, delete all occurrences associated with the counter
      await txn.delete(
        'occurrences',
        where: 'counter_id = ?',
        whereArgs: [counterId],
      );
      // Then, delete the counter itself
      await txn.delete(
        'counters',
        where: 'counter_id = ?',
        whereArgs: [counterId],
      );
    });
  }

  Future<void> deleteNewestOccurrence(int counterId) async {
    final db = await instance.database;

    // Execute a transaction to ensure both operations are completed successfully
    await db.transaction((txn) async {
      // First, find the newest occurrence for the counter
      var maxIdResult = await txn.query(
        'occurrences',
        columns: ['MAX(occurrence_id) AS max_id'],
        where: 'counter_id = ?',
        whereArgs: [counterId],
      );

      if (maxIdResult.isNotEmpty && maxIdResult.first['max_id'] != null) {
        int? maxId = maxIdResult.first['max_id'] as int?;
        
        // Then, delete the newest occurrence
        await txn.delete(
          'occurrences',
          where: 'occurrence_id = ?',
          whereArgs: [maxId],
        );
      }
    });
  }

  Future<List<Counter>> getCountersWithOccurrences() async {
    final db = await instance.database;

    // A query to get all counters with their number of occurrences
    // It performs a LEFT JOIN to include counters with zero occurrences
    final result = await db.rawQuery('''
      SELECT c.counter_id, c.name, c.unit, COUNT(o.occurrence_id) as occurrences
      FROM counters c
      LEFT JOIN occurrences o ON c.counter_id = o.counter_id
      GROUP BY c.counter_id
      ORDER BY c.name ASC; // Order alphabetically by counter name
    ''');

    // Map the query results to a list of Counter objects
    List<Counter> counters = result.isNotEmpty
        ? result.map((c) => Counter.fromMap(c)).toList()
        : [];

    return counters;
  }

  Future<CounterDetails> getCounterDetails(counterId) async {
    final db = await instance.database;

    // A query to get all counters with their number of occurrences
    // It performs a LEFT JOIN to include counters with zero occurrences
    final result = await db.rawQuery('''
      SELECT c.counter_id, 
        c.name, 
        c.unit, 
        COUNT(CASE WHEN o.datetime >= ? AND o.datetime <= ? THEN 1 ELSE NULL END) AS occurrences_today,
        COUNT(CASE WHEN o.datetime >= ? AND o.datetime <= ? THEN 1 ELSE NULL END) AS occurrences_yesterday,
        COUNT(CASE WHEN o.datetime >= ? AND o.datetime <= ? THEN 1 ELSE NULL END) AS occurrences_this_week,
        COUNT(CASE WHEN o.datetime >= ? AND o.datetime <= ? THEN 1 ELSE NULL END) AS occurrences_this_month,
        COUNT(CASE WHEN o.datetime >= ? AND o.datetime <= ? THEN 1 ELSE NULL END) AS occurrences_this_year,
        COUNT(*) AS occurrences_total
      FROM counters c
      LEFT JOIN occurrences o ON c.counter_id = o.counter_id
      WHERE c.counter_id == ?
      GROUP BY c.counter_id
      ORDER BY c.name ASC; // Order alphabetically by counter name
    ''',[DateHelper().getDateTodayStart(), DateHelper().getDateTodayEnd(),
    DateHelper().getDateYesterdayStart(), DateHelper().getDateYesterdayEnd(),
    DateHelper().getDateWeekStart(), DateHelper().getDateWeekEnd(),
    DateHelper().getDateMonthStart(), DateHelper().getDateMonthEnd(),
    DateHelper().getDateYearStart(), DateHelper().getDateYearEnd(),
    counterId]);

    // Map the query results to a list of Counter objects
    //CounterDetails counterDetails = result.map((c) => CounterDetails.fromMap(c));
    CounterDetails counterDetails = CounterDetails.fromMap(result.first); // Use first since we should only be getting one record

    return counterDetails;
  }

  Future<List<Counter>> getCountersWithOccurrencesByDate(startDate, endDate) async {
    final db = await instance.database;

    // A query to get all counters with their number of occurrences
    // It performs a LEFT JOIN to include counters with zero occurrences
    final result = await db.rawQuery('''
      SELECT
        c.counter_id,
        c.name,
        c.unit,
        COUNT(CASE WHEN o.datetime >= ? AND o.datetime <= ? THEN 1 ELSE NULL END) AS occurrences
      FROM
        counters c
      LEFT JOIN occurrences o ON c.counter_id = o.counter_id
      GROUP BY
        c.counter_id
      ORDER BY
        c.name ASC;
    ''', [
      startDate,
      endDate,
    ]);

    // Map the query results to a list of Counter objects
    List<Counter> counters = result.isNotEmpty
        ? result.map((c) => Counter.fromMap(c)).toList()
        : [];

    return counters;
  }
  
  Future<int> getCounterOccurrences(counterId) async {
    final db = await instance.database;
    // Use a parameterized query to prevent SQL injection
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS occurrences FROM occurrences WHERE counter_id = ?',
      [counterId], // Passing counterId as a parameter to replace the '?' placeholder
    );
    
    if (result.isNotEmpty) {
      // The result is a list of maps, so we access the first item and then the 'count' key
      return int.tryParse(result.first['occurrences'].toString()) ?? 0;
    } else {
      return 0; // If the result is empty, return 0 occurrences
    }
  }
  
  Future<int> getCounterOccurrencesByDate(counterId, startDate, endDate) async {
    final db = await instance.database;
    // Use a parameterized query to prevent SQL injection
    final result = await db.rawQuery(
      'SELECT COUNT(CASE WHEN datetime >= ? AND datetime <= ? THEN 1 ELSE NULL END) AS occurrences FROM occurrences WHERE counter_id = ?',
      [startDate,
      endDate,
      counterId], // Passing counterId as a parameter to replace the '?' placeholder
    );
    
    if (result.isNotEmpty) {
      // The result is a list of maps, so we access the first item and then the 'count' key
      return int.tryParse(result.first['occurrences'].toString()) ?? 0;
    } else {
      return 0; // If the result is empty, return 0 occurrences
    }
  }

  Future<List<Map<String, dynamic>>> getOccurrencesForCounterByDate(
      int counterId, String startDate, String endDate) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> result = await db.query(
      'occurrences',
      where: 'counter_id = ? AND datetime >= ? AND datetime <= ?',
      whereArgs: [
        counterId,
        startDate,
        endDate,
      ],
    );
    
    return result;
  }
  Future<void> printAllCounters() async {
    final db = await instance.database;
    List<Map<String, dynamic>> allRows = await db.query('counters');
    print('All counters:');
    for (var row in allRows) {
      print(row);
    }
  }  

  Future<void> updateCounter(int id, String name, String unit) async {
    final db = await instance.database;
    await db.update(
      'counters',
      {'name': name, 'unit': unit},
      where: 'counter_id = ?',
      whereArgs: [id],
    );
  }
}
