import 'package:flutter/material.dart';

import '../models/lecture.dart';
import '../models/assignment.dart';
import '../models/video_progress.dart';

import '../services/db_service.dart';
import '../services/video_progress_service.dart';
import '../services/progress_calc_service.dart';

import '../widget/assignment_card.dart';

// ✅ 상태는 두 가지만 유지
const List<String> kAssignmentStatusOptions = ['미제출', '제출'];

class LectureDetailPage extends StatefulWidget {
  const LectureDetailPage({super.key});

  @override
  State<LectureDetailPage> createState() => _LectureDetailPageState();
}

class _LectureDetailPageState extends State<LectureDetailPage> {
  late Lecture lecture;

  late Future<List<Assignment>> _futureAssignments;
  late Future<List<VideoProgress>> _futureProgress;

  bool _inited = false; // didChangeDependencies 1회 가드

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_inited) return;

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is! Lecture) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop();
      });
      return;
    }

    lecture = args;
    _futureAssignments = DBService().getAssignmentsByLectureId(lecture.localId!);
    _futureProgress = VideoProgressService().loadByLectureId(lecture.localId!);
    _inited = true;
  }

  void _reloadAssignments() {
    _futureAssignments = DBService().getAssignmentsByLectureId(lecture.localId!);
    if (mounted) setState(() {});
  }

  void _reloadProgress() {
    _futureProgress = VideoProgressService().loadByLectureId(lecture.localId!);
    if (mounted) setState(() {});
  }

  Future<void> _openAssignmentSheet({Assignment? initial}) async {
    final nameCtrl = TextEditingController(text: initial?.name ?? '');
    final dueCtrl = TextEditingController(text: initial?.due ?? '');

    // initial.status가 두 옵션 중 아니면 null로 시작 → 사용자가 선택
    String? status = kAssignmentStatusOptions.contains(initial?.status) ? initial!.status : null;
    final isEdit = initial != null;

    final shouldReload = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: 16 + MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isEdit ? '과제 수정' : '과제 추가',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: '과제명'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: dueCtrl,
                    decoration: const InputDecoration(labelText: '마감일 (ISO8601 또는 표시문구)'),
                  ),
                  const SizedBox(height: 8),

                  DropdownButtonFormField<String>(
                    value: status,
                    items: kAssignmentStatusOptions
                        .map((s) => DropdownMenuItem<String>(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) => setSheetState(() => status = v),
                    decoration: const InputDecoration(labelText: '상태'),
                    hint: const Text('상태 선택'),
                  ),

                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if (isEdit)
                        TextButton(
                          onPressed: () async {
                            await DBService().deleteAssignment(initial!.id!);
                            if (context.mounted) Navigator.pop(ctx, true);
                          },
                          child: const Text('삭제', style: TextStyle(color: Colors.red)),
                        ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('취소'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          final safeStatus = status ?? kAssignmentStatusOptions.first; // 기본 '미제출'
                          final a = Assignment(
                            id: initial?.id,
                            lectureId: lecture.localId,
                            name: nameCtrl.text.trim(),
                            due: dueCtrl.text.trim(),
                            status: safeStatus,
                          );

                          if (isEdit) {
                            await DBService().updateAssignment(a);
                          } else {
                            await DBService().addAssignment(lecture.localId!, a);
                          }
                          if (context.mounted) Navigator.pop(ctx, true);
                        },
                        child: Text(isEdit ? '저장' : '추가'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (shouldReload == true) _reloadAssignments();
  }

  @override
  Widget build(BuildContext context) {
    if (!mounted || ModalRoute.of(context)?.settings.arguments is! Lecture) {
      return const Scaffold(
        body: Center(child: Text('잘못된 파라미터입니다. (Lecture 필요)')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(lecture.title),
        backgroundColor: const Color(0xFF1A3276),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAssignmentSheet(),
        icon: const Icon(Icons.add),
        label: const Text('과제 추가'),
        backgroundColor: const Color(0xFF1A3276),
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _reloadAssignments();
          _reloadProgress();
        },
        child: Column(
          children: [
            // ------- 상단: 강의 헤더 (강의명 + 교수명 + 출석률: 실제 계산) -------
            FutureBuilder<List<VideoProgress>>(
              future: _futureProgress,
              builder: (context, snap) {
                final rows = snap.data ?? const <VideoProgress>[];
                final attendanceRate = ProgressCalcService.calcLectureAttendance(rows);
                return _HeaderCard(
                  title: lecture.title,
                  professor: lecture.professor,
                  attendanceRate: attendanceRate,
                );
              },
            ),

            // ------- 본문: 과제 + 동영상 진도 -------
            Expanded(
              child: ListView(
                children: [
                  // ----- 과제 섹션 -----
                  FutureBuilder<List<Assignment>>(
                    future: _futureAssignments,
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      if (snap.hasError) {
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text('과제를 불러오지 못했어요: ${snap.error}'),
                        );
                      }
                      final items = snap.data ?? [];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 섹션 타이틀
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                            child: Row(
                              children: [
                                const Icon(Icons.assignment_outlined, size: 18, color: Colors.black54),
                                const SizedBox(width: 6),
                                Text(
                                  '과제 (${items.length})',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.refresh, size: 18),
                                  onPressed: _reloadAssignments,
                                  tooltip: '과제 새로고침',
                                ),
                              ],
                            ),
                          ),
                          if (items.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Text('등록된 과제가 없습니다.'),
                            )
                          else
                            ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: items.length,
                              itemBuilder: (context, i) {
                                final a = items[i];
                                return Dismissible(
                                  key: ValueKey(a.id),
                                  direction: DismissDirection.endToStart,
                                  background: Container(
                                    alignment: Alignment.centerRight,
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    color: Colors.red,
                                    child: const Icon(Icons.delete, color: Colors.white),
                                  ),
                                  confirmDismiss: (_) async {
                                    final ok = await showDialog<bool>(
                                      context: context,
                                      builder: (dctx) => AlertDialog(
                                        title: const Text('삭제할까요?'),
                                        content: Text('과제 "${a.name}"를 삭제합니다.'),
                                        actions: [
                                          TextButton(
                                              onPressed: () => Navigator.pop(dctx, false),
                                              child: const Text('취소')),
                                          TextButton(
                                              onPressed: () => Navigator.pop(dctx, true),
                                              child: const Text('삭제')),
                                        ],
                                      ),
                                    );
                                    return ok ?? false;
                                  },
                                  onDismissed: (_) async {
                                    await DBService().deleteAssignment(a.id!);
                                    _reloadAssignments();
                                  },
                                  child: AssignmentCard(
                                    title: a.name,
                                    due: a.due,
                                    status: a.status,
                                    lectureTitle: lecture.title,
                                    onTap: () => _openAssignmentSheet(initial: a),
                                  ),
                                );
                              },
                            ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 8),

                  // ----- 동영상 진도 섹션 -----
                  FutureBuilder<List<VideoProgress>>(
                    future: _futureProgress,
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      if (snap.hasError) {
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text('동영상 진도를 불러오지 못했어요: ${snap.error}'),
                        );
                      }
                      final rows = snap.data ?? [];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 섹션 타이틀
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                            child: Row(
                              children: [
                                const Icon(Icons.ondemand_video_outlined, size: 18, color: Colors.black54),
                                const SizedBox(width: 6),
                                Text(
                                  '동영상 진도 (${rows.length})',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.refresh, size: 18),
                                  onPressed: _reloadProgress,
                                  tooltip: '진도 새로고침',
                                ),
                              ],
                            ),
                          ),

                          if (rows.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Text('동영상 진도 데이터가 없습니다.'),
                            )
                          else
                            ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: rows.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (context, i) {
                                final vp = rows[i];
                                final p = ProgressCalcService.calcItemPercent(vp); // 0~100
                                return _VideoProgressTile(vp: vp, percent: p);
                              },
                            ),
                        ],
                      );
                    },
                  ),

                  // 하단: 강의자료 (placeholder)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: const ListTile(
                        title: Text('강의자료'),
                        subtitle: Text('슬라이드, PDF, 영상 등 업로드됨'),
                        trailing: Icon(Icons.arrow_forward_ios),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- 헤더 카드 위젯 ----------------
class _HeaderCard extends StatelessWidget {
  final String title;
  final String professor;
  final double attendanceRate; // 0~100

  const _HeaderCard({
    required this.title,
    required this.professor,
    required this.attendanceRate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A3276), Color(0xFF314E9B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x22000000), blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          // 왼쪽: 텍스트
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 강의명
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                // 교수명
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 16, color: Colors.white70),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        professor.isNotEmpty ? '$professor 교수' : '교수 정보 없음',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white70, fontSize: 13.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // 오른쪽: 출석 링 (실제 값)
          _AttendanceRingBig(percent: attendanceRate),
        ],
      ),
    );
  }
}

// 큰 출석 링(헤더용)
class _AttendanceRingBig extends StatelessWidget {
  final double percent; // 0~100
  const _AttendanceRingBig({required this.percent});

  @override
  Widget build(BuildContext context) {
    final v = (percent.clamp(0, 100)) / 100.0;
    return SizedBox(
      width: 88,
      height: 88,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: v,
            strokeWidth: 8,
            backgroundColor: Colors.white.withOpacity(0.18),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
          Text(
            '${(v * 100).round()}%',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- 동영상 진도 타일 ----------------
class _VideoProgressTile extends StatelessWidget {
  final VideoProgress vp;
  final double percent; // 0~100

  const _VideoProgressTile({required this.vp, required this.percent});

  @override
  Widget build(BuildContext context) {
    final showWeek = (vp.week ?? '').trim().isNotEmpty ? '[${vp.week}] ' : '';
    final req = vp.requiredTimeText ?? '-';
    final tot = vp.totalTimeText ?? (vp.totalTimeSec != null ? _formatSec(vp.totalTimeSec!) : '-');
    final displayPercent = percent.isFinite ? percent : 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          '$showWeek${vp.title ?? '(제목 없음)'}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('출석인정 요구시간: $req'),
              Text('총 학습시간: $tot'),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: (displayPercent / 100).clamp(0, 1),
                  minHeight: 8,
                  backgroundColor: Colors.black12,
                ),
              ),
            ],
          ),
        ),
        trailing: Text('${displayPercent.toStringAsFixed(0)}%'),
      ),
    );
  }

  String _formatSec(int sec) {
    final h = sec ~/ 3600;
    final m = (sec % 3600) ~/ 60;
    final s = sec % 60;
    if (h > 0) {
      return '${_pad(h)}:${_pad(m)}:${_pad(s)}';
    } else {
      return '${_pad(m)}:${_pad(s)}';
    }
    // hh:mm:ss or mm:ss
  }

  String _pad(int n) => n.toString().padLeft(2, '0');
}
