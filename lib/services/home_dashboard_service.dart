import 'package:flutter/foundation.dart';
import '../models/lecture.dart';
import '../models/assignment.dart';
import '../models/video_progress.dart';

import '../utils/filters.dart';
import 'db_service.dart';
import 'video_progress_service.dart';
import 'progress_calc_service.dart';

/// 홈 대시보드용 아이템 (과제)
class DashboardAssignmentItem {
  final Lecture lecture;
  final Assignment assignment;
  final DateTime? due;
  DashboardAssignmentItem({
    required this.lecture,
    required this.assignment,
    required this.due,
  });
}

/// 홈 대시보드용 아이템 (동영상)
class DashboardVideoItem {
  final Lecture lecture;
  final VideoProgress progress;
  final double percent; // 0~100
  DashboardVideoItem({
    required this.lecture,
    required this.progress,
    required this.percent,
  });
}

class HomeDashboardService {
  final _db = DBService();
  final _vp = VideoProgressService();

  /// 오늘(현지시간) 23:59:59까지 마감이고 '미제출'인 과제 목록
  Future<List<DashboardAssignmentItem>> loadAssignmentsDueToday() async {
    final lectures = await _db.getAllLecturesWithAssignments();
    final filteredLectures = lectures
        .where((lec) => !shouldExcludeLectureByTitle(lec.title))
        .toList(); // ⬅ 필터


    final now = DateTime.now();
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);



    final out = <DashboardAssignmentItem>[];
    for (final lec in filteredLectures) {
      for (final a in lec.assignments) {
        if (a.status != '미제출') continue;
        final due = _parseDue(a.due);
        if (due == null) continue; // 날짜 파싱 실패(표시문구 등)는 일단 제외
        if (!due.isAfter(endOfToday)) {
          out.add(DashboardAssignmentItem(lecture: lec, assignment: a, due: due));
        }
      }
    }

    // 가장 임박한 마감 순으로 정렬
    out.sort((x, y) {
      final dx = x.due ?? DateTime(2100);
      final dy = y.due ?? DateTime(2100);
      return dx.compareTo(dy);
    });
    return out;
  }

  /// 미완료(진도 < 100%) 동영상 목록 (최대 N개, 임박도/우선순위 기준 정렬)
  /// * 임박도는 week 텍스트가 숫자일 경우 오름차순, 그 외는 그대로
  Future<List<DashboardVideoItem>> loadIncompleteVideos({int limit = 10}) async {
    final lectures = await _db.getAllLecturesWithAssignments(); // assignments는 쓰지 않지만 재사용

    final filteredLectures = lectures
        .where((lec) => !shouldExcludeLectureByTitle(lec.title))
        .toList(); // ⬅ 필터

    final out = <DashboardVideoItem>[];

    for (final lec in filteredLectures) {
      final rows = await _vp.loadByLectureId(lec.localId!);
      for (final r in rows) {
        final p = ProgressCalcService.calcItemPercent(r);
        if (p < 100) {
          out.add(DashboardVideoItem(lecture: lec, progress: r, percent: p));
        }
      }
    }

    // 주차 숫자 → 오름차순, 같은 주차면 퍼센트 낮은(덜 본) 것 우선
    int _parseWeekNum(String? s) {
      if (s == null) return 9999;
      final n = RegExp(r'\d+').firstMatch(s)?.group(0);
      return int.tryParse(n ?? '') ?? 9999;
    }

    out.sort((a, b) {
      final wa = _parseWeekNum(a.progress.week);
      final wb = _parseWeekNum(b.progress.week);
      final byWeek = wa.compareTo(wb);
      if (byWeek != 0) return byWeek;
      return a.percent.compareTo(b.percent); // 덜 본 것 먼저
    });

    if (out.length > limit) return out.sublist(0, limit);
    return out;
  }

  // ---------------- helpers ----------------
  /// 과제 마감 문자열을 DateTime으로 최대한 유연하게 파싱
  /// 지원: 'YYYY-MM-DD', 'YYYY-MM-DD HH:mm', 'YYYY-MM-DD HH:mm:ss'
  ///      ISO8601(타임존 포함)도 시도
  DateTime? _parseDue(String? raw) {
    if (raw == null) return null;
    final s = raw.trim();
    if (s.isEmpty) return null;

    // ISO8601
    try {
      return DateTime.parse(s);
    } catch (_) {}

    // 'YYYY-MM-DD HH:mm[:ss]' 형태
    final ymdHms = RegExp(r'^(\d{4})-(\d{2})-(\d{2})(?:[ T](\d{2}):(\d{2})(?::(\d{2}))?)?$');
    final m = ymdHms.firstMatch(s);
    if (m != null) {
      final y = int.parse(m.group(1)!);
      final mo = int.parse(m.group(2)!);
      final d = int.parse(m.group(3)!);
      final hh = int.tryParse(m.group(4) ?? '23') ?? 23;
      final mm = int.tryParse(m.group(5) ?? '59') ?? 59;
      final ss = int.tryParse(m.group(6) ?? '59') ?? 59;
      return DateTime(y, mo, d, hh, mm, ss);
    }

    return null;
  }
}
