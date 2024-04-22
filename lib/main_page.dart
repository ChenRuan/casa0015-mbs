import 'dart:convert';

import 'package:eztour/data.dart';
import 'package:eztour/plans_page.dart';
import 'package:eztour/settings_page.dart';
import 'package:eztour/travel_mode_page.dart';
import 'package:eztour/travel_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    checkTravelState();
  }

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

  void checkTravelState() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isTraveling = prefs.getBool('isTraveling') ?? false;
    String? planStr = prefs.getString('plan');

    if (isTraveling && planStr != null) {
      Plan plan = Plan.fromJson(json.decode(planStr));
      DateTime now = DateTime.now();

      if (now.isAfter(plan.startDate) && now.isBefore(plan.endDate.add(Duration(days: 1)))) {
        // 如果当前时间在旅行时间内
        _askToContinueTraveling(plan);
      }
    }
  }

  void _askToContinueTraveling(Plan plan) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('继续旅行'),
          content: Text('您上次还在旅行中，是否要继续?'),
          actions: <Widget>[
            TextButton(
              child: Text('取消'),
              onPressed: () {
                Navigator.of(context).pop();
                clearTravelState(); // 清除状态
              },
            ),
            TextButton(
              child: Text('继续'),
              onPressed: () {
                Navigator.of(context).pop();
                goToPlanModePage(plan);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> clearTravelState() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('isTraveling');
    await prefs.remove('plan');
  }

  void goToPlanModePage(Plan plan) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TravelModePage(plan: plan),
      ),
    );
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