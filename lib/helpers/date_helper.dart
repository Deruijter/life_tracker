import 'package:intl/intl.dart';

class DateHelper {
  String getDateTodayStart(){
    DateTime now = DateTime.now();
    String dateTodayStart = DateFormat('yyyy-MM-dd').format(now) + ' 00:00:00';

    return dateTodayStart;
  }

  String getDateTodayEnd(){
    DateTime now = DateTime.now();
    DateTime tomorrow = DateTime(now.year, now.month, now.day + 1);
    String dateTodayEnd = DateFormat('yyyy-MM-dd').format(tomorrow) + ' 00:00:00';

    return dateTodayEnd;
  }

  String getDateYesterdayStart(){
    DateTime now = DateTime.now();
    DateTime tomorrow = DateTime(now.year, now.month, now.day - 1);
    String dateYesterdayStart = DateFormat('yyyy-MM-dd').format(tomorrow) + ' 00:00:00';

    return dateYesterdayStart;
  }

  String getDateYesterdayEnd(){
    return getDateTodayStart();
  }

  String getDateWeekStart(){
    DateTime now = DateTime.now();
    DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    String dateWeekStart = DateFormat('yyyy-MM-dd').format(startOfWeek) + ' 00:00:00';
    
    return dateWeekStart;
  }

  String getDateWeekEnd(){
    DateTime now = DateTime.now();
    DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    DateTime endOfWeek = DateTime(now.year, now.month, now.day + 7);
    String dateWeekEnd = DateFormat('yyyy-MM-dd').format(endOfWeek) + ' 00:00:00';
    
    return dateWeekEnd;
  }

  String getDateMonthStart(){
    DateTime now = DateTime.now();
    DateTime startOfMonth = DateTime(now.year, now.month, 1);
    String dateMonthStart = DateFormat('yyyy-MM-dd').format(startOfMonth) + ' 00:00:00';
    
    return dateMonthStart;
  }

  String getDateMonthEnd(){
    DateTime now = DateTime.now();
    DateTime endOfMonth = DateTime(now.year, now.month + 1, 1);
    String dateMonthEnd = DateFormat('yyyy-MM-dd').format(endOfMonth) + ' 00:00:00';
    
    return dateMonthEnd;
  }

  String getDateYearStart(){
    DateTime now = DateTime.now();
    DateTime startOfYear = DateTime(now.year, 1, 1);
    String dateYearStart = DateFormat('yyyy-MM-dd').format(startOfYear) + ' 00:00:00';
    
    return dateYearStart;
  }

  String getDateYearEnd(){
    DateTime now = DateTime.now();
    DateTime endOfYear = DateTime(now.year+1, 1, 1);
    String dateYearEnd = DateFormat('yyyy-MM-dd').format(endOfYear) + ' 00:00:00';
    
    return dateYearEnd;
  }
}