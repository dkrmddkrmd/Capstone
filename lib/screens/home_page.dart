import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  static const Color smBlue = Color(0xFF1A3276); // 상명대 남색

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('홈'),
        automaticallyImplyLeading: false,
        backgroundColor: HomePage.smBlue,
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

      // 🔹 하단 네비게이션 바 (아이콘만 + 순서 변경)
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.campaign), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: ''),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: HomePage.smBlue,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  // 🔹 하단 탭 클릭 시 처리
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushNamed(context, '/notices'); // 전공 공지
        break;
      case 1:
        Navigator.pushNamed(context, '/demoninfo'); // 시위 정보
        break;
      case 2:
        Navigator.pushNamed(context, '/profile'); // 마이페이지
        break;
      case 3:
        Navigator.pushNamed(context, '/settings'); // 환경 설정
        break;
    }
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
