import 'package:life_tracker/entities/tracker_details.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../entities/tracker.dart';
import '../entities/occurrence.dart';
import 'package:intl/intl.dart';
import '../helpers/date_helper.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';

enum TrackerType { counter, timer, text, monitor }
extension TrackerTypeString on String {
  TrackerType get trackerType {
    switch (this) {
      case 'counter':
        return TrackerType.counter;
      case 'timer':
        return TrackerType.timer;
      case 'text':
        return TrackerType.text;
      case 'monitor':
        return TrackerType.monitor;
      default:
        return TrackerType.counter;
    }
  }
}
extension TrackerTypeExtension on TrackerType {
  String get string {
    switch (this) {
      case TrackerType.counter:
        return 'counter';
      case TrackerType.timer:
        return 'timer';
      case TrackerType.text:
        return 'text';
      case TrackerType.monitor:
        return 'monitor';
    }
  }
}

class TrackerRepository {
  static final TrackerRepository instance = TrackerRepository._init();
  static Database? _database;
  TrackerRepository._init();


  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('statistics_tracker.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, 
    version: 2, 
    onCreate: _createDB,
    onUpgrade: (Database db, int oldVersion, int newVersion) async {
      if (oldVersion < 2) {
        // Apply changes needed to upgrade from version 1 to 2
        _updateDBV2(db, newVersion);
      }
      // Add additional checks here for future versions (e.g., oldVersion < 3)
    },);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE trackers(
      tracker_id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT,
      unit TEXT,
      type TEXT NOT NULL
    )
    ''');

    await db.execute('''
    CREATE TABLE occurrences(
      occurrence_id INTEGER PRIMARY KEY AUTOINCREMENT,
      tracker_id INTEGER,
      datetime DATETIME NOT NULL,
      latitude REAL NULL,
      longitude REAL NULL,
      FOREIGN KEY (tracker_id) REFERENCES trackers (tracker_id)
    )
    ''');

    await db.execute('''
    CREATE TABLE occurrences_timer (
        occurrence_id INTEGER PRIMARY KEY,
        end_time DATETIME,
        FOREIGN KEY (occurrence_id) REFERENCES occurrences(occurrence_id)
    )
    ''');

    await db.execute('''
    CREATE TABLE occurrences_text (
        occurrence_id INTEGER PRIMARY KEY,
        text TEXT,
        FOREIGN KEY (occurrence_id) REFERENCES occurrences(occurrence_id)
    )
    ''');

    await db.execute('''
    CREATE TABLE occurrences_monitor (
        occurrence_id INTEGER PRIMARY KEY,
        value REAL NOT NULL,
        FOREIGN KEY (occurrence_id) REFERENCES occurrences(occurrence_id)
    )
    ''');
  }

  Future _updateDBV2(Database db, int version) async {  
    print("updating DB to version 2");
    // UPDATE counters table
    await db.transaction((txn) async {
      // Step 1: Create a new table with the updated schema
      await txn.execute('''
        CREATE TABLE trackers (
          tracker_id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT,
          unit TEXT,
          type TEXT NOT NULL
        )
      ''');

      // Step 2: Copy the data from the old table to the new table
      // Assuming 'tally' as the default value for the existing rows
      await txn.execute('''
        INSERT INTO trackers (tracker_id, name, unit, type)
        SELECT counter_id, name, unit, 'counter' FROM counters
      ''');

      // Step 3: Drop the old table
      await txn.execute('DROP TABLE counters');

      await txn.execute('ALTER TABLE occurrences RENAME COLUMN counter_id TO tracker_id');
    });

    // CREATE new tracker type specific occurrence tables
    await db.execute('''
    CREATE TABLE occurrences_timer (
        occurrence_id INTEGER PRIMARY KEY,
        end_time DATETIME,
        FOREIGN KEY (occurrence_id) REFERENCES occurrences(occurrence_id)
    )
    ''');

    await db.execute('''
    CREATE TABLE occurrences_text (
        occurrence_id INTEGER PRIMARY KEY,
        text TEXT,
        FOREIGN KEY (occurrence_id) REFERENCES occurrences(occurrence_id)
    )
    ''');

    await db.execute('''
    CREATE TABLE occurrences_monitor (
        occurrence_id INTEGER PRIMARY KEY,
        value REAL NOT NULL,
        FOREIGN KEY (occurrence_id) REFERENCES occurrences(occurrence_id)
    )
    ''');
  }

  Future close() async {
    final db = await instance.database;

    db.close();
  }

  Future addTracker(String name, String unit, String type) async {
    final db = await instance.database;

    // Use a parameterized SQL query to prevent SQL injection.
    var res = await db.rawInsert(
      'INSERT INTO trackers (name, unit, type) VALUES (?, ?, ?)',
      [name, unit, type], // Use a list to pass parameters.
    );

    return res;
  }

  Future<int> addOccurrence(int trackerId, DateTime startTime, double? latitude, double? longitude) async {
    final db = await instance.database;

    String startTimeFormatted = startTime.toIso8601String();

    print('Adding new occurrence: $trackerId; $startTimeFormatted; $latitude; $longitude');

    int occurrenceId = 0;
    // Use a parameterized SQL query to prevent SQL injection.
    await db.transaction((txn) async {
      occurrenceId = await txn.rawInsert(
        'INSERT INTO occurrences (tracker_id, datetime, latitude, longitude) VALUES (?, ?, ?, ?)',
        [
          trackerId,
          startTimeFormatted,
          latitude, // If currentLocation is null, this evaluates to null
          longitude, // If currentLocation is null, this evaluates to null
        ],
      );
    });

    return occurrenceId;
  }

  Future<int> addOccurrenceTimerStart(int occurrenceId) async {
    // Technically a timer doesn't have a specific "start time", it just uses the occurrence start time as the start time.
    // However, we still need to add a record in occurrences_timer so the app knows there's a timer in progress
    final db = await instance.database;

    // Use a parameterized SQL query to prevent SQL injection.
    await db.transaction((txn) async {
      await txn.rawInsert(
        'INSERT INTO occurrences_timer (occurrence_id, end_time) VALUES (?, ?)',
        [
          occurrenceId,
          null
        ],
      );
    });
    
    return occurrenceId;
  }

  Future<DateTime> addOccurrenceTimerEnd(int trackerId, DateTime endTime) async {
    final db = await instance.database;

    String endTimeFormatted = endTime.toIso8601String();
    await db.rawUpdate('''UPDATE occurrences_timer
      SET end_time = ?
      WHERE occurrence_id = (
        SELECT occurrence_id
        FROM occurrences
        WHERE tracker_id = ?
        ORDER BY datetime DESC
        LIMIT 1
      );''',[endTimeFormatted, trackerId]);
    return endTime;
  }

  Future<int> addOccurrenceText(int occurrenceId, String text) async {
    final db = await instance.database;

    // Use a parameterized SQL query to prevent SQL injection.
    await db.transaction((txn) async {
      await txn.rawInsert(
        'INSERT INTO occurrences_text (occurrence_id, text) VALUES (?, ?)',
        [
          occurrenceId,
          text
        ],
      );
    });

    return occurrenceId;
  }

  Future<int> addOccurrenceMonitorValue(int occurrenceId, double value) async {
    final db = await instance.database;

    // Use a parameterized SQL query to prevent SQL injection.
    await db.transaction((txn) async {
      await txn.rawInsert(
        'INSERT INTO occurrences_monitor (occurrence_id, value) VALUES (?, ?)',
        [
          occurrenceId,
          value
        ],
      );
    });

    return occurrenceId;
  }

  Future<DateTime> addOccurrenceWithOccurrenceTimerStart(int trackerId, double? latitude, double? longitude) async {
    final db = await instance.database;

    DateTime now = DateTime.now();
    String nowFormatted = now.toIso8601String();

    //LocationData? currentLocation = await LocationService().getLocation();

    print('Adding new timer occurrence: $trackerId; $nowFormatted; $latitude; $longitude');

    // Use a parameterized SQL query to prevent SQL injection.
    await db.transaction((txn) async {
      int occurrenceId = await txn.rawInsert(
        'INSERT INTO occurrences (tracker_id, datetime, latitude, longitude) VALUES (?, ?, ?, ?)',
        [
          trackerId,
          nowFormatted,
          latitude, // If currentLocation is null, this evaluates to null
          longitude, // If currentLocation is null, this evaluates to null
        ],
      );

      await txn.rawInsert(
        'INSERT INTO occurrences_timer (occurrence_id, end_time) VALUES (?, ?)',
        [
          occurrenceId,
          null
        ],
      );
    });

    return now;
  }

  Future<DateTime> addOccurrenceWithOccurrenceText(int trackerId, double? latitude, double? longitude, String text) async {
    final db = await instance.database;

    DateTime now = DateTime.now();
    String nowFormatted = now.toIso8601String();

    //LocationData? currentLocation = await LocationService().getLocation();

    print('Adding new text occurrence: $trackerId; $nowFormatted; $latitude; $longitude; $text');

    // Use a parameterized SQL query to prevent SQL injection.
    await db.transaction((txn) async {
      int occurrenceId = await txn.rawInsert(
        'INSERT INTO occurrences (tracker_id, datetime, latitude, longitude) VALUES (?, ?, ?, ?)',
        [
          trackerId,
          nowFormatted,
          latitude, // If currentLocation is null, this evaluates to null
          longitude, // If currentLocation is null, this evaluates to null
        ],
      );

      await txn.rawInsert(
        'INSERT INTO occurrences_text (occurrence_id, text) VALUES (?, ?)',
        [
          occurrenceId,
          text
        ],
      );
    });

    return now;
  }

  Future<DateTime> addOccurrenceWithOccurrenceMonitor(int trackerId, double? latitude, double? longitude, double value) async {
    final db = await instance.database;

    DateTime now = DateTime.now();
    String nowFormatted = now.toIso8601String();

    //LocationData? currentLocation = await LocationService().getLocation();

    print('Adding new value occurrence: $trackerId; $nowFormatted; $latitude; $longitude; $value');

    // Use a parameterized SQL query to prevent SQL injection.
    await db.transaction((txn) async {
      int occurrenceId = await txn.rawInsert(
        'INSERT INTO occurrences (tracker_id, datetime, latitude, longitude) VALUES (?, ?, ?, ?)',
        [
          trackerId,
          nowFormatted,
          latitude, // If currentLocation is null, this evaluates to null
          longitude, // If currentLocation is null, this evaluates to null
        ],
      );

      await txn.rawInsert(
        'INSERT INTO occurrences_monitor (occurrence_id, value) VALUES (?, ?)',
        [
          occurrenceId,
          value
        ],
      );
    });

    return now;
  }

  Future<DateTime> addOccurrenceWithOccurrenceTimerEnd(int trackerId) async{
    final db = await instance.database;

    DateTime now = DateTime.now();
    String nowFormatted = now.toIso8601String();
    await db.rawUpdate('''UPDATE occurrences_timer
      SET end_time = ?
      WHERE occurrence_id = (
        SELECT occurrence_id
        FROM occurrences
        WHERE tracker_id = ?
        ORDER BY datetime DESC
        LIMIT 1
      );''',[nowFormatted, trackerId]);
    return now;
  }

  void updateOccurrence(int occurrenceId, DateTime datetime) async {
    final db = await instance.database;

    String datetimeFormatted = datetime.toIso8601String();
    await db.rawUpdate('''UPDATE occurrences
      SET datetime = ?
      WHERE occurrence_id = ?''',
      [datetimeFormatted, occurrenceId]);
  }

  void updateOccurrenceTimerEnd(int occurrenceId, DateTime endTime) async {
    final db = await instance.database;

    String endTimeFormatted = endTime.toIso8601String();
    await db.rawUpdate('''UPDATE occurrences_timer
      SET end_time = ?
      WHERE occurrence_id = ?''',
      [endTimeFormatted, occurrenceId]);
  }

  void updateOccurrenceText(int occurrenceId, String text) async {
    final db = await instance.database;

    await db.rawUpdate('''UPDATE occurrences_text
      SET text = ?
      WHERE occurrence_id = ?''',
      [text, occurrenceId]);
  }

  void updateOccurrenceMonitor(int occurrenceId, double value) async {
    final db = await instance.database;

    await db.rawUpdate('''UPDATE occurrences_monitor
      SET value = ?
      WHERE occurrence_id = ?''',
      [value, occurrenceId]);
  }

  Future<void> deleteOccurrence(int occurrenceId) async {
    final db = await instance.database;

    await db.transaction((txn) async {
      // Delete from occurrences_timer if exists
      await txn.delete(
        'occurrences_timer',
        where: 'occurrence_id = ?',
        whereArgs: [occurrenceId],
      );

      // Delete from occurrences_text if exists
      await txn.delete(
        'occurrences_text',
        where: 'occurrence_id = ?',
        whereArgs: [occurrenceId],
      );

      // Delete from occurrences_monitor if exists
      await txn.delete(
        'occurrences_monitor',
        where: 'occurrence_id = ?',
        whereArgs: [occurrenceId],
      );

      // Finally, delete from occurrences
      await txn.delete(
        'occurrences',
        where: 'occurrence_id = ?',
        whereArgs: [occurrenceId],
      );
    });
  }

  Future<void> deleteTrackerAndOccurrences(int trackerId) async {
    final db = await instance.database;

    // Execute a transaction to ensure both operations are completed successfully
    await db.transaction((txn) async {
      // First, delete all occurrences associated with the tracker
      await txn.delete(
        'occurrences',
        where: 'tracker_id = ?',
        whereArgs: [trackerId],
      );
      // Then, delete the tracker itself
      await txn.delete(
        'trackers',
        where: 'tracker_id = ?',
        whereArgs: [trackerId],
      );
    });
  }

  Future<void> deleteNewestOccurrence(int trackerId) async {
    final db = await instance.database;

    // Execute a transaction to ensure both operations are completed successfully
    await db.transaction((txn) async {
      // First, find the newest occurrence for the tracker
      var maxIdResult = await txn.query(
        'occurrences',
        columns: ['MAX(occurrence_id) AS max_id'],
        where: 'tracker_id = ?',
        whereArgs: [trackerId],
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

  Future<List<Tracker>> getTrackersWithOccurrences() async {
    final db = await instance.database;

    // A query to get all trackers with their number of occurrences
    // It performs a LEFT JOIN to include trackers with zero occurrences
    final result = await db.rawQuery('''
      SELECT t.tracker_id, t.name, t.unit, t.type, COUNT(o.occurrence_id) as occurrences
      FROM trackers t
      LEFT JOIN occurrences o ON t.tracker_id = o.tracker_id
      GROUP BY t.tracker_id
      ORDER BY t.name ASC;
    ''');

    // Map the query results to a list of Tracker objects
    List<Tracker> trackers = result.isNotEmpty
        ? result.map((c) => Tracker.fromMap(c)).toList()
        : [];

    return trackers;
  }

    Future<List<Occurrence>> getOccurrencesByTrackerId(int trackerId) async {
    final db = await instance.database;

    // A query to get all trackers with their number of occurrences
    // It performs a LEFT JOIN to include trackers with zero occurrences
    final result = await db.rawQuery('''
      SELECT o.occurrence_id, o.tracker_id, o.datetime, otime.end_time, otext.text, omonitor.value
      FROM occurrences o
      LEFT JOIN occurrences_timer otime ON o.occurrence_id = otime.occurrence_id
      LEFT JOIN occurrences_text otext ON o.occurrence_id = otext.occurrence_id
      LEFT JOIN occurrences_monitor omonitor ON o.occurrence_id = omonitor.occurrence_id
      WHERE o.tracker_id = ?
      ORDER BY o.datetime DESC;
    ''', [trackerId]);

    // Map the query results to a list of Tracker objects
    List<Occurrence> trackers = result.isNotEmpty
        ? result.map((c) => Occurrence.fromMap(c)).toList()
        : [];

    return trackers;
  }

  Future<Tracker> getTrackerWithOccurrences(int trackerId) async {
    final db = await instance.database;

    // A query to get all trackers with their number of occurrences
    // It performs a LEFT JOIN to include trackers with zero occurrences
    final result = await db.rawQuery('''
      SELECT t.tracker_id, t.name, t.unit, t.type, COUNT(o.occurrence_id) as occurrences
      FROM trackers t
      LEFT JOIN occurrences o ON t.tracker_id = o.tracker_id
      WHERE t.tracker_id = ?
      GROUP BY t.tracker_id
      ORDER BY t.name ASC;
    ''', [trackerId]);

    // Map the query results to a list of Tracker objects
    Tracker tracker = Tracker.fromMap(result.first);

    return tracker;
  }

  Future<TrackerDetails> getTrackerDetails(trackerId) async {
    final db = await instance.database;

    // A query to get all trackers with their number of occurrences
    // It performs a LEFT JOIN to include trackers with zero occurrences
    final result = await db.rawQuery('''
      SELECT t.tracker_id, 
        t.name, 
        t.unit, 
        t.type,
        COUNT(CASE WHEN o.datetime >= ? AND o.datetime <= ? THEN 1 ELSE NULL END) AS occurrences_today,
        COUNT(CASE WHEN o.datetime >= ? AND o.datetime <= ? THEN 1 ELSE NULL END) AS occurrences_yesterday,
        COUNT(CASE WHEN o.datetime >= ? AND o.datetime <= ? THEN 1 ELSE NULL END) AS occurrences_this_week,
        COUNT(CASE WHEN o.datetime >= ? AND o.datetime <= ? THEN 1 ELSE NULL END) AS occurrences_this_month,
        COUNT(CASE WHEN o.datetime >= ? AND o.datetime <= ? THEN 1 ELSE NULL END) AS occurrences_this_year,
        COUNT(*) AS occurrences_total
      FROM trackers t
      LEFT JOIN occurrences o ON t.tracker_id = o.tracker_id
      WHERE t.tracker_id == ?
      GROUP BY t.tracker_id
      ORDER BY t.name ASC;
    ''',[DateHelper().getDateTodayStart(), DateHelper().getDateTodayEnd(),
    DateHelper().getDateYesterdayStart(), DateHelper().getDateYesterdayEnd(),
    DateHelper().getDateWeekStart(), DateHelper().getDateWeekEnd(),
    DateHelper().getDateMonthStart(), DateHelper().getDateMonthEnd(),
    DateHelper().getDateYearStart(), DateHelper().getDateYearEnd(),
    trackerId]);

    // Map the query results to a list of Tracker objects
    TrackerDetails trackerDetails = TrackerDetails.fromMap(result.first); // Use first since we should only be getting one record

    return trackerDetails;
  }

  Future<List<Tracker>> getTrackersWithOccurrencesByDate_old(startDate, endDate) async {
    final db = await instance.database;

    // A query to get all trackers with their number of occurrences
    // It performs a LEFT JOIN to include trackers with zero occurrences
    final result = await db.rawQuery('''
      SELECT
        t.tracker_id,
        t.name,
        t.unit,
        t.type,
        COUNT(CASE WHEN o.datetime >= ? AND o.datetime <= ? THEN 1 ELSE NULL END) AS occurrences
      FROM
        trackers t
      LEFT JOIN occurrences o ON t.tracker_id = o.tracker_id
      GROUP BY
        t.tracker_id
      ORDER BY
        t.name ASC;
    ''', [
      startDate,
      endDate,
    ]);

    // Map the query results to a list of Tracker objects
    List<Tracker> trackers = result.isNotEmpty
        ? result.map((c) => Tracker.fromMap(c)).toList()
        : [];

    return trackers;
  }
  

  Future<List<Tracker>> getTrackersWithOccurrencesByDate(startDate, endDate) async {
    final db = await instance.database;

    // Process each tracker and fetch type-specific data
    List<Tracker> trackers = [];
    List<Tracker> counterTrackers = [];
    List<Tracker> timerTrackers = [];
    List<Tracker> textTrackers = [];
    List<Tracker> monitorTrackers = [];
    for (var trackerType in TrackerType.values){
      switch(trackerType){
        case TrackerType.counter:
            final result = await db.rawQuery('''
              SELECT t.tracker_id, t.name, t.unit,t.type,
                COUNT(CASE WHEN o.datetime >= ? AND o.datetime <= ? THEN 1 ELSE NULL END) AS occurrences,
                (
                  SELECT MAX(o2.datetime)
                  FROM occurrences o2 
                  WHERE o2.tracker_id = t.tracker_id 
                ) AS latest_occurrence
              FROM trackers t
              LEFT JOIN occurrences o ON t.tracker_id = o.tracker_id
              WHERE t.type == 'counter'
              GROUP BY t.tracker_id
              ORDER BY t.name ASC;
            ''', [
              startDate,
              endDate,
            ]);
          counterTrackers = result.isNotEmpty
            ? result.map((c) => CounterTracker.fromMap(c)).toList()
            : [];
        case TrackerType.timer:
            final result = await db.rawQuery('''
              SELECT t.tracker_id, t.name, t.unit,t.type,
                COUNT(CASE WHEN o.datetime >= ? AND o.datetime <= ? THEN 1 ELSE NULL END) AS occurrences,
                (
                  SELECT MAX(o2.datetime)
                  FROM occurrences o2 
                  WHERE o2.tracker_id = t.tracker_id 
                ) AS latest_occurrence,
                (
                  SELECT ot.end_time 
                  FROM occurrences_timer ot
                  WHERE ot.occurrence_id = (
                    SELECT occurrence_id 
                    FROM occurrences o3 
                    WHERE o3.tracker_id = t.tracker_id 
                    ORDER BY o3.datetime DESC 
                    LIMIT 1
                  )
                ) AS end_time,
                ( SELECT
                    SUM(
                      JULIANDAY(
                        CASE 
                          WHEN ot3.end_time > ? THEN ? -- End date of range
                          ELSE ot3.end_time 
                        END
                      ) - 
                      JULIANDAY(
                        CASE 
                          WHEN o3.datetime < ? THEN ? -- Start date of range
                          ELSE o3.datetime 
                        END
                      )
                    ) * 24 * 60 AS total_duration_minutes -- Convert days to minutes
                  FROM 
                    occurrences o3
                  INNER JOIN 
                    occurrences_timer ot3 ON o3.occurrence_id = ot3.occurrence_id
                  WHERE 
                    o3.tracker_id = t.tracker_id AND
                    (
                      (o3.datetime BETWEEN ? AND ?) OR
                      (ot3.end_time BETWEEN ? AND ?) OR
                      (o3.datetime < ? AND ot3.end_time > ?)
                    )
                ) AS duration_finished
              FROM trackers t
              LEFT JOIN occurrences o ON t.tracker_id = o.tracker_id
              WHERE t.type == 'timer'
              GROUP BY t.tracker_id
              ORDER BY t.name ASC;
            ''', [
              startDate, endDate, // SELECT occurrences
              endDate, endDate, // SELECT duration end_time
              startDate, startDate, // SELECT duration datetime
              startDate, endDate, // WHERE datetime between
              endDate, endDate, // WHERE end_time between
              startDate, endDate, // WHERE datetime - end_time
            ]);
          timerTrackers = result.isNotEmpty
            ? result.map((c) => TimerTracker.fromMap(c)).toList()
            : [];
        case TrackerType.text:
            final result = await db.rawQuery('''
              SELECT t.tracker_id, t.name, t.unit,t.type,
                COUNT(CASE WHEN o.datetime >= ? AND o.datetime <= ? THEN 1 ELSE NULL END) AS occurrences,
                (
                  SELECT MAX(o2.datetime)
                  FROM occurrences o2 
                  WHERE o2.tracker_id = t.tracker_id 
                ) AS latest_occurrence,
                (
                  SELECT ot.text 
                  FROM occurrences_text ot
                  WHERE ot.occurrence_id = (
                    SELECT occurrence_id 
                    FROM occurrences o2 
                    WHERE o2.tracker_id = t.tracker_id 
                    ORDER BY o2.datetime DESC 
                    LIMIT 1
                  )
                ) AS text
              FROM trackers t
              LEFT JOIN occurrences o ON t.tracker_id = o.tracker_id
              WHERE t.type == 'text'
              GROUP BY t.tracker_id
              ORDER BY t.name ASC;
            ''', [
              startDate,
              endDate,
            ]);
          textTrackers = result.isNotEmpty
            ? result.map((c) => TextTracker.fromMap(c)).toList()
            : [];
        case TrackerType.monitor:
            final result = await db.rawQuery('''
              SELECT t.tracker_id, t.name, t.unit,t.type,
                COUNT(CASE WHEN o.datetime >= ? AND o.datetime <= ? THEN 1 ELSE NULL END) AS occurrences,
                (
                  SELECT 
                    CASE WHEN COUNT(o2.occurrence_id) = 0
                      THEN NULL ELSE MAX(o2.datetime) END
                  FROM occurrences o2 
                  WHERE o2.tracker_id = t.tracker_id 
                ) AS latest_occurrence,
                (
                  SELECT om.value 
                  FROM occurrences_monitor om
                  WHERE om.occurrence_id = (
                    SELECT occurrence_id 
                    FROM occurrences o2 
                    WHERE o2.tracker_id = t.tracker_id 
                    ORDER BY o2.datetime DESC 
                    LIMIT 1
                  )
                ) AS value
              FROM trackers t
              LEFT JOIN occurrences o ON t.tracker_id = o.tracker_id
              WHERE t.type == 'monitor'
              GROUP BY t.tracker_id
              ORDER BY t.name ASC;
            ''', [
              startDate,
              endDate,
            ]);
          monitorTrackers = result.isNotEmpty
            ? result.map((c) => MonitorTracker.fromMap(c)).toList()
            : [];
        default:
      }
    }
    trackers = []..addAll(counterTrackers.cast<Tracker>())
             ..addAll(timerTrackers.cast<Tracker>())
             ..addAll(textTrackers.cast<Tracker>())
             ..addAll(monitorTrackers.cast<Tracker>());

    return(trackers);
  }

  Future<int> getTrackerOccurrences(trackerId) async {
    final db = await instance.database;
    // Use a parameterized query to prevent SQL injection
    final result = await db.rawQuery(
      'SELECT COUNT(*) AS occurrences FROM occurrences WHERE tracker_id = ?',
      [trackerId],
    );
    
    if (result.isNotEmpty) {
      // The result is a list of maps, so we access the first item and then the 'count' key
      return int.tryParse(result.first['occurrences'].toString()) ?? 0;
    } else {
      return 0; // If the result is empty, return 0 occurrences
    }
  }
  
  Future<int> getTrackerOccurrencesByDate(trackerId, startDate, endDate) async {
    final db = await instance.database;
    // Use a parameterized query to prevent SQL injection
    final result = await db.rawQuery(
      '''SELECT COUNT(CASE WHEN datetime >= ? AND datetime <= ? THEN 1 ELSE NULL END) AS occurrences 
        FROM occurrences 
        WHERE tracker_id = ?''',
      [startDate,
      endDate,
      trackerId],
    );
    
    if (result.isNotEmpty) {
      // The result is a list of maps, so we access the first item and then the 'count' key
      return int.tryParse(result.first['occurrences'].toString()) ?? 0;
    } else {
      return 0; // If the result is empty, return 0 occurrences
    }
  }

  Future<int> getTrackerDurationFinishedBetweenDates(trackerId, startDate, endDate) async {
    final db = await instance.database;

    final result = await db.rawQuery('''SELECT 
      SUM(
              JULIANDAY(
                  CASE 
                      WHEN ot.end_time > ? THEN ? -- End date of range
                      ELSE ot.end_time 
                  END
              ) - 
              JULIANDAY(
                  CASE 
                      WHEN o.datetime < ? THEN ? -- Start date of range
                      ELSE o.datetime 
                  END
              )
          ) * 24 * 60 AS total_duration_minutes -- Convert days to minutes
      FROM 
          occurrences o
      INNER JOIN 
          occurrences_timer ot ON o.occurrence_id = ot.occurrence_id
      WHERE 
          o.tracker_id = ? AND
          (
              (o.datetime BETWEEN ? AND ?) OR
              (ot.end_time BETWEEN ? AND ?) OR
              (o.datetime < ? AND ot.end_time > ?)
          );
      ''',[endDate, startDate, trackerId]);
    
    print('durations');
    print(result);
    if (result.isNotEmpty) {
      // The result is a list of maps, so we access the first item and then the 'count' key
      return int.tryParse(result.first['total_duration_minutes'].toString()) ?? 0;
    } else {
      return 0; // If the result is empty, return 0 occurrences
    }
  }

  Future<List<Map<String, dynamic>>> getOccurrencesForTrackerByDate(
      int trackerId, String startDate, String endDate) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> result = await db.query(
      'occurrences',
      where: 'tracker_id = ? AND datetime >= ? AND datetime <= ?',
      whereArgs: [
        trackerId,
        startDate,
        endDate,
      ],
    );
    
    return result;
  }

  Future<void> printAllTrackers() async {
    final db = await instance.database;
    List<Map<String, dynamic>> allRows = await db.query('trackers');
    print('All trackers:');
    for (var row in allRows) {
      print(row);
    }
  }  

  Future<void> updateTracker(int id, String name, String unit) async {
    final db = await instance.database;
    await db.update(
      'trackers',
      {'name': name, 'unit': unit},
      where: 'tracker_id = ?',
      whereArgs: [id],
    );
  }

  Future<String> exportDatabaseToJSON() async {
    // Get the database path
    var databasesPath = await getDatabasesPath();
    String dbPath = join(databasesPath, 'my_database.db');

    // Get the export file path
    Directory? directory;
    if (Platform.isAndroid || Platform.isIOS) {
      directory = await getExternalStorageDirectory();
    } else {  // any other OS / test environments
      directory = await getApplicationDocumentsDirectory();
    }
    if (directory == null) {
      print('External storage is not available');
      return "Error";
    }

    String exportPath = join(directory.path, 'database_backup.json');

    final db = await instance.database;

    // Export the JSON data
    List<Map<String, dynamic>> tables = await db.rawQuery('SELECT name FROM sqlite_master WHERE type="table"');
    Map<String, dynamic> jsonMap = {};
    for (var table in tables) {
      String tableName = table['name'];
      List<Map<String, dynamic>> rows = await db.rawQuery('SELECT * FROM $tableName');
      jsonMap[tableName] = rows;
    }

    String json = jsonEncode(jsonMap);

    // Write to file
    File exportFile = File(exportPath);
    await exportFile.writeAsString(json);

    return exportPath;
  }

  Future<void> replaceDatabaseFromJSON(String jsonPath) async {
    final db = await instance.database;

    // Read the JSON file
    File jsonFile = File(jsonPath);
    String jsonString = await jsonFile.readAsString();
    Map<String, dynamic> jsonData = jsonDecode(jsonString);

    // Clear the existing tables
    await db.transaction((txn) async {
      // Get list of existingTables. Some OSs may have OS specific tables such as android_metatable, lets make sure this method works cross platform
      List<Map<String, dynamic>> tables = await txn.rawQuery('SELECT name FROM sqlite_master WHERE type="table"');
      Set<String> existingTables = tables.map((table) => table['name'].toString()).toSet();

      // Delete existing data in tables that are in the JSON but also exist in the current database
      for (var table in jsonData.keys) {
        if (existingTables.contains(table)) {
          await txn.delete(table);
        }
      }

      // Insert new data from JSON
      for (var tableName in jsonData.keys) {
        if (existingTables.contains(tableName)) {
          for (var row in jsonData[tableName]) {
            await txn.insert(tableName, Map<String, dynamic>.from(row));
          }
        }
      }
    });
  }
}
