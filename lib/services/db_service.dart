// services/db_service.dart
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/lecture.dart';
import '../models/assignment.dart';
import '../models/video_progress.dart';

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
      version: 5, // ✅ v5: video_progress 테이블 추가
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

        // 인덱스
        await db.execute('CREATE INDEX IF NOT EXISTS idx_lectures_link ON lectures(link);');

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
        await db.execute('CREATE INDEX IF NOT EXISTS idx_assignments_lecture ON assignments(lecture_id);');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_assignments_due ON assignments(due);');

        // --- video_progress (신규) ---
        await db.execute('''
          CREATE TABLE video_progress(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            lecture_id INTEGER NOT NULL,
            week TEXT,
            title TEXT,
            requiredTimeText TEXT,
            requiredTimeSec INTEGER,
            totalTimeText TEXT,
            totalTimeSec INTEGER,
            progressPercent REAL,
            UNIQUE(lecture_id, title, week) ON CONFLICT REPLACE,
            FOREIGN KEY(lecture_id) REFERENCES lectures(id) ON DELETE CASCADE
          );
        ''');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_video_progress_lecture ON video_progress(lecture_id);');

        // --- meta ---
        await db.execute('''
          CREATE TABLE meta(
            key TEXT PRIMARY KEY,
            value TEXT
          );
        ''');

        // --- ✅ User (최신 스키마로 생성)
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
        // v3 -> v4: major 컬럼 추가
        if (oldV < 4) {
          try { await db.execute('ALTER TABLE User ADD COLUMN major TEXT;'); } catch (_) {}
        }
        // v4 -> v5: video_progress 테이블 신설
        if (oldV < 5) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS video_progress(
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              lecture_id INTEGER NOT NULL,
              week TEXT,
              title TEXT,
              requiredTimeText TEXT,
              requiredTimeSec INTEGER,
              totalTimeText TEXT,
              totalTimeSec INTEGER,
              progressPercent REAL,
              UNIQUE(lecture_id, title, week) ON CONFLICT REPLACE,
              FOREIGN KEY(lecture_id) REFERENCES lectures(id) ON DELETE CASCADE
            );
          ''');
          await db.execute('CREATE INDEX IF NOT EXISTS idx_video_progress_lecture ON video_progress(lecture_id);');
        }

        // (안전) 인덱스 보장
        await db.execute('CREATE INDEX IF NOT EXISTS idx_lectures_link ON lectures(link);');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_assignments_lecture ON assignments(lecture_id);');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_assignments_due ON assignments(due);');
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
        profileImg TEXT,
        major TEXT
      );
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_user_userId ON User(userId);');
  }

  static Future<void> _addUserOptionalColumns(Database db) async {
    try { await db.execute('ALTER TABLE User ADD COLUMN userName TEXT;'); } catch (_) {}
    try { await db.execute('ALTER TABLE User ADD COLUMN profileImg TEXT;'); } catch (_) {}
    // v4에서 major 추가(여기선 제외) — onUpgrade에서 처리
  }

  Future<int> createUser(
      String userId,
      String userPw, {
        DateTime? createdAt,
        String? userName,
        String? profileImg,
        String? major, // ✅ 추가
      }) async {
    final d = await db;
    final nowIso = (createdAt ?? DateTime.now()).toIso8601String();
    return d.insert(
      'User',
      {
        'userId': userId.trim(),
        'userPw': userPw,
        'createdAt': nowIso,
        'userName': userName,
        'profileImg': profileImg,
        'major': major, // ✅ 저장
      },
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

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

  Future<int> updateUserProfile({
    required String userId,
    String? userName,
    String? profileImg,
    String? major, // ✅ 추가
  }) async {
    final d = await db;
    final data = <String, Object?>{};
    if (userName != null) data['userName'] = userName;
    if (profileImg != null) data['profileImg'] = profileImg;
    if (major != null) data['major'] = major;
    if (data.isEmpty) return 0;
    return d.update(
      'User',
      data,
      where: 'userId=?',
      whereArgs: [userId.trim()],
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<bool> validateUser(String userId, String userPw) async {
    final row = await getUserByUserId(userId);
    if (row == null) return false;
    return row['userPw'] == userPw;
  }

  /// 비밀번호 변경
  Future<int> updateUserPassword(String userId, String newPw) async {
    final d = await db;
    return d.update(
      'User',
      {'userPw': newPw},
      where: 'userId = ?',
      whereArgs: [userId.trim()],
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  /// 해당 userId가 존재하는지 여부
  Future<bool> hasUser(String userId) async {
    final d = await db;
    final cnt = Sqflite.firstIntValue(await d.rawQuery(
      'SELECT COUNT(*) FROM User WHERE userId = ?',
      [userId.trim()],
    ));
    return (cnt ?? 0) > 0;
  }

  /// 아무 사용자나 하나 가져와서 userId 반환 (저장된 계정이 하나뿐인 앱 가정 시 편의용)
  Future<String?> getAnySavedUserId() async {
    final d = await db;
    final rs = await d.query(
      'User',
      columns: ['userId'],
      orderBy: 'createdAt DESC',
      limit: 1,
    );
    if (rs.isEmpty) return null;
    return rs.first['userId'] as String?;
  }

  /// 사용자 삭제 (로그아웃/재등록 시 사용)
  Future<int> deleteUserByUserId(String userId) async {
    final d = await db;
    return d.delete(
      'User',
      where: 'userId = ?',
      whereArgs: [userId.trim()],
    );
  }

  // =========================
  // lectures / assignments
  // =========================

  Future<int> lecturesCount() async {
    final d = await db;
    final c = Sqflite.firstIntValue(
      await d.rawQuery('SELECT COUNT(*) FROM lectures'),
    );
    return c ?? 0;
  }

  /// 기존 메서드 (유지해도 됨)
  Future<void> saveCourses(List<Lecture> arr) async {
    final d = await db;
    await d.transaction((txn) async {
      for (final lec in arr) {
        await txn.insert(
          'lectures',
          lec.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

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

        // (선택) Lecture에 videoProgress 리스트를 나중에 붙일 계획이면 여기서 저장 가능
        // if (lec.videoProgress != null) {
        //   await replaceVideoProgressForLecture(lid, lec.videoProgress!);
        // }
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

  /// 크롤링 결과를 기준으로 동기화
  Future<void> syncCourses(List<Lecture> crawled) async {
    final d = await db;
    await d.transaction((txn) async {
      // 1) 기존 강좌 맵
      final existingRows = await txn.query(
        'lectures',
        columns: ['id', 'link', 'title', 'professor'],
      );
      final Map<String, Map<String, Object?>> existingByLink = {
        for (final r in existingRows) (r['link'] as String): r
      };

      // 2) 크롤링 링크 집합
      final Set<String> crawledLinks = crawled.map((e) => e.link).toSet();

      // 3) 삭제 대상
      final List<int> deleteIds = [];
      for (final r in existingRows) {
        final link = r['link'] as String;
        if (!crawledLinks.contains(link)) deleteIds.add(r['id'] as int);
      }
      if (deleteIds.isNotEmpty) {
        final placeholders = List.filled(deleteIds.length, '?').join(',');
        await txn.delete('lectures', where: 'id IN ($placeholders)', whereArgs: deleteIds);
        // ON DELETE CASCADE 로 assignments / video_progress 자동 삭제
      }

      // 4) upsert & 과제 리프레시
      for (final lec in crawled) {
        final exist = existingByLink[lec.link];

        int lectureId;
        if (exist == null) {
          lectureId = await txn.insert(
            'lectures',
            lec.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        } else {
          lectureId = exist['id'] as int;
          await txn.update(
            'lectures',
            {'title': lec.title, 'professor': lec.professor, 'link': lec.link},
            where: 'id=?',
            whereArgs: [lectureId],
            conflictAlgorithm: ConflictAlgorithm.abort,
          );
          await txn.delete('assignments', where: 'lecture_id=?', whereArgs: [lectureId]);
          await txn.delete('video_progress', where: 'lecture_id=?', whereArgs: [lectureId]);
        }

        for (final a in lec.assignments) {
          await txn.insert(
            'assignments',
            a.toMap(lectureId),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        // (선택) 크롤링 단계에서 Lecture에 progress를 담아왔다면 여기서 저장
        // if (lec.videoProgress != null) {
        //   await _insertManyVideoProgress(txn, lectureId, lec.videoProgress!);
        // }
      }

      await txn.insert(
        'meta',
        {'key': 'last_sync', 'value': DateTime.now().toIso8601String()},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  /// 특정 강의 과제 목록
  Future<List<Assignment>> getAssignmentsByLectureId(int? lectureId) async {
    if (lectureId == null) return [];
    final d = await db;
    final rows = await d.query(
      'assignments',
      where: 'lecture_id=?',
      whereArgs: [lectureId],
      orderBy: 'due ASC',
    );
    return rows.map(Assignment.fromMap).toList();
  }

  /// (옵션) 링크로 lecture_id 찾기
  Future<int?> getLectureIdByLink(String link) async {
    final d = await db;
    final rs = await d.query(
      'lectures',
      columns: ['id'],
      where: 'link=?',
      whereArgs: [link],
      limit: 1,
    );
    if (rs.isEmpty) return null;
    return rs.first['id'] as int;
  }

  // -------------------------
  // assignments CRUD
  // -------------------------

  Future<int> addAssignment(int lectureId, Assignment a) async {
    final d = await db;
    return d.insert(
      'assignments',
      a.toMap(lectureId),
      conflictAlgorithm: ConflictAlgorithm.replace, // (lecture_id, name, due) UNIQUE
    );
  }

  Future<int> updateAssignment(Assignment a) async {
    if (a.id == null) return 0;
    final d = await db;
    return d.update(
      'assignments',
      {
        'name': a.name,
        'due': a.due,
        'status': a.status,
      },
      where: 'id=?',
      whereArgs: [a.id],
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<int> deleteAssignment(int id) async {
    final d = await db;
    return d.delete('assignments', where: 'id=?', whereArgs: [id]);
  }

  // =========================
  // video_progress CRUD
  // =========================

  Future<int> addVideoProgress(int lectureId, VideoProgress vp) async {
    final d = await db;
    return d.insert(
      'video_progress',
      vp.toMap(lectureId),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> replaceVideoProgressForLecture(int lectureId, List<VideoProgress> rows) async {
    final d = await db;
    await d.transaction((txn) async {
      await txn.delete('video_progress', where: 'lecture_id=?', whereArgs: [lectureId]);
      for (final r in rows) {
        await txn.insert(
          'video_progress',
          r.toMap(lectureId),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<List<VideoProgress>> getVideoProgressByLectureId(int lectureId) async {
    final d = await db;
    final rows = await d.query(
      'video_progress',
      where: 'lecture_id=?',
      whereArgs: [lectureId],
      orderBy: 'id ASC',
    );
    return rows.map(VideoProgress.fromMap).toList();
  }

  Future<int> updateVideoProgress(VideoProgress vp) async {
    if (vp.id == null) return 0;
    final d = await db;
    return d.update(
      'video_progress',
      vp.toMap(vp.lectureId),
      where: 'id=?',
      whereArgs: [vp.id],
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<int> deleteVideoProgress(int id) async {
    final d = await db;
    return d.delete('video_progress', where: 'id=?', whereArgs: [id]);
  }

  // 내부 다건 삽입 헬퍼
  Future<void> _insertManyVideoProgress(Transaction txn, int lectureId, List<VideoProgress> rows) async {
    for (final r in rows) {
      await txn.insert(
        'video_progress',
        r.toMap(lectureId),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }
}
