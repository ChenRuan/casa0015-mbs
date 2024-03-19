import 'package:flutter/material.dart';
import 'splash_screen.dart'; // 确保正确导入了splash_screen.dart

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      home: SplashScreen(), // 使用SplashScreen作为启动页面
    );
  }
}