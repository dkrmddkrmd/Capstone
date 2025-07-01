class Lecture {
  final String id;
  final String name;
  final double attendanceRate;

  Lecture({required this.id, required this.name, required this.attendanceRate});

  factory Lecture.fromJson(Map<String, dynamic> json) {
    return Lecture(
      id: json['id'],
      name: json['name'],
      attendanceRate: json['attendanceRate'].toDouble(),
    );
  }
}
