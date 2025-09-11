import 'assignment.dart';
import 'video_progress.dart';

class Lecture {
  /// 로컬 DB PK (lectures.id)
  final int? localId;

  final String title;
  final String professor;
  final String link;

  /// 과제 목록 (메모리용)
  final List<Assignment> assignments;

  /// 🔹 동영상 진도 (메모리용; lectures 테이블에 저장하지 않음)
  /// - API/크롤링에서 받아온 경우에만 채워짐
  /// - 저장은 DBService.replaceVideoProgressForLecture(...)가 담당
  final List<VideoProgress>? videoProgress;

  Lecture({
    this.localId,
    required this.title,
    required this.professor,
    required this.link,
    this.assignments = const [],
    this.videoProgress,
  });

  // ---------- DB <-> 모델 ----------
  /// DB row → Lecture (assignments는 호출부에서 주입)
  factory Lecture.fromMap(Map<String, Object?> map, {List<Assignment> asg = const []}) {
    return Lecture(
      localId: map['id'] as int?,
      title: (map['title'] ?? '').toString(),
      professor: (map['professor'] ?? '').toString(),
      link: (map['link'] ?? '').toString(),
      assignments: asg,
      // DB에는 videoProgress를 저장하지 않으므로 null
      videoProgress: null,
    );
  }

  /// Lecture → DB row(lectures 테이블용)
  Map<String, Object?> toMap() {
    return {
      'id': localId,
      'title': title,
      'professor': professor,
      'link': link,
      // assignments / videoProgress는 개별 테이블에 저장하므로 제외
    };
  }

  // ---------- JSON (서버 응답 <-> 모델) ----------
  /// 서버 JSON → Lecture
  factory Lecture.fromJson(Map<String, dynamic> json) {
    final rawAssignments = (json['assignments'] as List?) ?? const [];
    final rawProgress = (json['progressRows'] as List?) ?? const [];

    return Lecture(
      localId: null,
      title: (json['title'] ?? '').toString(),
      professor: (json['professor'] ?? '').toString(),
      link: (json['link'] ?? '').toString(),
      assignments: rawAssignments.map((a) => Assignment.fromMap((a as Map).cast<String, dynamic>())).toList(),
      videoProgress: rawProgress.map((p) {
        final m = (p as Map).cast<String, dynamic>();
        return VideoProgress(
          id: null,
          lectureId: -1, // 🔸 나중에 DB 저장 시 실제 lectureId로 교체
          week: m['week'] as String?,
          title: m['title'] as String?,
          requiredTimeText: m['requiredTimeText'] as String?,
          requiredTimeSec: _asIntOrNull(m['requiredTimeSec']),
          totalTimeText: m['totalTimeText'] as String?,
          totalTimeSec: _asIntOrNull(m['totalTimeSec']),
          progressPercent: _asDoubleOrNull(m['progressPercent']),
        );
      }).toList(),
    );
  }

  /// Lecture → JSON (필요 시)
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'professor': professor,
      'link': link,
      'assignments': assignments.map((e) => e.toMap(localId ?? -1)).toList(),
      'progressRows': videoProgress?.map((e) => e.toJson()).toList(),
    };
  }

  static int? _asIntOrNull(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  static double? _asDoubleOrNull(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  /// 편의 복사
  Lecture copyWith({
    int? localId,
    String? title,
    String? professor,
    String? link,
    List<Assignment>? assignments,
    List<VideoProgress>? videoProgress,
  }) {
    return Lecture(
      localId: localId ?? this.localId,
      title: title ?? this.title,
      professor: professor ?? this.professor,
      link: link ?? this.link,
      assignments: assignments ?? this.assignments,
      videoProgress: videoProgress ?? this.videoProgress,
    );
  }
}
