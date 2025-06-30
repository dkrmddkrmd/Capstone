import 'package:flutter/material.dart';

class DepartmentNoticePage extends StatelessWidget {
  const DepartmentNoticePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('전공 공지')),
      body: const Center(child: Text('전공별 공지 화면')),
    );
  }
}
