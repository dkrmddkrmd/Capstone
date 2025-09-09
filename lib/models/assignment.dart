// models/assignment.dart
class Assignment {
  /// SQLite PK (AUTOINCREMENT). DB에 넣기 전이면 null일 수 있음.
  final int? id;

  /// FK. 상황에 따라 없는 경우가 있어 nullable로 둠(삽입 시에는 필요).
  final int? lectureId;

  final String name;

  /// ISO8601 문자열 (예: "2025-09-15T23:59:59")
  final String due;

  /// 예: 'todo' | 'done' 등
  final String status;

  const Assignment({
    this.id,
    this.lectureId,
    required this.name,
    required this.due,
    required this.status,
  });

  /// 서버 JSON → 모델
  factory Assignment.fromJson(Map<String, dynamic> json) {
    final dynamic idRaw = json['id'];
    final dynamic lecRaw = json['lectureId'] ?? json['lecture_id'];

    return Assignment(
      id: (idRaw is int) ? idRaw : int.tryParse(idRaw?.toString() ?? ''),
      lectureId:
      (lecRaw is int) ? lecRaw : int.tryParse(lecRaw?.toString() ?? ''),
      name: (json['name'] ?? '').toString(),
      due: (json['due'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
    );
  }

  /// DB row → 모델
  factory Assignment.fromMap(Map<String, dynamic> m) {
    final dynamic idRaw = m['id'];
    final dynamic lecRaw = m['lecture_id'];

    return Assignment(
      id: (idRaw is int) ? idRaw : int.tryParse(idRaw?.toString() ?? ''),
      lectureId:
      (lecRaw is int) ? lecRaw : int.tryParse(lecRaw?.toString() ?? ''),
      name: (m['name'] ?? '').toString(),
      due: (m['due'] ?? '').toString(),
      status: (m['status'] ?? '').toString(),
    );
  }

  /// 서버 전송용
  Map<String, dynamic> toJson({bool includeIds = false}) {
    final map = <String, dynamic>{
      'name': name,
      'due': due,
      'status': status,
    };
    if (includeIds) {
      if (id != null) map['id'] = id;
      if (lectureId != null) map['lectureId'] = lectureId;
    }
    return map;
  }

  /// DB 저장용 Map
  /// - 기본적으로 PK(id)는 넣지 않음(자동증가)
  /// - insert 시 lectureId가 필요하면 매개변수로 넘기면 됨.
  Map<String, dynamic> toMap(int lectureId, {int? overrideLectureId, bool includeId = false}) {
    final map = <String, dynamic>{
      'lecture_id': overrideLectureId ?? lectureId,
      'name': name,
      'due': due,
      'status': status,
    };
    if (includeId && id != null) {
      map['id'] = id;
    }
    return map;
  }

  /// 편의용 복제
  Assignment copyWith({
    int? id,
    int? lectureId,
    String? name,
    String? due,
    String? status,
  }) {
    return Assignment(
      id: id ?? this.id,
      lectureId: lectureId ?? this.lectureId,
      name: name ?? this.name,
      due: due ?? this.due,
      status: status ?? this.status,
    );
  }

  /// due(ISO8601)를 DateTime으로 파싱 (실패 시 null)
  DateTime? get dueAt {
    try {
      return DateTime.parse(due);
    } catch (_) {
      return null;
    }
  }
}
