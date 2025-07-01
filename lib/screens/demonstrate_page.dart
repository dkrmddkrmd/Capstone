import 'package:flutter/material.dart';

const smBlue = Color(0xFF1A3276); // 상명대 남색

class DemonstratePage extends StatelessWidget {
  const DemonstratePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('시위 정보'),
        automaticallyImplyLeading: false,
        backgroundColor: smBlue,
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      body: Column(
        children: [
          // 🔹 버스 노선도 리스트 (상단 절반)
          Expanded(
            flex: 1,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: const [
                BusRouteTile(title: '1호선 노선도'),
                BusRouteTile(title: '2호선 노선도'),
                BusRouteTile(title: '셔틀버스 노선도'),
              ],
            ),
          ),

          // 🔸 중앙 구분선
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(color: Colors.grey[400], thickness: 0.8, height: 1),
          ),

          // 🔹 시위 달력 영역 (하단 절반)
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(20),
              alignment: Alignment.center,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade400, width: 1),
                ),
                width: double.infinity,
                height: double.infinity,
                alignment: Alignment.center,
                child: const Text(
                  '시위 달력',
                  style: TextStyle(fontSize: 18, color: Colors.black54),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BusRouteTile extends StatelessWidget {
  final String title;
  const BusRouteTile({required this.title, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: smBlue,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: const Icon(Icons.directions_bus, color: Colors.white),
        onTap: () {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('준비 중입니다')));
        },
      ),
    );
  }
}
