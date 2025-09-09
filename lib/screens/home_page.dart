// pages/home_page.dart (DB 우선 + 새로고침 = API 동기화 + 자격체크/리다이렉트)
import 'package:flutter/material.dart';
import '../models/assignment.dart';
import '../models/lecture.dart';

// ✅ Repository 기반
import '../services/db_service.dart';
import '../services/lecture_repository.dart';
// ✅ 로그인 자격 보관 확인
import '../services/secure_storage.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // TODO: 이후 colors.dart로 이동
  static const Color smBlue = Color(0xFF1A3276); // 상명대 남색

  final _repo = LectureRepository();

  List<Lecture> lectures = [];
  bool isLoading = true;
  String? errorMessage;
  String? currentUserName; // ✅ 사용자 이름 저장


  @override
  void initState() {
    super.initState();
    _bootstrap(); // ✅ 먼저 자격 체크 → 로드/리다이렉트 분기
  }

  /// ✅ 앱 진입 시 자격 보유 여부 확인 → 없으면 로그인으로 이동
  Future<void> _bootstrap() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final hasCreds = await SecureStore.hasCreds();
    if (!mounted) return;

    if (!hasCreds) {
      // 사용자 안내 후 로그인으로
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 필요합니다')),
      );
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    // 자격이 있으면 평소처럼 로드
    await _loadLecturesPreferLocal();
    await _loadUserName(); // ✅ 사용자 이름 로드

  }
  Future<void> _loadUserName() async {
    final db = DBService();
    final uid = await db.getAnySavedUserId();

    if (uid != null) {
      final row = await db.getUserByUserId(uid);
      final dbName = (row?['userName'] as String?)?.trim();
      setState(() {
        currentUserName = dbName;
      });

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('디버그'),
            content: Text('uid=$uid\nuserName=$dbName'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('확인'),
              ),
            ],
          ),
        );
      }
    } else {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('디버그'),
            content: const Text('DB에 저장된 User가 없습니다.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('확인'),
              ),
            ],
          ),
        );
      }
    }
  }


  /// ✅ DB 우선 로드 (DB가 비면 내부적으로 API→DB 저장 후 DB 반환)
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

  /// ✅ 수동 새로고침: 자격 있으면 API 동기화 → DB 재조회
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
  }

  // 더미 데이터 (개발/테스트용)
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
      Lecture(
        title: '알고리즘',
        professor: '박교수',
        link: 'https://ecampus.smu.ac.kr/course/view.php?id=1003',
        assignments: [],
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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(radius: 30, child: Icon(Icons.person, size: 30)),
                const SizedBox(width: 12),
                Text(
                  currentUserName ?? '사용자', // ✅ DB 값 있으면 대체
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _onRefresh,
                child: _buildLectureList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLectureList() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('강의 목록을 불러오는 중...'),
          ],
        ),
      );
    }

    if (lectures.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 80),
          Center(
            child: Column(
              children: [
                Icon(Icons.school_outlined, size: 64, color: Colors.black38),
                SizedBox(height: 16),
                Text(
                  '등록된 강의가 없습니다.',
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      itemCount: lectures.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final lecture = lectures[index];
        return LectureTile(lecture: lecture);
      },
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
    this.color = const Color(0xFF1A3276),
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
        leading: const AttendanceRing(
          percent: 50, // TODO: 출석률 연동되면 교체
          size: 44,
          color: Colors.white,
        ),
        title: Text(
          lecture.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        // ✅ 교수명 표시
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            lecture.professor.isNotEmpty ? '${lecture.professor} 교수님' : '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12.5,
            ),
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

