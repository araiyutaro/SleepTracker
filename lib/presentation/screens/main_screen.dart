import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'history_screen.dart';
import 'sleep_analytics_screen.dart';
import 'profile_screen.dart';
import '../../core/themes/app_theme.dart';
import '../../services/analytics_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = const [
    HomeScreen(),
    HistoryScreen(),
    SleepAnalyticsScreen(),
    ProfileScreen(),
  ];
  
  final List<String> _screenNames = const [
    'home',
    'history', 
    'analytics',
    'profile',
  ];

  @override
  void initState() {
    super.initState();
    // Analytics: アプリ開始イベント
    AnalyticsService().logAppOpened();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          // Analytics: 画面遷移イベント
          AnalyticsService().logScreenView(_screenNames[index]);
        },
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'ホーム',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: '履歴',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: '分析',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'プロフィール',
          ),
        ],
      ),
    );
  }
}