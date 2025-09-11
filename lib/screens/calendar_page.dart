// pages/calendar_page.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:myproject/widget/assignment_card.dart';

import '../services/db_service.dart';
import '../services/video_progress_service.dart';
import '../services/progress_calc_service.dart';
import '../utils//filters.dart';

import '../models/lecture.dart';
import '../models/assignment.dart';
import '../models/video_progress.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  static const sangmyungBlue = Color(0xFF1A3276);
  static const _videoHighlightColor = Color(0xFFFFFF00); // 형광펜 노랑

  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  /// 날짜별 이벤트(과제 + 동영상)
  final Map<DateTime, List<_CalItem>> _events = {};
  /// 동영상이 있는 날짜 집합(연속 하이라이트용)
  final Set<DateTime> _videoDays = <DateTime>{};

  bool _loading = true;
  bool _showUntilToday = false; // 선택일까지 집계

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
        return Colors.red.shade700;
      case '제출':
        return Colors.green.shade400;
      default:
        return Colors.grey;
    }
  }

  // 동영상 아이콘 색 (리스트 표시용)
  Color _videoColor(double percent) {
    if (percent >= 100) return Colors.green.shade400;
    if (percent >= 50) return Colors.blue.shade400;
    return Colors.blue.shade700;
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
      final vp = VideoProgressService();

      // 강의(과제 포함) + 제목 필터
      final lecturesAll = await db.getAllLecturesWithAssignments();
      final lectures = lecturesAll
          .where((lec) => !shouldExcludeLectureByTitle(lec.title))
          .toList();

      // 1) 과제 → 날짜별 묶기
      final map = <DateTime, List<_CalItem>>{};
      for (final lec in lectures) {
        for (final a in lec.assignments) {
          final day = _parseToDay(a.due);
          if (day == null) continue;
          map.putIfAbsent(day, () => []);
          map[day]!.add(_DueItem(lectureTitle: lec.title, assignment: a));
        }
      }

      // 2) 동영상(미완료) → 날짜 세트 및 이벤트 추가
      _videoDays.clear();
      for (final lec in lectures) {
        if (lec.localId == null) continue;
        final rows = await vp.loadByLectureId(lec.localId!);
        for (final r in rows) {
          final percent = ProgressCalcService.calcItemPercent(r); // 0~100
          if (percent >= 100) continue; // 완료 제외

          final dates = _parseWeekRangeDays(r.week);
          if (dates.isEmpty) continue;

          final item = _VideoCalItem(
            lectureTitle: lec.title,
            progress: r,
            percent: percent,
          );

          for (final d in dates) {
            final key = DateTime(d.year, d.month, d.day);
            map.putIfAbsent(key, () => []);
            map[key]!.add(item);
            _videoDays.add(key); // ✅ 줄 연결용 날짜 기록
          }
        }
      }

      // 날짜별 정렬: 과제(미제출 우선) → 동영상(덜 본 순)
      for (final e in map.entries) {
        e.value.sort((x, y) {
          final typeOrder = x.type.index.compareTo(y.type.index);
          if (typeOrder != 0) return typeOrder;

          if (x is _DueItem && y is _DueItem) {
            final s = _statusRank(x.assignment.status) - _statusRank(y.assignment.status);
            if (s != 0) return s;
            return x.assignment.name.compareTo(y.assignment.name);
          }
          if (x is _VideoCalItem && y is _VideoCalItem) {
            return x.percent.compareTo(y.percent);
          }
          return 0;
        });
      }

      _events
        ..clear()
        ..addAll(map);

      _selectedDay = DateTime(_focusedDay.year, _focusedDay.month, _focusedDay.day);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // 상태 가중치(미제출 우선)
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
      final dt = DateTime.parse(raw);
      return DateTime(dt.year, dt.month, dt.day);
    } catch (_) {
      return null;
    }
  }

  // 현재 선택일이 속한 주(월~일) 생성 (week 범위를 못 찾을 때 폴백)
  List<DateTime> _weekDaysAround(DateTime base) {
    final start = DateTime(base.year, base.month, base.day)
        .subtract(Duration(days: base.weekday - DateTime.monday));
    return List.generate(7, (i) => DateTime(start.year, start.month, start.day + i));
  }

  // week 문자열에서 [M월D일 - M월D일] 범위를 추출 → 날짜 리스트
  // 없으면 현재 선택일 주(월~일)로 폴백
  List<DateTime> _parseWeekRangeDays(String? week) {
    if (week == null) return _weekDaysAround(_selectedDay);

    final text = week.replaceAll(' ', '');
    final bracket = RegExp(r'\[(.*?)\]').firstMatch(text)?.group(1);

    if (bracket == null) return _weekDaysAround(_selectedDay);

    final parts = bracket.split('-');
    if (parts.length != 2) return _weekDaysAround(_selectedDay);

    final startMD = _parseKorMonthDay(parts[0]);
    final endMD = _parseKorMonthDay(parts[1]);
    if (startMD == null || endMD == null) return _weekDaysAround(_selectedDay);

    final year = DateTime.now().year; // 학기 연도 가정
    final s = DateTime(year, startMD.$1, startMD.$2);
    final e = DateTime(year, endMD.$1, endMD.$2);
    if (e.isBefore(s)) return _weekDaysAround(_selectedDay);

    final days = <DateTime>[];
    var cur = s;
    while (!cur.isAfter(e)) {
      days.add(cur);
      cur = cur.add(const Duration(days: 1));
    }
    return days;
  }

  /// "9월08일" → (9, 8)
  (int, int)? _parseKorMonthDay(String s) {
    final m = RegExp(r'(\d{1,2})월(\d{1,2})일').firstMatch(s);
    if (m == null) return null;
    final mm = int.parse(m.group(1)!);
    final dd = int.parse(m.group(2)!);
    return (mm, dd);
  }

  List<_CalItem> _getEventsForDay(DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    if (_showUntilToday) {
      final List<_CalItem> agg = [];
      for (final entry in _events.entries) {
        if (!entry.key.isAfter(key)) {
          agg.addAll(entry.value);
        }
      }
      agg.sort((a, b) {
        final typeOrder = a.type.index.compareTo(b.type.index);
        if (typeOrder != 0) return typeOrder;
        if (a is _DueItem && b is _DueItem) {
          return _statusRank(a.assignment.status) - _statusRank(b.assignment.status);
        }
        if (a is _VideoCalItem && b is _VideoCalItem) {
          return a.percent.compareTo(b.percent);
        }
        return 0;
      });
      return agg;
    }
    return _events[key] ?? const [];
  }

  // ===== 줄 연결 판단 =====
  bool _isVideoDay(DateTime d) {
    final key = DateTime(d.year, d.month, d.day);
    return _videoDays.contains(key);
  }

  bool _isVideoPrev(DateTime d) {
    final prev = DateTime(d.year, d.month, d.day).subtract(const Duration(days: 1));
    // 행의 왼쪽 끝(월요일)은 연결하지 않음
    return d.weekday != DateTime.monday && _videoDays.contains(prev);
  }

  bool _isVideoNext(DateTime d) {
    final next = DateTime(d.year, d.month, d.day).add(const Duration(days: 1));
    // 행의 오른쪽 끝(일요일)은 연결하지 않음
    return d.weekday != DateTime.sunday && _videoDays.contains(next);
  }

  // TableCalendar의 eventLoader (마커 용)
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
                ? const Center(child: Text('표시할 항목이 없습니다.'))
                : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: selectedEvents.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final item = selectedEvents[i];
                if (item is _DueItem) {
                  final a = item.assignment;
                  final dueDay = _parseToDay(a.due);
                  final dueLabel = dueDay == null
                      ? a.due
                      : '${dueDay.year}-${_2(dueDay.month)}-${_2(dueDay.day)}';
                  return AssignmentCard(
                    title: a.name,
                    due: dueLabel,
                    status: a.status,
                    lectureTitle: item.lectureTitle,
                    onTap: () {},
                  );
                } else if (item is _VideoCalItem) {
                  final double p = math.min(100.0, math.max(0.0, item.percent));
                  final showWeek = (item.progress.week ?? '').trim().isNotEmpty
                      ? '[${item.progress.week}] '
                      : '';
                  final req = item.progress.requiredTimeText ?? '-';
                  final tot = item.progress.totalTimeText ??
                      (item.progress.totalTimeSec != null
                          ? _formatSec(item.progress.totalTimeSec!)
                          : '-');

                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading:
                      Icon(Icons.ondemand_video_outlined, color: _videoColor(p)),
                      title: Text(
                        '$showWeek${item.progress.title ?? "(제목 없음)"}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(item.lectureTitle,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text('출석인정 요구시간: $req · 총 학습시간: $tot'),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: math.min(1.0, math.max(0.0, p / 100.0)),
                              minHeight: 8,
                              backgroundColor: Colors.black12,
                            ),
                          ),
                        ],
                      ),
                      trailing: Text('${p.toStringAsFixed(0)}%'),
                      onTap: () {},
                    ),
                  );
                }
                return const SizedBox.shrink();
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
            label: const Text('선택일 항목'),
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
    return ConstrainedBox(
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
        calendarBuilders: CalendarBuilders(
          // ✅ 동영상 있는 날: 가운데 얇은 줄(스트립)로 연속 형광펜
          defaultBuilder: (context, day, focusedDay) {
            if (!_isVideoDay(day)) return null;

            final hasLeft  = _isVideoPrev(day);
            final hasRight = _isVideoNext(day);

            final radius = BorderRadius.only(
              topLeft:    hasLeft  ? const Radius.circular(3)  : const Radius.circular(10),
              bottomLeft: hasLeft  ? const Radius.circular(3)  : const Radius.circular(10),
              topRight:   hasRight ? const Radius.circular(3)  : const Radius.circular(10),
              bottomRight:hasRight ? const Radius.circular(3)  : const Radius.circular(10),
            );

            return Stack(
              children: [
                // 가운데 스트립 (가로로 쭉 이어지는 얇은 바)
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.center,
                    child: Container(
                      height: 12, // 두께
                      margin: const EdgeInsets.symmetric(horizontal: 0),
                      decoration: BoxDecoration(
                        color: _videoHighlightColor.withOpacity(0.38),
                        borderRadius: radius,
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x22000000),
                            blurRadius: 2,
                            offset: Offset(0, 1),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
                // 날짜 숫자(스트립 위에 표시)
                Center(
                  child: Text('${day.day}', style: const TextStyle(color: Colors.black87)),
                ),
              ],
            );
          },

          // ✅ 과제는 점 마커(동영상은 점 사용 X)
          markerBuilder: (context, day, events) {
            if (events.isEmpty) return const SizedBox.shrink();
            final dueItems = events.whereType<_DueItem>().toList();
            if (dueItems.isEmpty) return const SizedBox.shrink();

            const maxDots = 4;
            final dots = dueItems.take(maxDots).map((e) {
              final c = _statusColor(e.assignment.status);
              return Container(
                width: 6, height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(color: c, shape: BoxShape.circle),
              );
            }).toList();

            final extra = dueItems.length - maxDots;
            return Padding(
              padding: const EdgeInsets.only(top: 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ...dots,
                  if (extra > 0)
                    Padding(
                      padding: const EdgeInsets.only(left: 2),
                      child: Text('+$extra', style: const TextStyle(fontSize: 9, color: Colors.black54)),
                    ),
                ],
              ),
            );
          },
        ),
        calendarStyle: CalendarStyle(
          // ✅ 가로 여백 0으로 — 줄이 끊겨 보이지 않게
          cellMargin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
          todayDecoration: BoxDecoration(
            color: sangmyungBlue.withOpacity(0.18),
            shape: BoxShape.circle,
          ),
          selectedDecoration: const BoxDecoration(
            color: sangmyungBlue,
            shape: BoxShape.circle,
          ),
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
          _dotLegend(Colors.red.shade700, '과제: 미제출'),
          const SizedBox(width: 12),
          _dotLegend(Colors.green.shade400, '과제: 제출'),
          const SizedBox(width: 12),
          _highlightLegend(_videoHighlightColor, '동영상: 미완료(연속 줄)'),
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

  Widget _highlightLegend(Color c, String label) {
    return Row(
      children: [
        Container(
          width: 36, height: 12,
          decoration: BoxDecoration(color: c.withOpacity(0.38), borderRadius: BorderRadius.circular(8)),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.black87)),
      ],
    );
  }

  String _2(int n) => n.toString().padLeft(2, '0');

  String _formatSec(int sec) {
    final h = sec ~/ 3600;
    final m = (sec % 3600) ~/ 60;
    final s = sec % 60;
    if (h > 0) {
      return '${_2(h)}:${_2(m)}:${_2(s)}';
    } else {
      return '${_2(m)}:${_2(s)}';
    }
  }
}

/* ===== 내부 표시용 모델 / 타입 ===== */

enum _ItemType { assignment, video }

abstract class _CalItem {
  _ItemType get type;
}

class _DueItem extends _CalItem {
  final String lectureTitle;
  final Assignment assignment;
  _DueItem({required this.lectureTitle, required this.assignment});
  @override
  _ItemType get type => _ItemType.assignment;
}

class _VideoCalItem extends _CalItem {
  final String lectureTitle;
  final VideoProgress progress;
  final double percent; // 0~100
  _VideoCalItem({required this.lectureTitle, required this.progress, required this.percent});
  @override
  _ItemType get type => _ItemType.video;
}
