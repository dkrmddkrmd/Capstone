import 'package:flutter/material.dart';

class LectureDetailPage extends StatelessWidget {
  const LectureDetailPage({super.key});

  static const Color smBlue = Color(0xFF1A3276); // 상명대 남색

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('강의 상세'),
        automaticallyImplyLeading: false,
        backgroundColor: smBlue,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 상단: 강의명 + 출석 동그라미
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '소프트웨어공학',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[300],
                    ),
                    child: const Center(child: Text('출석')),
                  ),
                ],
              ),
            ),
          ),

          // 중간: 과제 카드 리스트
          Expanded(
            flex: 2,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                buildTaskCard('과제 1'),
                buildTaskCard('과제 2'),
                buildTaskCard('과제 3'),
              ],
            ),
          ),

          // 하단: 강의자료 카드
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                color: Colors.grey[200],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text('강의자료', style: TextStyle(fontSize: 18)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTaskCard(String title) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: smBlue,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(title, style: const TextStyle(color: Colors.white)),
        trailing: const Icon(Icons.assignment, color: Colors.white),
        onTap: () {
          // 과제 상세로 이동 예정
        },
      ),
    );
  }
}
