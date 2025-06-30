import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const Color sangmyungBlue = Color(0xFF1A3276); // 상명대 남색

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('홈'),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
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
                    Navigator.pushNamed(context, '/profile'); // 마이페이지로 이동
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

            const SizedBox(height: 12),

            // 하단 버튼 3개
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const [
                HomeNavButton(label: '강의 정보', route: '/lecturedetail'),
                HomeNavButton(label: '시위 정보', route: '/demoninfo'),
                HomeNavButton(label: '공지사항', route: '/notices'),
              ],
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

  static const Color sangmyungBlue = HomePage.sangmyungBlue;

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

// 🔹 하단 네비게이션 버튼
class HomeNavButton extends StatelessWidget {
  final String label;
  final String route;
  const HomeNavButton({required this.label, required this.route, super.key});

  static const Color sangmyungBlue = HomePage.sangmyungBlue;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => Navigator.pushNamed(context, route),
      style: ElevatedButton.styleFrom(
        backgroundColor: sangmyungBlue,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );
  }
}
