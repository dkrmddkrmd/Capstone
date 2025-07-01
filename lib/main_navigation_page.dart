import 'package:flutter/material.dart';
import 'screens/home_page.dart';
import 'screens/department_notice_page.dart';
import 'screens/demonstrate_page.dart';
import 'screens/profile_page.dart';
import 'screens/settings_page.dart';

class MainNavigationPage extends StatefulWidget {
  final int initialIndex; // 🔹 외부에서 초기 탭 인덱스를 받을 수 있도록 추가

  const MainNavigationPage({this.initialIndex = 0, super.key}); // 🔹 기본값은 0 (홈)

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  late PageController _pageController;
  late int _selectedIndex;

  static const Color smBlue = Color(0xFF1A3276);

  final List<Widget> _pages = const [
    HomePage(),
    DepartmentNoticePage(),
    DemonstratePage(),
    ProfilePage(),
    SettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex; // 🔹 초기 탭 인덱스 지정
    _pageController = PageController(
      initialPage: _selectedIndex,
    ); // 🔹 초기 페이지 설정
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.ease,
    );
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
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics: const ClampingScrollPhysics(),
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: smBlue,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.campaign), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.flag), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: ''),
        ],
      ),
    );
  }
}
