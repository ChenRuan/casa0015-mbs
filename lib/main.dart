import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // 导入 Firebase Core 包
import 'package:provider/provider.dart';
import 'splash_screen.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化 Firebase App
  Firebase.initializeApp().then((_) {
    runApp(
      ChangeNotifierProvider<ApplicationState>(
        create: (context) => ApplicationState(),
        child: MyApp(),
      ),
    );
  });
}

class ApplicationState with ChangeNotifier {

}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        primaryColor: Colors.white,
        bottomAppBarTheme: BottomAppBarTheme(color: Colors.white), // 设置底部导航栏的颜色
      ),
      home: SplashScreen(),
    );
  }
}