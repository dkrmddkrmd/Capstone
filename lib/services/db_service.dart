// services/db_service.dart
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/lecture.dart';
import '../models/assignment.dart';

class DBService {
  static final DBService _i = DBService._();
  DBService._();
  factory DBService() => _i;

  Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    final base = await getDatabasesPath();
    _db = await openDatabase(
      join(base, 'ecampus_app.db'),
      version: 1,
      onCreate: (db, v) async {
        await db.execute('''
          CREATE TABLE lectures(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            professor TEXT NOT NULL,
            link TEXT NOT NULL UNIQUE
          )
        ''');
        await db.execute('''
          CREATE TABLE assignments(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            lecture_id INTEGER NOT NULL,
            name TEXT NOT NULL,
            due TEXT NOT NULL,
            status TEXT NOT NULL,
            UNIQUE(lecture_id, name, due) ON CONFLICT REPLACE,
            FOREIGN KEY(lecture_id) REFERENCES lectures(id) ON DELETE CASCADE
          )
        ''');
        await db.execute('''
          CREATE TABLE meta(
            key TEXT PRIMARY KEY,
            value TEXT
          )
        ''');
      },
    );
    await _db!.execute('PRAGMA foreign_keys=ON');
    return _db!;
  }

  Future<int> lecturesCount() async {
    final d = await db;
    final c = Sqflite.firstIntValue(
      await d.rawQuery('SELECT COUNT(*) FROM lectures'),
    );
    return c ?? 0;
  }

  Future<void> saveCourses(List<Lecture> arr) async {
    final d = await db;
    await d.transaction((txn) async {
      for (final lec in arr) {
        await txn.insert('lectures', lec.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace);
        final idRow = await txn.query(
          'lectures',
          columns: ['id'],
          where: 'link=?',
          whereArgs: [lec.link],
          limit: 1,
        );
        final lid = idRow.first['id'] as int;
        for (final a in lec.assignments) {
          await txn.insert(
            'assignments',
            a.toMap(lid),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
      await txn.insert(
        'meta',
        {'key': 'last_sync', 'value': DateTime.now().toIso8601String()},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  Future<List<Lecture>> getAllLecturesWithAssignments() async {
    final d = await db;
    final lrs = await d.query('lectures', orderBy: 'title ASC');
    final out = <Lecture>[];
    for (final m in lrs) {
      final id = m['id'] as int;
      final ars = await d.query('assignments',
          where: 'lecture_id=?', whereArgs: [id], orderBy: 'due ASC');
      out.add(Lecture.fromMap(
        m,
        asg: ars.map(Assignment.fromMap).toList(),
      ));
    }
    return out;
  }
}
