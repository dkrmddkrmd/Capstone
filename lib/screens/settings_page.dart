import 'package:flutter/material.dart';

const Color smBlue = Color(0xFF1A3276); // 상명대 남색
const Color white = Colors.white;

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
        backgroundColor: smBlue,
        foregroundColor: Colors.white,
        elevation: 1,
      ),
      body: ListView(
        children: const [
          SettingTile(title: '다크 모드'),
          SettingTile(title: '알림 설정'),
          SettingTile(title: '앱 정보'),
          SettingTile(title: '버전: 1.0.0', isClickable: false),
        ],
      ),
    );
  }
}

class SettingTile extends StatelessWidget {
  final String title;
  final bool isClickable;

  const SettingTile({required this.title, this.isClickable = true, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: smBlue,
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(color: white, fontWeight: FontWeight.bold),
        ),
        trailing: isClickable
            ? const Icon(Icons.arrow_forward_ios, color: white, size: 16)
            : null,
        onTap: isClickable
            ? () {
                final messenger = ScaffoldMessenger.of(context);
                messenger.hideCurrentSnackBar();
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text(
                      '⚠️ 아직 개발 준비 중입니다',
                      style: TextStyle(color: white),
                    ),
                    backgroundColor: Colors.black87,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            : null,
      ),
    );
  }
}
