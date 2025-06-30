import 'package:flutter/material.dart';

class LectureDetailPage extends StatelessWidget {
  const LectureDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('강의 상세')),
      body: const Center(child: Text('강의 상세 & 과제 정보')),
    );
  }
}
