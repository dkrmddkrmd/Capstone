import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';

// 화면
import 'package:myproject/main_navigation_page.dart';
import 'package:myproject/screens/login_page.dart';
import 'package:myproject/screens/register_page.dart';
import 'package:myproject/screens/lecture_detail_page.dart';

// 🔔 백그라운드 작업 콜백/상수
import 'package:myproject/background/task.dart'; // callbackDispatcher, kTaskCrawlSync

Future<void> _initBackgroundTasks() async {
  if (!Platform.isAndroid) return; // Workmanager는 Android 전용 사용

  // WorkManager 초기화
  await Workmanager().initialize(
    callbackDispatcher,              // lib/background/task.dart 내 @pragma('vm:entry-point') 함수
    isInDebugMode: !kReleaseMode,    // 개발 중엔 true로 로그 보기
  );

  // 3시간마다 크롤링 동기화 작업 (최소 주기는 15분, 3시간 OK)
  await Workmanager().registerPeriodicTask(
    'crawlSyncUnique',               // unique name
    kTaskCrawlSync,                  // task name (task.dart의 상수)
    frequency: const Duration(hours: 3),
    initialDelay: const Duration(minutes: 5),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep, // 이미 있으면 유지
    backoffPolicy: BackoffPolicy.exponential,
    backoffPolicyDelay: const Duration(minutes: 10),
    constraints: Constraints(
      networkType: NetworkType.connected, // 온라인에서만
      // requiresBatteryNotLow: true,      // 필요시 추가
      // requiresCharging: true,           // 필요시 추가
    ),
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Android에서만 백그라운드 작업 초기화
  await _initBackgroundTasks();

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
        '/register': (_) => const RegisterPage(),          // ✅ 등록 라우트 추가
        '/main': (_) => const MainNavigationPage(),
        '/lecturedetail': (_) => const LectureDetailPage(),
      },
    );
  }
}
