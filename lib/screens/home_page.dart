import 'package:flutter/material.dart';
import '../models/lecture.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // TODO: 이후 colors.dart로 이동 추천
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
            const Row(
              children: [
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
              child: RefreshIndicator(
                onRefresh: () async {
                  // TODO: 실제 API 연동 시 강의 목록 재요청 처리
                  await Future<void>.delayed(const Duration(milliseconds: 700));
                },
                child: dummyLectures.isEmpty
                    ? ListView(
                        children: const [
                          SizedBox(height: 80),
                          Center(
                            child: Text(
                              '등록된 강의가 없습니다.',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                        itemCount: dummyLectures.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 6),
                        itemBuilder: (context, index) {
                          final lecture = dummyLectures[index];
                          return LectureTile(lecture: lecture);
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 🔹 출석률 링 위젯 (부드러운 애니메이션 포함)
class AttendanceRing extends StatelessWidget {
  final double percent; // 0~100
  final double size;
  final Color color;
  const AttendanceRing({
    super.key,
    required this.percent,
    this.size = 44,
    this.color = HomePage.smBlue,
  });

  @override
  Widget build(BuildContext context) {
    final value = (percent.clamp(0, 100)) / 100.0;
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value),
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeOutCubic,
        builder: (_, v, __) {
          return Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: v,
                strokeWidth: 5,
                backgroundColor: color.withOpacity(0.15),
                // 색상은 테마를 따라감. 필요시 valueColor로 지정 가능
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
              Text(
                '${(v * 100).round()}%',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          );
        },
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
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: AttendanceRing(
          percent: lecture.attendanceRate,
          size: 44,
          color: Colors.white, // 흰색 링으로 카드 배경과 대비
        ),
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
