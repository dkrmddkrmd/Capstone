class VideoProgress {
  final int? id;                  // PK (auto increment)
  final int lectureId;            // FK → lectures.id
  final String? week;
  final String? title;
  final String? requiredTimeText;
  final int? requiredTimeSec;
  final String? totalTimeText;
  final int? totalTimeSec;
  final double? progressPercent;

  VideoProgress({
    this.id,
    required this.lectureId,
    this.week,
    this.title,
    this.requiredTimeText,
    this.requiredTimeSec,
    this.totalTimeText,
    this.totalTimeSec,
    this.progressPercent,
  });

  // ---------- DB ----------
  factory VideoProgress.fromMap(Map<String, dynamic> map) {
    return VideoProgress(
      id: map['id'] as int?,
      lectureId: map['lecture_id'] as int,
      week: map['week'] as String?,
      title: map['title'] as String?,
      requiredTimeText: map['requiredTimeText'] as String?,
      requiredTimeSec: map['requiredTimeSec'] as int?,
      totalTimeText: map['totalTimeText'] as String?,
      totalTimeSec: map['totalTimeSec'] as int?,
      progressPercent: (map['progressPercent'] is int)
          ? (map['progressPercent'] as int).toDouble()
          : map['progressPercent'] as double?,
    );
  }

  Map<String, dynamic> toMap(int lectureId) {
    return {
      'id': id,
      'lecture_id': lectureId,
      'week': week,
      'title': title,
      'requiredTimeText': requiredTimeText,
      'requiredTimeSec': requiredTimeSec,
      'totalTimeText': totalTimeText,
      'totalTimeSec': totalTimeSec,
      'progressPercent': progressPercent,
    };
  }

  // ---------- JSON ----------
  factory VideoProgress.fromJson(Map<String, dynamic> json, {required int lectureId}) {
    return VideoProgress(
      id: json['id'] as int?,
      lectureId: lectureId,
      week: json['week'] as String?,
      title: json['title'] as String?,
      requiredTimeText: json['requiredTimeText'] as String?,
      requiredTimeSec: json['requiredTimeSec'] as int?,
      totalTimeText: json['totalTimeText'] as String?,
      totalTimeSec: json['totalTimeSec'] as int?,
      progressPercent: (json['progressPercent'] is int)
          ? (json['progressPercent'] as int).toDouble()
          : json['progressPercent'] as double?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'week': week,
      'title': title,
      'requiredTimeText': requiredTimeText,
      'requiredTimeSec': requiredTimeSec,
      'totalTimeText': totalTimeText,
      'totalTimeSec': totalTimeSec,
      'progressPercent': progressPercent,
    };
  }
}
