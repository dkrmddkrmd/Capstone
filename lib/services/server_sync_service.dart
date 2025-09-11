import 'dart:convert';

import '../models/lecture.dart';
import '../models/assignment.dart';
import '../models/video_progress.dart';
import 'db_service.dart';

/// 서버 JSON 응답(courses 배열 포함)을 로컬 DB로 동기화
class ServerSyncService {
  final DBService _db = DBService();

  /// 서버에서 받은 payload(Map or JSON String)를 그대로 넘겨주면 됨
  Future<void> ingestServerResponse(dynamic payload) async {
    // 1) payload 파싱
    final Map<String, dynamic> root = _normalizePayload(payload);

    // 2) courses 배열 획득
    final List<dynamic> courses = (root['courses'] as List?) ?? const [];

    // 3) Lecture/Assignment로 변환 (progressRows 제외)
    final lectures = <Lecture>[];
    for (final c in courses) {
      final map = (c as Map).cast<String, dynamic>();
      final title = (map['title'] ?? '').toString();
      final professor = (map['professor'] ?? '').toString();
      final link = (map['link'] ?? '').toString();

      // assignments
      final rawAssignments = (map['assignments'] as List?) ?? const [];
      final assignments = <Assignment>[];
      for (final a in rawAssignments) {
        final am = (a as Map).cast<String, dynamic>();
        assignments.add(Assignment(
          id: null, // DB에서 autoincrement
          name: (am['name'] ?? '').toString(),
          due: (am['due'] ?? '').toString(),
          status: (am['status'] ?? '').toString(),
        ));
      }

      lectures.add(Lecture(
        localId: null, // DB에서 생성
        title: title,
        professor: professor,
        link: link,
        assignments: assignments,
      ));
    }

    // 4) 강의/과제 동기화
    await _db.syncCourses(lectures);

    // 5) 비디오 진도(progressRows) 저장
    for (final c in courses) {
      final map = (c as Map).cast<String, dynamic>();
      final link = (map['link'] ?? '').toString();
      if (link.isEmpty) continue;

      final lectureId = await _db.getLectureIdByLink(link);
      if (lectureId == null) {
        // 이 강의가 DB에 없으면 스킵
        continue;
      }

      final rawProgress = (map['progressRows'] as List?) ?? const [];
      final rows = <VideoProgress>[];

      for (final p in rawProgress) {
        final pm = (p as Map).cast<String, dynamic>();
        rows.add(
          VideoProgress(
            id: null,
            lectureId: lectureId,
            week: (pm['week'] as String?),
            title: (pm['title'] as String?),
            requiredTimeText: (pm['requiredTimeText'] as String?),
            requiredTimeSec: _asIntOrNull(pm['requiredTimeSec']),
            totalTimeText: (pm['totalTimeText'] as String?),
            totalTimeSec: _asIntOrNull(pm['totalTimeSec']),
            progressPercent: _asDoubleOrNull(pm['progressPercent']),
          ),
        );
      }

      // 해당 강의의 비디오 진도를 전량 교체 저장
      await _db.replaceVideoProgressForLecture(lectureId, rows);
    }
  }

  // ---------------- helpers ----------------

  Map<String, dynamic> _normalizePayload(dynamic payload) {
    if (payload is String) {
      return jsonDecode(payload) as Map<String, dynamic>;
    } else if (payload is Map<String, dynamic>) {
      return payload;
    } else {
      throw ArgumentError('Unsupported payload type: ${payload.runtimeType}');
    }
  }

  int? _asIntOrNull(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is String) {
      final s = v.trim();
      if (s.isEmpty) return null;
      return int.tryParse(s);
    }
    if (v is double) return v.toInt();
    return null;
  }

  double? _asDoubleOrNull(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) {
      final s = v.trim();
      if (s.isEmpty) return null;
      return double.tryParse(s);
    }
    return null;
  }
}
