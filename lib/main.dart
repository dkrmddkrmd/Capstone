import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';

import 'package:myproject/main_navigation_page.dart';
import 'package:myproject/screens/login_page.dart';
import 'package:myproject/screens/lecture_detail_page.dart';

// 🔔 백그라운드 작업 콜백 (5-2에서 추가)
import 'background/task.dart'; // 파일 위치: lib/background/task.dart (아래 주석 참고)

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // WorkManager 초기화
  await Workmanager().initialize(
    callbackDispatcher,        // background/task.dart 내 함수
    isInDebugMode: false,      // 개발 중엔 true로 두고 로그 확인 가능
  );

  // 3시간마다 크롤링 동기화 작업 등록 (앱 최초 1회만 등록됨)
  await Workmanager().registerPeriodicTask(
    'crawlSyncUnique',         // unique name
    kTaskCrawlSync,            // task name (background/task.dart 상수)
    frequency: const Duration(hours: 3),
    initialDelay: const Duration(minutes: 5),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    constraints: Constraints(
      networkType: NetworkType.connected, // 온라인일 때만 실행
    ),
    backoffPolicy: BackoffPolicy.exponential,
    backoffPolicyDelay: const Duration(minutes: 10),
  );

  runApp(const MyProject());
}

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
