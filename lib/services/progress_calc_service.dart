// lib/services/progress_calc_service.dart
import '../models/video_progress.dart';

class ProgressCalcService {
  /// 단일 아이템의 진행 퍼센트(0~100)
  /// - progressPercent가 있으면 그대로 사용
  /// - 없으면 totalTimeSec / requiredTimeSec 기반으로 추정 (최대 100)
  static double calcItemPercent(VideoProgress vp) {
    if (vp.progressPercent != null) {
      final p = vp.progressPercent!;
      if (p.isNaN) return 0;
      return p.clamp(0, 100);
    }
    if (vp.requiredTimeSec != null && vp.requiredTimeSec! > 0 && vp.totalTimeSec != null) {
      final ratio = vp.totalTimeSec! / vp.requiredTimeSec!;
      return (ratio * 100).clamp(0, 100);
    }
    // 정보가 없으면 0으로 간주
    return 0;
  }

  /// 강의의 전체 출석률(0~100)
  /// - progressPercent가 있는 항목은 평균에 그대로 반영
  /// - 없으면 total/required 비율로 계산
  /// - 둘 다 없으면 0으로 취급
  static double calcLectureAttendance(List<VideoProgress> rows) {
    if (rows.isEmpty) return 0;
    double sum = 0;
    int count = 0;
    for (final vp in rows) {
      sum += calcItemPercent(vp);
      count++;
    }
    if (count == 0) return 0;
    return (sum / count).clamp(0, 100);
  }
}
