import 'package:flutter/material.dart';
import 'package:myproject/screens/calendar_page.dart';
import 'screens/home_page.dart';
import 'screens/department_notice_page.dart';
import 'screens/demonstrate_page.dart';
import 'screens/profile_page.dart';

class MainNavigationPage extends StatefulWidget {
  final int initialIndex;

  const MainNavigationPage({this.initialIndex = 0, super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  static const Color smBlue = Color(0xFF1A3276);

  late final PageController _pageController;
  late int _selectedIndex; // 현재 탭

  final List<Widget> _pages = const [
    HomePage(),
    HomeListPage(),
    // DemonstratePage(), 기존 시위정보 띄우기
    CalendarPage(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _selectedIndex);
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    _pageController.jumpToPage(index); // ← animateToPage 대신 jumpToPage
    setState(() => _selectedIndex = index);
  }

  void _onPageChanged(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 필요 시 테마 커스터마이즈
    // (예: indicatorColor 등) 여기서 감싸도 됨.
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics: const ClampingScrollPhysics(),
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
        // 선택 영역 표시 색상 살짝 커스텀하고 싶으면:
        // indicatorColor: smBlue.withOpacity(0.12),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: '홈',
          ),
          NavigationDestination(
            icon: Icon(Icons.campaign_outlined),
            selectedIcon: Icon(Icons.campaign),
            label: '전공 공지',
          ),
          // NavigationDestination(
          //   icon: Icon(Icons.flag_outlined),
          //   selectedIcon: Icon(Icons.flag),
          //   label: '시위 정보',
          // ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today),
            label: '캘린더',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: '마이',
          ),
        ],
      ),
    );
  }
}
