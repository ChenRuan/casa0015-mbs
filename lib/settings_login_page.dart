import 'package:eztour/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _signInWithEmailAndPassword(context);
              },
              child: Text('Sign In'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                _registerWithEmailAndPassword();
              },
              child: Text('Register'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _signInWithEmailAndPassword(BuildContext context) async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      final User? user = userCredential.user;
      // 登录成功后的处理
      if (user != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Signed in successfully!')));
        Navigator.pop(context, userCredential.user?.email?.split('@').first); // 关闭登录页面
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to sign in. ${e.toString()}')));
    }
  }

  Future<void> _registerWithEmailAndPassword() async {
    try {
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );
      final User? user = userCredential.user;
      // 注册成功后的处理
      if (user != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Registered successfully!')));
        // 进行页面跳转等操作
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to register. ${e.toString()}')));
    }
  }
}

void main() {
  runApp(MaterialApp(
    title: 'Login Demo',
    theme: ThemeData(primarySwatch: Colors.blue),
    initialRoute: '/',
    routes: {
      '/': (context) => LoginPage(),
      '/settings': (context) => SettingsPage(),
    },
  ));
}
