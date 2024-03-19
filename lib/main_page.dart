import 'package:flutter/material.dart';
import 'bottom_bar.dart';

class MainPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Main Page'),
      ),
      body: Center(
        child: Text('Welcome to the Main Page!'),
      ),
      bottomNavigationBar: BottomNavScreen(
        selectedIndex: 0, // 当前页面的索引
        onItemSelected: (index) {
          // 处理页面切换
        },
      ),
    );
  }
}
