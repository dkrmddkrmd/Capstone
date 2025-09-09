import 'package:flutter/material.dart';
import '../models/lecture.dart';
import '../models/assignment.dart';
import '../services/db_service.dart';
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
    _inited = true;
  }

  void _reloadAssignments() {
    _futureAssignments = DBService().getAssignmentsByLectureId(lecture.localId!);
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

    final double attendanceRate = 50; // TODO: 실제 값 연결

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
      body: Column(
        children: [
          // ------- 상단: 강의 헤더 (강의명 + 교수명 + 출석률) -------
          _HeaderCard(
            title: lecture.title,
            professor: lecture.professor, // ✅ 교수명 노출
            attendanceRate: attendanceRate,
          ),

          // ------- 과제 목록 -------
          Expanded(
            child: FutureBuilder<List<Assignment>>(
              future: _futureAssignments,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: Text('과제를 불러오지 못했어요: ${snap.error}'));
                }
                final items = snap.data ?? [];
                if (items.isEmpty) {
                  return const Center(child: Text('등록된 과제가 없습니다.'));
                }

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
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                              status: a.status,                 // ✅ '미제출' / '제출'
                              lectureTitle: lecture.title,       // ✅ 강의색 일관성 (버그 수정)
                              onTap: () => _openAssignmentSheet(initial: a),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
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
                // ✅ 교수명
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
          // 오른쪽: 출석 링
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
