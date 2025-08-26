import 'package:flutter/material.dart';
import 'place_list_screen.dart';
import 'my_place_list_screen.dart';
import 'swim_diary_screen.dart';
import 'my_info_screen.dart';
import 'place_map_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  // 각 탭에 해당하는 위젯들을 리스트로 관리
  static final List<Widget> _widgetOptions = <Widget>[
    const PlaceListScreen(),
    const PlaceMapScreen(),
    const MyPlaceListScreen(),
    const SwimDiaryScreen(),
    const MyInfoScreen(),
  ];

  void _onItemTapped(int index) {
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: _widgetOptions,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: const Color(0xff757575),
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map_rounded),
            label: '수영장 지도',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pool_outlined),
            activeIcon: Icon(Icons.pool),
            label: '내 수영장',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.edit_calendar_outlined),
            activeIcon: Icon(Icons.edit_calendar),
            label: '수영 일기',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: '내 정보',
          ),
        ],
      ),
    );
  }
}