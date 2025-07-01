import 'package:flutter/material.dart';
import '../models/lecture.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const Color smBlue = Color(0xFF1A3276); // 상명대 남색

  @override
  Widget build(BuildContext context) {
    final List<Lecture> dummyLectures = [
      Lecture(id: '1', name: '자료구조', attendanceRate: 92.0),
      Lecture(id: '2', name: '운영체제', attendanceRate: 85.5),
      Lecture(id: '3', name: '알고리즘', attendanceRate: 78.0),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('홈'),
        automaticallyImplyLeading: false,
        backgroundColor: smBlue,
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 사용자 정보 (탭 기능 제거)
            Row(
              children: const [
                CircleAvatar(radius: 30, child: Icon(Icons.person, size: 30)),
                SizedBox(width: 12),
                Text(
                  '사용자',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 강의 리스트
            Expanded(
              child: ListView.builder(
                itemCount: dummyLectures.length,
                itemBuilder: (context, index) {
                  final lecture = dummyLectures[index];
                  return LectureTile(lecture: lecture);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 🔹 강의 타일
class LectureTile extends StatelessWidget {
  final Lecture lecture;
  const LectureTile({required this.lecture, super.key});

  static const Color sangmyungBlue = HomePage.smBlue;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: sangmyungBlue,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(
          lecture.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '출석률: ${lecture.attendanceRate.toStringAsFixed(1)}%',
          style: const TextStyle(color: Colors.white70),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Colors.white,
          size: 18,
        ),
        onTap: () {
          Navigator.pushNamed(context, '/lecturedetail', arguments: lecture);
        },
      ),
    );
  }
}
