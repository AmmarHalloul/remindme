
import 'package:flutter/widgets.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:table_calendar/table_calendar.dart' show isSameDay;

class Event {
  int? id;
  String name;
  DateTime date;
  int color = 0;

  Event.from(Map<String, Object?> map) :
    this.id = map['id'] as int,
    this.name = map['name'] as String,
    this.date = DateTime.parse(map['date'] as String),
    this.color = map['color'] as int {
  }

  Event(this.name, this.date);

  Map<String, Object?> toInsertMap() {
    return {
      "name": name,
      "date": date.toIso8601String(),
      "color": color,
    };
  }
}

DateTime stripTime(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

Future<EventModel> createEventModel() async{
  var database = await openDatabase(
    join(await getDatabasesPath(), "remindme4.db"),
    version: 1,
    onCreate: (db, version) {
      return db.execute('CREATE TABLE Events(id INTEGER PRIMARY KEY, name TEXT, date TEXT, color INTEGER)');
    } 
  );
  var q = await database.query('Events');
  var l = q.map((e) => Event.from(e)).toList();
  return EventModel(database, l);
}

class EventModel extends ChangeNotifier {  
  Database database;
  Map<DateTime, List<bool>> perDayCount = {};
  EventModel(this.database, List<Event> loadedEvents) {
    for (var e in loadedEvents) {
      addEventPerDay(e.date);
    }
  }

  addEventPerDay(DateTime date) {
    var day = stripTime(date);
    if (perDayCount.containsKey(day)) {
      perDayCount[day]?.add(true);
    } else {
      perDayCount[day] = [true];
    }
  }

  removeEventPerDay(DateTime date) {
    var day = stripTime(date);

    if (perDayCount.containsKey(day) && perDayCount[day]!.isNotEmpty) {
      perDayCount[day]?.removeLast();
    } 
  }

  void insert(Event e) async {
    addEventPerDay(e.date);
    await database.insert('Events', e.toInsertMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    notifyListeners();
  }

  void delete(Event e) async {
    removeEventPerDay(e.date);
    await database.delete('Events', where: 'id = ?', whereArgs: [e.id]);
    notifyListeners();
  }

  void update(Event e) async {
    await database.update('Events', e.toInsertMap(), where: 'id = ?', whereArgs: [e.id]);
    notifyListeners();
  }

  Future<List<Event>> selectAll() async {
    var q = await database.query('Events', orderBy: "date");
    return q.map((e) => Event.from(e)).toList();
  }

  Future<List<Event>> selectDay(DateTime day) async {
    var a = await selectAll();
    return a.where((e) => isSameDay(e.date, day)).toList();
  }

}