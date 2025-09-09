import 'package:flutter/material.dart';
import 'package:myproject/widget/assignment_card.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/db_service.dart';
import '../models/assignment.dart';
import '../models/lecture.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  static const sangmyungBlue = Color(0xFF1A3276);

  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  // 날짜별 과제 맵
  final Map<DateTime, List<_DueItem>> _events = {};
  bool _loading = true;
  bool _showUntilToday = false; // 오늘까지(마감 임박) 토글

  // ----- Color helpers -----
  // ----- Color helpers -----
  final List<Color> _lecturePalette = const [
    Color(0xFF6C8AE4), // indigo
    Color(0xFFEBA04D), // orange
    Color(0xFFDB6E7E), // rose
    Color(0xFF9A7FD1), // purple
    Color(0xFF52B9C9), // teal
    Color(0xFFF06292), // pink
    Color(0xFF4DB6AC), // turquoise
    Color(0xFFFFB74D), // amber
    Color(0xFF9575CD), // violet
    Color(0xFF81C784), // light green
    Color(0xFF64B5F6), // light blue
  ];
  Color _lectureColor(String title) {
    final h = title.hashCode;
    return _lecturePalette[h.abs() % _lecturePalette.length];
  }

  Color _statusColor(String s) {
    switch (s) {
      case '미제출':
        return Colors.red.shade700;   // 진한 빨강
      case '제출':
        return Colors.green.shade400; // 연한 초록
      default:
        return Colors.grey;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadFromDb();
  }

  Future<void> _loadFromDb() async {
    setState(() => _loading = true);
    try {
      final db = DBService();
      final lectures = await db.getAllLecturesWithAssignments(); // List<Lecture> (과제 포함)
      _events
        ..clear()
        ..addAll(_groupAssignmentsByDay(lectures));

      // 선택된 날짜에 맞춰 스크롤 포커스
      _selectedDay = DateTime(
        _focusedDay.year,
        _focusedDay.month,
        _focusedDay.day,
      );
    } catch (_) {
      // 에러는 조용히 무시하고 빈 상태 유지
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // 날짜별로 묶기
  Map<DateTime, List<_DueItem>> _groupAssignmentsByDay(List<Lecture> lectures) {
    final map = <DateTime, List<_DueItem>>{};
    for (final lec in lectures) {
      for (final a in lec.assignments) {
        final day = _parseToDay(a.due);
        if (day == null) continue;
        map.putIfAbsent(day, () => []);
        map[day]!.add(_DueItem(
          lectureTitle: lec.title,
          assignment: a,
        ));
      }
    }
    // due 같은 날 여러개 정렬(상태/이름 기준 등)
    for (final e in map.entries) {
      e.value.sort((x, y) {
        final s = _statusRank(x.assignment.status) - _statusRank(y.assignment.status);
        if (s != 0) return s;
        return x.assignment.name.compareTo(y.assignment.name);
      });
    }
    return map;
  }

// 상태 가중치(미제출이 먼저 나오게)
  int _statusRank(String s) {
    switch (s) {
      case '미제출':
        return 0;
      case '제출':
        return 1;
      default:
        return 2;
    }
  }

  // 문자열 due -> 날짜(시분초 제거)
  DateTime? _parseToDay(String raw) {
    if (raw.isEmpty) return null;
    try {
      // ISO 8601 또는 "YYYY-MM-DD" 등 일반 포맷 시도
      final dt = DateTime.parse(raw);
      return DateTime(dt.year, dt.month, dt.day);
    } catch (_) {
      // 위 포맷이 아니면 추가 포맷을 여기서 필요시 확장
      // 예: 2025.09.20, 2025/09/20 등 커스텀 파싱
      // 간단히 실패 시 null
      return null;
    }
  }

  List<_DueItem> _getEventsForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    if (_showUntilToday) {
      // 선택일까지 마감인 과제
      final List<_DueItem> agg = [];
      for (final entry in _events.entries) {
        if (!entry.key.isAfter(key)) {
          agg.addAll(entry.value);
        }
      }
      // 정렬: 날짜 오름차 + 상태
      agg.sort((a, b) {
        final da = _parseToDay(a.assignment.due)!;
        final db = _parseToDay(b.assignment.due)!;
        final cmp = da.compareTo(db);
        if (cmp != 0) return cmp;
        return _statusRank(a.assignment.status) - _statusRank(b.assignment.status);
      });
      return agg;
    }
    return _events[key] ?? const [];
  }

  // 날짜 셀에 찍을 이벤트 개수 점 (TableCalendar 기본 마커 용)
  List<dynamic> _eventLoader(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return _events[key] ?? const [];
  }

  @override
  Widget build(BuildContext context) {
    final selectedEvents = _getEventsForDay(_selectedDay);

    return Scaffold(
      appBar: AppBar(
        title: const Text('캘린더'),
        backgroundColor: sangmyungBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFromDb,
            tooltip: '새로고침',
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          const SizedBox(height: 8),
          _buildHeaderToggle(),
          _buildCalendar(),
          _buildLegend(),
          const Divider(height: 1),
          Expanded(
            child: selectedEvents.isEmpty
                ? const Center(child: Text('표시할 과제가 없습니다.'))
                : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: selectedEvents.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final item = selectedEvents[i];
                final a = item.assignment;
                final lectureColor = _lectureColor(item.lectureTitle);
                final statusColor = _statusColor(a.status);
                final dueDay = _parseToDay(a.due);
                final dueLabel = dueDay == null
                    ? a.due
                    : '${dueDay.year}-${_2(dueDay.month)}-${_2(dueDay.day)}';

                return AssignmentCard(
                  title: a.name,
                  due: dueLabel,
                  status: a.status,
                  lectureTitle: item.lectureTitle,
                  onTap: () {
                    // 필요하면 과제 편집 바텀시트로 이동하도록 연결
                    // Navigator.pushNamed(context, '/lecturedetail', arguments: ...);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          FilterChip(
            label: const Text('선택일 마감'),
            selected: !_showUntilToday,
            onSelected: (_) => setState(() => _showUntilToday = false),
            selectedColor: sangmyungBlue.withOpacity(0.15),
            checkmarkColor: sangmyungBlue,
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('선택일까지'),
            selected: _showUntilToday,
            onSelected: (_) => setState(() => _showUntilToday = true),
            selectedColor: Colors.red.withOpacity(0.12),
            checkmarkColor: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return ConstrainedBox( // ❗ overflow 방지
      constraints: const BoxConstraints(maxHeight: 420),
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2035, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (d) =>
        d.year == _selectedDay.year && d.month == _selectedDay.month && d.day == _selectedDay.day,
        onDaySelected: (selected, focused) {
          setState(() {
            _selectedDay = DateTime(selected.year, selected.month, selected.day);
            _focusedDay = focused;
          });
        },
        onPageChanged: (focused) => _focusedDay = focused,
        eventLoader: _eventLoader,
        // ------- 예쁜 마커 빌더: 상태별 색 점 여러 개 + 개수 -------
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, day, events) {
            if (events.isEmpty) return const SizedBox.shrink();
            final dueItems = events.cast<_DueItem>();
            // 상태 색으로 최대 4개 점 표시 (그 이상은 +n)
            final maxDots = 4;
            final dots = dueItems.take(maxDots).map((e) {
              final c = _statusColor(e.assignment.status);
              return Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(color: c, shape: BoxShape.circle),
              );
            }).toList();

            final extra = dueItems.length - maxDots;
            return Padding(
              padding: const EdgeInsets.only(top: 30), // 날짜 숫자 아래쪽
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ...dots,
                  if (extra > 0)
                    Padding(
                      padding: const EdgeInsets.only(left: 2),
                      child: Text(
                        '+$extra',
                        style: const TextStyle(fontSize: 9, color: Colors.black54),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            color: sangmyungBlue.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          selectedDecoration: const BoxDecoration(
            color: sangmyungBlue,
            shape: BoxShape.circle,
          ),
          // 기본 markerDecoration은 markerBuilder를 쓰면 무시됨
        ),
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
        ),
        locale: 'ko_KR',
      ),
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          _dotLegend(Colors.red.shade700, '미제출'),
          const SizedBox(width: 12),
          _dotLegend(Colors.green.shade400, '제출'),
        ],
      ),
    );
  }

  Widget _dotLegend(Color c, String label) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.black87)),
      ],
    );
  }

  String _2(int n) => n.toString().padLeft(2, '0');
}

// 내부 표시용 모델
class _DueItem {
  final String lectureTitle;
  final Assignment assignment;
  _DueItem({required this.lectureTitle, required this.assignment});
}