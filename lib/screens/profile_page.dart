import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  static const Color sangmyungBlue = Color(0xFF1A3276);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('마이페이지'),
        automaticallyImplyLeading: false,
        backgroundColor: sangmyungBlue,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // 프로필 헤더
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: const [
              CircleAvatar(radius: 50, child: Icon(Icons.person, size: 50)),
              SizedBox(height: 12),
              Text(
                '사용자',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text('컴퓨터과학과 · 2025학번', style: TextStyle(color: Colors.black54)),
            ],
          ),
          const SizedBox(height: 24),

          // 프로필 편집
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context)
                  ..clearSnackBars()
                  ..showSnackBar(
                    const SnackBar(content: Text('프로필 편집은 준비 중입니다.')),
                  );
              },
              icon: const Icon(Icons.edit),
              label: const Text('프로필 편집'),
              style: ElevatedButton.styleFrom(
                backgroundColor: sangmyungBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 계정/앱 설정 섹션
          _SectionTitle('계정'),
          _SettingTile(
            leading: const Icon(Icons.badge_outlined),
            title: '학번',
            trailingText: '2025XXXXX',
            onTap: null,
          ),
          _SettingTile(
            leading: const Icon(Icons.school_outlined),
            title: '전공',
            trailingText: '컴퓨터과학과',
            onTap: null,
          ),
          const SizedBox(height: 8),

          _SectionTitle('앱 설정'),
          _SettingTile(
            leading: const Icon(Icons.notifications_active_outlined),
            title: '알림 설정',
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              ScaffoldMessenger.of(context)
                ..clearSnackBars()
                ..showSnackBar(
                  const SnackBar(content: Text('알림 설정은 준비 중입니다.')),
                );
            },
          ),
          _SettingTile(
            leading: const Icon(Icons.dark_mode_outlined),
            title: '테마',
            trailingText: '시스템',
            onTap: () {
              ScaffoldMessenger.of(context)
                ..clearSnackBars()
                ..showSnackBar(
                  const SnackBar(content: Text('테마 변경은 준비 중입니다.')),
                );
            },
          ),
          _SettingTile(
            leading: const Icon(Icons.info_outline),
            title: '앱 정보',
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: '상명대 앱',
                applicationVersion: 'v0.1.0',
                applicationIcon: const Icon(Icons.school, color: sangmyungBlue),
              );
            },
          ),
          const SizedBox(height: 24),

          // 로그아웃
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final ok = await _confirmLogout(context);
                if (ok != true) return;
                // 로그인 화면으로 이동 (스택 정리)
                // ignore: use_build_context_synchronously
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              },
              icon: const Icon(Icons.logout),
              label: const Text('로그아웃'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 섹션 타이틀
class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Colors.black87,
        ),
      ),
    );
  }
}

// 설정 타일(좌측 아이콘 + 제목 + 우측 텍스트/아이콘)
class _SettingTile extends StatelessWidget {
  final Widget leading;
  final String title;
  final String? trailingText;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingTile({
    required this.leading,
    required this.title,
    this.trailingText,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Widget right =
        trailing ??
        (trailingText != null
            ? Text(trailingText!, style: const TextStyle(color: Colors.black54))
            : const SizedBox.shrink());

    return Material(
      color: Colors.white,
      child: ListTile(
        leading: leading,
        title: Text(title),
        trailing: right,
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      ),
    );
  }
}

// 로그아웃 확인 다이얼로그
Future<bool?> _confirmLogout(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('로그아웃'),
      content: const Text('정말 로그아웃하시겠습니까?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
          child: const Text('로그아웃'),
        ),
      ],
    ),
  );
}
