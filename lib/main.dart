import 'package:flutter/material.dart';
import 'package:myproject/main_navigation_page.dart';
import 'screens/login_page.dart';
import 'screens/home_page.dart';
import 'screens/lecture_detail_page.dart';
import 'screens/demonstrate_page.dart';
import 'screens/department_notice_page.dart';
import 'screens/settings_page.dart';

void main() => runApp(MyProject());

class MyProject extends StatelessWidget {
  const MyProject({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "상명대 앱",
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF1A3276)),
        scaffoldBackgroundColor: Colors.white, // 흰 배경
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/main': (context) => const MainNavigationPage(),
        '/home': (context) => const HomePage(),
        '/lecturedetail': (context) => const LectureDetailPage(),
        '/demoninfo': (context) => const DemonstratePage(),
        '/notices': (context) => const DepartmentNoticePage(),
        '/settings': (context) => const SettingsPage(),
      },
    );
  }
}
