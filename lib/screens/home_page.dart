// pages/home_page.dart
import 'package:flutter/material.dart';
import '../models/assignment.dart';
import '../models/lecture.dart';

import '../services/db_service.dart';
import '../services/lecture_repository.dart';
import '../services/secure_storage.dart';

// 🔹 새로 추가
import '../services/home_dashboard_service.dart';
import '../models/video_progress.dart';
import '../services/progress_calc_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const Color smBlue = Color(0xFF1A3276);

  final _repo = LectureRepository();
  final _dash = HomeDashboardService();

  List<Lecture> lectures = [];
  bool isLoading = true;
  String? errorMessage;
  String? currentUserName;

  // 대시보드 데이터
  Future<List<DashboardAssignmentItem>> _futureTodayAssignments = Future.value(const <DashboardAssignmentItem>[]);
  Future<List<DashboardVideoItem>> _futureIncompleteVideos = Future.value(const <DashboardVideoItem>[]);

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final hasCreds = await SecureStore.hasCreds();
    if (!mounted) return;

    if (!hasCreds) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 필요합니다')),
      );
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    await _loadLecturesPreferLocal();
    await _loadUserName();
    _reloadDashboard();
  }

  void _reloadDashboard() {
    _futureTodayAssignments = _dash.loadAssignmentsDueToday();
    _futureIncompleteVideos = _dash.loadIncompleteVideos(limit: 10);
    if (mounted) setState(() {});
  }

  Future<void> _loadUserName() async {
    final db = DBService();
    final uid = await db.getAnySavedUserId();
    if (!mounted) return;

    if (uid != null) {
      final row = await db.getUserByUserId(uid);
      final dbName = (row?['userName'] as String?)?.trim();
      setState(() => currentUserName = dbName);
    }
  }

  Future<void> _loadLecturesPreferLocal() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final fetched = await _repo.getLecturesPreferLocal();
      if (!mounted) return;
      setState(() {
        lectures = fetched;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
        lectures = _getDummyLectures();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('강의 목록을 불러오는데 실패했습니다: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _onRefresh() async {
    final hasCreds = await SecureStore.hasCreds();
    if (!mounted) return;

    if (!hasCreds) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 필요합니다')),
      );
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    try {
      await _repo.refreshFromApi();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('동기화 실패: $e'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
    }
    await _loadLecturesPreferLocal();
    _reloadDashboard();
  }

  List<Lecture> _getDummyLectures() {
    return [
      Lecture(
        title: '자료구조',
        professor: '김교수',
        link: 'https://ecampus.smu.ac.kr/course/view.php?id=1001',
        assignments: [
          Assignment(name: '과제 1: 연결리스트 구현', due: '2025-09-15', status: '미제출'),
          Assignment(name: '과제 2: 트리 순회', due: '2025-09-30', status: '제출'),
        ],
      ),
      Lecture(
        title: '운영체제',
        professor: '이교수',
        link: 'https://ecampus.smu.ac.kr/course/view.php?id=1002',
        assignments: [
          Assignment(name: '과제 1: 프로세스 스케줄링', due: '2025-09-20', status: '미제출'),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('홈'),
        automaticallyImplyLeading: false,
        backgroundColor: smBlue,
        foregroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _onRefresh,
            tooltip: '새로고침',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 상단 사용자 영역
            Row(
              children: [
                const CircleAvatar(radius: 28, child: Icon(Icons.person, size: 28)),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentUserName ?? '사용자',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    // Text(
                    //   '오늘 할 일 한눈에 보기',
                    //   style: TextStyle(fontSize: 13, color: Colors.black.withOpacity(0.6)),
                    // ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 오늘까지 과제
            _SectionCard(
              title: '오늘까지 과제',
              color: const Color(0xFF1A3276),
              child: FutureBuilder<List<DashboardAssignmentItem>>(
                future: _futureTodayAssignments,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const _Loading();
                  }
                  if (snap.hasError) {
                    return _ErrorText('과제를 불러오지 못했어요: ${snap.error}');
                  }
                  final items = snap.data ?? const <DashboardAssignmentItem>[];
                  if (items.isEmpty) {
                    return const _EmptyText('오늘까지 마감인 과제가 없습니다.');
                  }
                  return Column(
                    children: items.map((it) {
                      final dueStr = _fmtDue(it.due);
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.assignment_outlined),
                        title: Text(it.assignment.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text('${it.lecture.title} · 마감 $dueStr'),
                        trailing: Text(it.assignment.status, style: const TextStyle(fontWeight: FontWeight.bold)),
                        onTap: () {
                          Navigator.pushNamed(context, '/lecturedetail', arguments: it.lecture);
                        },
                      );
                    }).toList(),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // 미완료 동영상
            _SectionCard(
              title: '미완료 동영상',
              color: const Color(0xFF314E9B),
              child: FutureBuilder<List<DashboardVideoItem>>(
                future: _futureIncompleteVideos,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const _Loading();
                  }
                  if (snap.hasError) {
                    return _ErrorText('동영상을 불러오지 못했어요: ${snap.error}');
                  }
                  final items = snap.data ?? const <DashboardVideoItem>[];
                  if (items.isEmpty) {
                    return const _EmptyText('미완료 동영상이 없습니다.');
                  }
                  return Column(
                    children: items.map((it) {
                      final showWeek = (it.progress.week ?? '').trim().isNotEmpty ? '[${it.progress.week}] ' : '';
                      final percent = it.percent.clamp(0, 100).toStringAsFixed(0);
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.ondemand_video_outlined),
                        title: Text('$showWeek${it.progress.title ?? "(제목 없음)"}',
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(it.lecture.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: SizedBox(
                          width: 80,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Expanded(
                                child: LinearProgressIndicator(
                                  value: (it.percent / 100).clamp(0, 1),
                                  minHeight: 6,
                                  backgroundColor: Colors.black12,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text('$percent%'),
                            ],
                          ),
                        ),
                        onTap: () {
                          Navigator.pushNamed(context, '/lecturedetail', arguments: it.lecture);
                        },
                      );
                    }).toList(),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // 기존 목록(전체 강의)
            Text('내 강의 (${lectures.length})',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            if (isLoading)
              const _Loading()
            else if (lectures.isEmpty)
              const _EmptyText('등록된 강의가 없습니다.')
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: lectures.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (context, index) {
                  final lecture = lectures[index];
                  return _LectureTileHome(lecture: lecture);
                },
              ),
          ],
        ),
      ),
    );
  }

  String _fmtDue(DateTime? d) {
    if (d == null) return '-';
    final two = (int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Color color;
  final Widget child;
  const _SectionCard({required this.title, required this.color, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(width: 6, height: 18, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            ]),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _EmptyText extends StatelessWidget {
  final String text;
  const _EmptyText(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(text, style: const TextStyle(color: Colors.black54)),
    );
  }
}

class _ErrorText extends StatelessWidget {
  final String text;
  const _ErrorText(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(text, style: const TextStyle(color: Colors.red)),
    );
  }
}

/// 홈 리스트용 간단 타일 (강의 상세로 이동)
class _LectureTileHome extends StatelessWidget {
  final Lecture lecture;
  const _LectureTileHome({required this.lecture});

  static const Color sangmyungBlue = Color(0xFF1A3276);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: sangmyungBlue,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: const Icon(Icons.school, color: Colors.white),
        title: Text(
          lecture.title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            lecture.professor.isNotEmpty ? '${lecture.professor} 교수님' : '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white70, fontSize: 12.5),
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
        onTap: () {
          Navigator.pushNamed(context, '/lecturedetail', arguments: lecture);
        },
      ),
    );
  }
}
