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
      version: 3, // ✅ v3: User.userName, User.profileImg 추가
      onCreate: (db, v) async {
        // --- lectures ---
        await db.execute('''
          CREATE TABLE lectures(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            professor TEXT NOT NULL,
            link TEXT NOT NULL UNIQUE
          );
        ''');

        // --- assignments ---
        await db.execute('''
          CREATE TABLE assignments(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            lecture_id INTEGER NOT NULL,
            name TEXT NOT NULL,
            due TEXT NOT NULL,
            status TEXT NOT NULL,
            UNIQUE(lecture_id, name, due) ON CONFLICT REPLACE,
            FOREIGN KEY(lecture_id) REFERENCES lectures(id) ON DELETE CASCADE
          );
        ''');

        // --- meta ---
        await db.execute('''
          CREATE TABLE meta(
            key TEXT PRIMARY KEY,
            value TEXT
          );
        ''');

        // --- ✅ v3: User (최신 스키마로 생성)
        await _createUserTable(db);
      },
      onUpgrade: (db, oldV, newV) async {
        // v1 -> v2: User 테이블 생성
        if (oldV < 2) {
          await _createUserTable(db);
        }
        // v2 -> v3: userName, profileImg 컬럼 추가
        if (oldV < 3) {
          await _addUserOptionalColumns(db);
        }
      },
    );
    await _db!.execute('PRAGMA foreign_keys=ON');
    return _db!;
  }

  // =========================
  // User 테이블/메서드
  // =========================

  static Future<void> _createUserTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS User(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT NOT NULL UNIQUE,
        userPw TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        userName TEXT,
        profileImg TEXT
      );
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_user_userId ON User(userId);');
  }

  static Future<void> _addUserOptionalColumns(Database db) async {
    // 이미 있으면 무시되도록 try/catch
    try {
      await db.execute('ALTER TABLE User ADD COLUMN userName TEXT;');
    } catch (_) {}
    try {
      await db.execute('ALTER TABLE User ADD COLUMN profileImg TEXT;');
    } catch (_) {}
  }

  /// 사용자 등록 (중복 userId면 예외 발생: UNIQUE 제약)
  Future<int> createUser(
      String userId,
      String userPw, {
        DateTime? createdAt,
        String? userName,
        String? profileImg,
      }) async {
    final d = await db;
    final nowIso = (createdAt ?? DateTime.now()).toIso8601String();
    return await d.insert(
      'User',
      {
        'userId': userId.trim(),
        'userPw': userPw,
        'createdAt': nowIso,
        'userName': userName,
        'profileImg': profileImg,
      },
      conflictAlgorithm: ConflictAlgorithm.abort, // 중복이면 에러
    );
  }

  /// userId로 1명 조회 (Map 반환 — 필요 시 AppUser.fromMap 사용)
  Future<Map<String, dynamic>?> getUserByUserId(String userId) async {
    final d = await db;
    final rows = await d.query(
      'User',
      where: 'userId=?',
      whereArgs: [userId.trim()],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first;
  }

  /// (선택) 프로필 업데이트
  Future<int> updateUserProfile({
    required String userId,
    String? userName,
    String? profileImg,
  }) async {
    final d = await db;
    final data = <String, Object?>{};
    if (userName != null) data['userName'] = userName;
    if (profileImg != null) data['profileImg'] = profileImg;
    if (data.isEmpty) return 0;
    return await d.update(
      'User',
      data,
      where: 'userId=?',
      whereArgs: [userId.trim()],
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  /// 로그인 검증용 (간단 비교)
  Future<bool> validateUser(String userId, String userPw) async {
    final row = await getUserByUserId(userId);
    if (row == null) return false;
    return row['userPw'] == userPw;
  }

  // =========================
  // 기존 강의/과제 메서드
  // =========================

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
      final ars = await d.query(
        'assignments',
        where: 'lecture_id=?',
        whereArgs: [id],
        orderBy: 'due ASC',
      );
      out.add(Lecture.fromMap(
        m,
        asg: ars.map(Assignment.fromMap).toList(),
      ));
    }
    return out;
  }
}
