// models/assignment.dart
class Assignment {
  final String name;
  final String due;     // ISO8601 문자열 보관(예: "2025-09-15T23:59:59")
  final String status;

  Assignment({required this.name, required this.due, required this.status});

  factory Assignment.fromJson(Map<String, dynamic> json) => Assignment(
    name: json['name']?.toString() ?? '',
    due: json['due']?.toString() ?? '',
    status: json['status']?.toString() ?? '',
  );

  Map<String, dynamic> toJson() => {'name': name, 'due': due, 'status': status};

  Map<String, dynamic> toMap(int lectureId) => {
    'lecture_id': lectureId,
    'name': name,
    'due': due,
    'status': status,
  };

  factory Assignment.fromMap(Map<String, dynamic> m) => Assignment(
    name: m['name'] as String,
    due: m['due'] as String,
    status: m['status'] as String,
  );
}
