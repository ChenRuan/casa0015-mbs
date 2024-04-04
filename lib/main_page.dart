import 'package:eztour/plans_page.dart';
import 'package:eztour/settings_page.dart';
import 'package:eztour/travel_page.dart';
import 'package:flutter/material.dart';

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  // IndexedStack可以帮助我们保持每个页面的状态
  final List<Widget> _pages = [
    PlansPage(), // 首页Widget
    TravelPage(), // 消息页面Widget
    SettingsPage(), // 个人资料页面Widget
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Image.asset('assets/plans.png', width: 40, height: 40),
            label: 'Plans',
          ),
          BottomNavigationBarItem(
            icon: Image.asset('assets/travel.png', width: 40, height: 40),
            label: 'Travel',
          ),
          BottomNavigationBarItem(
            icon: Image.asset('assets/settings.png', width: 40, height: 40),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}