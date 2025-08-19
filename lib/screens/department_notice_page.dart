import 'package:flutter/material.dart';

const smBlue = Color(0xFF1A3276);

class DepartmentNoticePage extends StatelessWidget {
  const DepartmentNoticePage({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: 실제 데이터 연동 시 리스트로 대체
    final notices = const <String>['공지사항 제목 1', '공지사항 제목 2', '공지사항 제목 3'];

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
              child: RefreshIndicator(
                onRefresh: () async {
                  // TODO: API 연동 시 재요청
                  await Future<void>.delayed(const Duration(milliseconds: 700));
                },
                child: notices.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [SizedBox(height: 120), _EmptyNotice()],
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: notices.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          return NoticeCard(title: notices[index]);
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

class _EmptyNotice extends StatelessWidget {
  const _EmptyNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        Icon(Icons.notifications_none, size: 56, color: Colors.black38),
        SizedBox(height: 12),
        Text(
          '등록된 공지가 없습니다.',
          style: TextStyle(fontSize: 16, color: Colors.black54),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class NoticeCard extends StatelessWidget {
  final String title;
  const NoticeCard({required this.title, super.key});

  @override
  Widget build(BuildContext context) {
    // 남색 카드 유지 + 리플/클립 보강
    return Material(
      color: smBlue,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias, // 리플이 둥근 모서리를 따르게
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.white,
        ),
        onTap: () {
          // TODO: 공지 상세 페이지로 이동
          // Navigator.pushNamed(context, '/noticeDetail', arguments: noticeId);
        },
      ),
    );
  }
}
