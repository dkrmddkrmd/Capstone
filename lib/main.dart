import 'package:flutter/material.dart';
import 'package:myproject/main_navigation_page.dart';
import 'package:myproject/screens/login_page.dart';
import 'package:myproject/screens/lecture_detail_page.dart';

void main() => runApp(const MyProject());

class MyProject extends StatelessWidget {
  const MyProject({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '상명대 앱',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A3276)),
        scaffoldBackgroundColor: Colors.white,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (_) => const LoginPage(),
        '/main': (_) => const MainNavigationPage(),
        '/lecturedetail': (_) => const LectureDetailPage(),
      },
    );
  }
}
