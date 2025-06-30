import 'package:flutter/material.dart';

class DemonstratePage extends StatelessWidget {
  const DemonstratePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('시위 정보')),
      body: const Center(
        child: Text('시위 일정 및 정보 페이지입니다.'),
      ),
    );
  }
}
