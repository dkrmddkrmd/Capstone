// models/lecture.dart
import 'assignment.dart';

class Lecture {
  final int? localId;           // SQLite PK (자동 생성)
  final String title;
  final String professor;
  final String link;            // 백엔드의 고유 링크 → UNIQUE 키로 사용
  final List<Assignment> assignments;

  Lecture({
    this.localId,
    required this.title,
    required this.professor,
    required this.link,
    required this.assignments,
  });

  factory Lecture.fromJson(Map<String, dynamic> json) => Lecture(
    title: json['title']?.toString() ?? '',
    professor: json['professor']?.toString() ?? '',
    link: json['link']?.toString() ?? '',
    assignments: (json['assignments'] as List<dynamic>? ?? [])
        .map((a) => Assignment.fromJson(a as Map<String, dynamic>))
        .toList(),
  );

  Map<String, dynamic> toMap() => {
    'title': title,
    'professor': professor,
    'link': link,
  };

  factory Lecture.fromMap(Map<String, dynamic> m, {List<Assignment>? asg}) =>
      Lecture(
        localId: m['id'] as int?,
        title: m['title'] as String,
        professor: m['professor'] as String,
        link: m['link'] as String,
        assignments: asg ?? const [],
      );
}
