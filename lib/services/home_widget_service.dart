// lib/services/home_widget_service.dart
import 'dart:convert';
import 'package:home_widget/home_widget.dart';

// 대시보드 아이템 타입
import '../models/video_progress.dart';
import '../services/home_dashboard_service.dart'; // DashboardAssignmentItem / DashboardVideoItem 제공
// ↑ 위 파일에서 DashboardAssignmentItem, DashboardVideoItem을 export하지 않는다면
//   여기에서 직접 정의 파일을 import 해주세요.

class HomeWidgetService {
  static const String _assignKey = 'assignments_json';
  static const String _videoKey  = 'videos_json';

  /// 대시보드 Future들을 받아 바로 푸시 (각각 await → 타입 안전)
  static Future<void> pushFromFutures({
    required Future<List<DashboardAssignmentItem>> futureAssignments,
    required Future<List<DashboardVideoItem>> futureVideos,
    int maxAssignments = 4,
    int maxVideos = 4,
  }) async {
    try {
      final assignments = await futureAssignments;
      final videos      = await futureVideos;
      await pushDashboard(
        assignments: assignments,
        videos: videos,
        maxAssignments: maxAssignments,
        maxVideos: maxVideos,
      );
    } catch (e) {
      // 푸시 실패 시에도 앱이 죽지 않도록 방어
      await _pushLinesSafe(assignLines: const [], videoLines: const []);
      rethrow;
    }
  }

  /// 대시보드 아이템을 받아 위젯으로 푸시
  static Future<void> pushDashboard({
    required List<DashboardAssignmentItem> assignments,
    required List<DashboardVideoItem> videos,
    int maxAssignments = 4,
    int maxVideos = 4,
  }) async {
    try {
      final assignLines = _buildAssignmentLines(assignments, maxAssignments);
      final videoLines  = _buildVideoLines(videos, maxVideos);
      await _pushLinesSafe(assignLines: assignLines, videoLines: videoLines);
    } catch (e) {
      // 실패 시 빈 데이터로라도 업데이트 (위젯 인플레이트 실패 방지)
      await _pushLinesSafe(assignLines: const [], videoLines: const []);
      rethrow;
    }
  }

  /// 문자열 라인을 직접 밀어넣고 싶을 때 사용 (테스트/디버그용)
  static Future<void> pushLines({
    required List<String> assignLines,
    required List<String> videoLines,
  }) async {
    await _pushLinesSafe(assignLines: assignLines, videoLines: videoLines);
  }

  /// 실제 저장 + 위젯 갱신 (예외 안전)
  static Future<void> _pushLinesSafe({
    required List<String> assignLines,
    required List<String> videoLines,
  }) async {
    try {
      await HomeWidget.saveWidgetData<String>(_assignKey, jsonEncode(assignLines));
      await HomeWidget.saveWidgetData<String>(_videoKey,  jsonEncode(videoLines));

      // Android 위젯 강제 갱신
      await HomeWidget.updateWidget(
        name: 'HomeDashboardWidgetProvider',
        androidName: 'HomeDashboardWidgetProvider',
        // iOS 사용 시 iOSName 지정 가능
      );
    } catch (_) {
      // 저장/업데이트 중 오류가 나도 앱 크래시 방지
    }
  }

  /// 과제 라인 빌드
  static List<String> _buildAssignmentLines(
      List<DashboardAssignmentItem> items,
      int maxCount,
      ) {
    return items.take(maxCount).map((a) {
      final due = _fmtDue(a.due);
      final title = (a.assignment.name).trim();
      final lecture = (a.lecture.title).trim();
      return '📌 $title · $lecture · $due';
    }).toList();
  }

  /// 동영상 라인 빌드
  static List<String> _buildVideoLines(
      List<DashboardVideoItem> items,
      int maxCount,
      ) {
    return items.take(maxCount).map((v) {
      final week = (v.progress.week ?? '').trim();
      final wk = week.isEmpty ? '' : '[$week] ';
      final pct = v.percent.clamp(0, 100).toStringAsFixed(0);
      final title = (v.progress.title ?? '').trim().isNotEmpty
          ? v.progress.title!.trim()
          : '(제목 없음)';
      final lecture = (v.lecture.title).trim();
      return '▶️ $wk$title · $lecture · $pct%';
    }).toList();
  }

  /// 날짜 포맷
  static String _fmtDue(DateTime? d) {
    if (d == null) return '-';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
  }
}
