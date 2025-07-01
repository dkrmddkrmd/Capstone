import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const Color smBlue = Color(0xFF1A3276); // 상명대 남색

  @override
  Widget build(BuildContext context) {
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
            // 사용자 정보
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/profile');
                  },
                  child: const CircleAvatar(
                    radius: 30,
                    child: Icon(Icons.person, size: 30),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  '사용자',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 강의 리스트
            Expanded(
              child: ListView(
                children: const [
                  LectureTile(title: '강의 1'),
                  LectureTile(title: '강의 2'),
                  LectureTile(title: '강의 3'),
                ],
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
  final String title;
  const LectureTile({required this.title, super.key});

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
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Colors.white,
          size: 18,
        ),
        onTap: () {
          Navigator.pushNamed(context, '/lecturedetail');
        },
      ),
    );
  }
}
