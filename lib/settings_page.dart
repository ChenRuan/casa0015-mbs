import 'dart:convert';

import 'package:eztour/settings_login_page.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data.dart';
import 'main.dart';

import 'package:event_bus/event_bus.dart';

EventBus eventBus = EventBus();

class DownloadCompleteEvent {}

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isLoggedIn = false;
  String _username = '';

  @override
  void initState() {
    super.initState();
    // 在初始化时检查用户的登录状态
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      _username = prefs.getString('username') ?? '';
    });
  }

  Future<void> _logout() async {
    // 用户注销时清除保存的登录状态
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    await prefs.remove('username');
    _checkLoginStatus();
  }

  Future<void> downloadAndSaveData(String userId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    DatabaseReference userRef = FirebaseDatabase.instance.ref().child('users').child(userId);

    // 下载并保存Plans
    DataSnapshot plansSnapshot = await userRef.child('plans').get();
    if (plansSnapshot.exists) {
      Map<dynamic, dynamic> plans = plansSnapshot.value as Map<dynamic, dynamic>;
      List<String> plansJson = [];
      plans.forEach((key, value) {
        plansJson.add(json.encode(value));
      });
      print(plansJson);
      await prefs.setStringList('plans', plansJson);
    }

    // 下载并保存PlanItems
    DataSnapshot itemsSnapshot = await userRef.child('planItems').get();
    if (itemsSnapshot.exists) {
      Map<dynamic, dynamic> items = itemsSnapshot.value as Map<dynamic, dynamic>;
      items.forEach((key, value) async {
        List<String> itemsJson = [];
        Map<dynamic, dynamic> itemDetails = value;
        itemDetails.forEach((id, itemData) {
          itemsJson.add(json.encode(itemData));
        });
        print('$key,$itemsJson');
        await prefs.setStringList('$key', itemsJson);
      });
    }

    // 下载并保存TodoLists
    DataSnapshot todosSnapshot = await userRef.child('todolists').get();
    if (todosSnapshot.exists) {
      Map<dynamic, dynamic> todos = todosSnapshot.value as Map<dynamic, dynamic>;
      todos.forEach((key, value) {
        print('$key,${json.encode(value)}');
        prefs.setString('$key', json.encode(value));
      });
    }

    eventBus.fire(DownloadCompleteEvent());
    print('download finished');
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _buildSettingsList(context),
        ),
      ),
    );
  }

  Future<void> confirmDownload(String userId) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Download'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('You are about to download data from the cloud.', style: TextStyle(fontSize:16,)),
                Text('*This may cause loss of current data.', style: TextStyle(fontSize:12,color: Colors.red)),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Download'),
              onPressed: () {
                Navigator.of(context).pop();
                downloadAndSaveData(userId);
              },
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildSettingsList(BuildContext context) {
    List<Widget> settingsList = [];

    if (_isLoggedIn) {
      // 如果已登录
      settingsList.add(
          ListTile(
            title: Text('User: $_username',style:TextStyle(fontSize: 18),),
            leading: Icon(Icons.person),
          )
      );
      settingsList.add(Divider());

      settingsList.add(
          ListTile(
            title: const Text('Logout',style:TextStyle(fontSize: 18),),
            leading: Icon(Icons.exit_to_app),
            onTap: _logout,
          )
      );
      settingsList.add(Divider());

      settingsList.add(
          ListTile(
            title: const Text('Upload data to Cloud',style:TextStyle(fontSize: 18),),
            leading: Icon(Icons.cloud_upload),
            onTap: () {
              FirebaseUploader().uploadSharedPreferencesData(_username,context);
              scaffoldMessengerKey.currentState?.showSnackBar(SnackBar(content: Text('Upload finished!')));
            },
          )
      );
      settingsList.add(Divider());

      settingsList.add(
          ListTile(
            title: const Text('Download data From Cloud',style:TextStyle(fontSize: 18),),
            leading: Icon(Icons.cloud_download),
            onTap: () {
              confirmDownload(_username);
              scaffoldMessengerKey.currentState?.showSnackBar(SnackBar(content: Text('Download finished!')));
            },
          )
      );
      settingsList.add(Divider());
    } else {
      settingsList.add(
          ListTile(
            title: const Text('Login',style:TextStyle(fontSize: 18),),
            leading: Icon(Icons.login),
            onTap: () async {
              final userEmail = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LoginPage(),
                ),
              );
              if (userEmail != null) {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.setBool('isLoggedIn', true);
                await prefs.setString('username', userEmail);
                _checkLoginStatus();
              }
            },
          )
      );
      settingsList.add(Divider());
    }

    settingsList.add(
        ListTile(
          title: Text('Version: 0.6.2',style:TextStyle(fontSize: 20),),
          leading: Icon(Icons.update),
          onTap: () {
            // Implement check for updates logic
          },
        )
    );
    settingsList.add(Divider());

    return settingsList;
  }
}

class FirebaseUploader {
  final DatabaseReference _databaseReference =
  FirebaseDatabase.instance.ref();

  Future<void> uploadSharedPreferencesData(String userId, BuildContext context) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> plansList = prefs.getStringList('plans') ?? [];

      DatabaseReference userRef = _databaseReference.child('users').child(userId);

      // 转换并上传Plan数据

      for (String planJson in plansList) {
        Plan plan = Plan.fromJson(jsonDecode(planJson));
        await _uploadPlan(userRef, plan);
      }

      try {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        Set<String> keys = prefs.getKeys(); // 获取所有键

        // 遍历所有键，查找以 "items_" 开头的键
        for (String key in keys) {
          if (key.startsWith('items_')) {
            List<String>? itemsJson = prefs.getStringList(key);
            if (itemsJson != null) {
              List<PlanItem> items = itemsJson
                  .map((itemJson) => PlanItem.fromJson(json.decode(itemJson) as Map<String, dynamic>))
                  .toList();

              // 逐个上传计划项目
              for (PlanItem item in items) {
                await _uploadPlanItem(userRef,item,key);
              }
            }
          }
        }
      } catch (e) {
        print('Error loading and uploading plan items: $e');
      }

      try {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        Set<String> keys = prefs.getKeys(); // 获取所有键

        // 遍历所有键，查找以 "todo_" 开头的键
        for (String key in keys) {
          if (key.startsWith('todo_')) {
            String? todoListJson = prefs.getString(key);
            if (todoListJson != null) {
              print('Original TodoList JSON for key $key: $todoListJson');
              Map<String, dynamic>? decodedData = json.decode(todoListJson);
              if (decodedData != null) {
                // 确保解码的数据是一个 Map 类型
                Todolist todolist = Todolist.fromJson(decodedData);
                await _uploadTodolist(userRef, todolist, key);
              } else {
                print('Error decoding TodoList JSON for key $key');
              }
            }
          }
        }
      } catch (e) {
        print('Error loading and uploading todo lists: $e');
      }
      print('SharedPreferences data uploaded successfully');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload succeeded')));
    } catch (e) {
      print('Error uploading SharedPreferences data: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    }
  }

  Future<void> _uploadPlan(DatabaseReference userRef, Plan plan) async {
    try {
      await userRef.child('plans').child(plan.id).set(plan.toJson());
      print('Plan uploaded successfully: ${plan.id}');
    } catch (e) {
      print('Error uploading plan: $e');
    }
  }

  Future<void> _uploadPlanItem(DatabaseReference userRef, PlanItem planItem,String key) async {
    try {
      await userRef.child('planItems').child(key).child(planItem.id).set(planItem.toJson());
      print('PlanItem uploaded successfully: ${planItem.id}');
    } catch (e) {
      print('Error uploading planItem: $e');
    }
  }

  Future<void> _uploadTodolist(DatabaseReference userRef, Todolist todolist,String key) async {
    try {
      await userRef.child('todolists').child(key).set(todolist.toJson());
      print('Todolist uploaded successfully: ${todolist.uid}');
    } catch (e) {
      print('Error uploading todolist: $e');
    }
  }
}

