import 'package:flutter/material.dart';

const smBlue = Color(0xFF1A3276); // 상명대 남색

class DemonstratePage extends StatelessWidget {
  const DemonstratePage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('교통 & 시위 정보'),
          automaticallyImplyLeading: false,
          backgroundColor: smBlue,
          foregroundColor: Colors.white,
          elevation: 1,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            tabs: [
              Tab(icon: Icon(Icons.directions_bus), text: '교통 정보'),
              Tab(icon: Icon(Icons.event), text: '시위 정보'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _TransitTab(), // 교통 정보 탭
            _ProtestTab(), // 시위 정보 탭
          ],
        ),
      ),
    );
  }
}

/// 교통 정보 탭 (버스/지하철/셔틀 등)
class _TransitTab extends StatelessWidget {
  const _TransitTab({super.key});

  @override
  Widget build(BuildContext context) {
    final routes = const <String>['1호선 노선도', '2호선 노선도', '셔틀버스 노선도'];

    return RefreshIndicator(
      onRefresh: () async {
        // TODO: 실제 데이터/이미지/링크 갱신
        await Future<void>.delayed(const Duration(milliseconds: 700));
      },
      child: routes.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 120),
                _EmptyState(icon: Icons.directions_bus, text: '표시할 노선도가 없습니다.'),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: routes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => BusRouteTile(title: routes[i]),
            ),
    );
  }
}

/// 시위 정보 탭 (달력/리스트 등으로 확장 예정)
class _ProtestTab extends StatelessWidget {
  const _ProtestTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade400, width: 1),
        ),
        alignment: Alignment.center,
        child: const Text(
          '시위 달력 (준비 중)',
          style: TextStyle(fontSize: 18, color: Colors.black54),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;
  const _EmptyState({required this.icon, required this.text, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 56, color: Colors.black38),
        const SizedBox(height: 12),
        Text(text, style: const TextStyle(fontSize: 16, color: Colors.black54)),
      ],
    );
  }
}

class BusRouteTile extends StatelessWidget {
  final String title;
  const BusRouteTile({required this.title, super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: smBlue,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias, // 리플이 둥근 모서리 따라가게
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Colors.white,
          size: 16,
        ),
        onTap: () {
          // TODO: 노선도 상세(이미지/웹뷰/링크)로 이동
          // Navigator.pushNamed(context, '/routeDetail', arguments: routeId);
          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(const SnackBar(content: Text('준비 중입니다')));
        },
      ),
    );
  }
}
