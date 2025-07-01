import 'package:flutter/material.dart';

const smBlue = Color(0xFF1A3276);

class DepartmentNoticePage extends StatelessWidget {
  const DepartmentNoticePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('전공별 공지'),
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
            const Text(
              '컴퓨터과학과',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: smBlue,
              ),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: ListView(
                children: const [
                  NoticeCard(title: '공지사항 제목 1'),
                  NoticeCard(title: '공지사항 제목 2'),
                  NoticeCard(title: '공지사항 제목 3'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NoticeCard extends StatelessWidget {
  final String title;
  const NoticeCard({required this.title, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        tileColor: smBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.white,
        ),
        onTap: () {
          // 나중에 공지 상세 페이지로 이동
        },
      ),
    );
  }
}
