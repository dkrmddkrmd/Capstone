import 'package:flutter/material.dart';
import '../models/lecture.dart';

class LectureDetailPage extends StatelessWidget {
  const LectureDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ 2) 라우팅 인자 가드
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is! Lecture) {
      return const Scaffold(
        body: Center(child: Text('잘못된 파라미터입니다. (Lecture 필요)')),
      );
    }
    final Lecture lecture = args;

    return Scaffold(
      appBar: AppBar(
        title: Text(lecture.title),
        backgroundColor: const Color(0xFF1A3276),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 상단: 강의명 + 출석률
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(16), // ✅ const
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    lecture.title,
                    style: const TextStyle(
                      // ✅ const
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const SizedBox(
                          // ✅ const
                          width: 100, // 원 크기
                          height: 100,
                          // 진행 링은 아래 _AttendanceCircle로 분리(리빌드 최소화 용이)
                          child: _AttendanceCircle(),
                        ),
                        Text(
                          // '${lecture.attendanceRate.toStringAsFixed(1)}%',
                          '50%',
                          style: const TextStyle(
                            // ✅ 1번 제외(검정 유지)
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 중간: 과제 카드
          Expanded(
            flex: 2,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16), // ✅ const
              children: const [
                // ✅ const
                AssignmentCard(title: '과제 1', due: '7월 5일 마감'),
                AssignmentCard(title: '과제 2', due: '7월 12일 마감'),
                AssignmentCard(title: '과제 3', due: '7월 19일 마감'),
              ],
            ),
          ),

          // 하단: 강의자료
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(16), // ✅ const
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const ListTile(
                  // ✅ const
                  title: Text('강의자료'),
                  subtitle: Text('슬라이드, PDF, 영상 등 업로드됨'),
                  trailing: Icon(Icons.arrow_forward_ios),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 진행 링만 분리(가독성/재사용성↑)
class _AttendanceCircle extends StatelessWidget {
  const _AttendanceCircle({super.key});

  @override
  Widget build(BuildContext context) {
    final Lecture lecture =
        ModalRoute.of(context)!.settings.arguments as Lecture;

    return CircularProgressIndicator(
      // value: lecture.attendanceRate / 100,
      value: 50,
      strokeWidth: 10,
      backgroundColor: Colors.grey[300],
      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1A3276)),
    );
  }
}

// 🔹 과제 카드 위젯
class AssignmentCard extends StatelessWidget {
  final String title;
  final String due;
  const AssignmentCard({required this.title, required this.due, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8), // ✅ const
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(title),
        subtitle: Text(due),
        trailing: const Icon(Icons.assignment), // ✅ const
        onTap: () {
          // 과제 상세 페이지로 이동 가능
        },
      ),
    );
  }
}
