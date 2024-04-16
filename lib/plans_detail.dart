import 'package:eztour/plans_add_new_item_forms.dart';
import 'package:eztour/plans_add_new_item_tdl.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:eztour/plans_add_new_item.dart'; // 确保这个路径与你的项目结构匹配
import 'package:eztour/data.dart'; // 假设这里定义了你的 Plan 类和其他相关数据结构
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class PlanDetailPage extends StatefulWidget {
  final Plan plan;

  PlanDetailPage({Key? key, required this.plan}) : super(key: key);

  @override
  _PlanDetailPageState createState() => _PlanDetailPageState();
}

class _PlanDetailPageState extends State<PlanDetailPage> {
  late int _currentDay;
  late int _totalDays;
  final double arrowButtonPadding = 16.0;  // 你可以根据需要调整这个值
  List<PlanItem> _planItems = [];

  @override
  void initState() {
    super.initState();
    _currentDay = 0;  // 初始化为Day 0
    _totalDays = widget.plan.travelDays; // 不再额外加1，以匹配天数
    _loadPlanItems();
  }

  Future<List<Map<String, dynamic>>> _loadToDoLists() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((key) => key.startsWith('todo_${widget.plan.id}_$_currentDay')).toList();
    List<Map<String, dynamic>> allLists = [];

    for (String key in keys) {
      String? savedData = prefs.getString(key);
      if (savedData != null) {
        try {
          var decodedData = jsonDecode(savedData);
          if (decodedData is Map) {
            allLists.add({
              'uid': decodedData['uid'],
              'title': decodedData['title'],
              'tasks': decodedData['tasks'],
            });
          } else {
            print("Unexpected JSON format for key $key");
          }
        } catch (e) {
          print("Error parsing ToDo list data for key $key: $e");
        }
      }
    }
    return allLists;
  }



  Widget _buildHorizontalToDoLists() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _loadToDoLists(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            return SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  var listData = snapshot.data![index];
                  List<dynamic> tasks = listData['tasks'] as List<dynamic>;
                  int completedCount = tasks.where((t) => t['completed'] as bool).length;
                  bool allCompleted = completedCount == tasks.length;
                  return InkWell(
                    onTap: () {
                      if (snapshot.data != null) {
                        var listData = snapshot.data![index];
                        List<String> tasks = listData['tasks'].map<String>((t) => t['task'].toString()).toList();
                        List<String> taskCompletionStatus = listData['tasks'].map<String>((t) => t['completed'].toString()).toList();
                        Navigator.push(context, MaterialPageRoute(builder: (context) => ToDoListPage(
                          planId: widget.plan.id,
                          day: _currentDay,
                          uid: listData['uid'],
                          title: listData['title'],
                          tasks: tasks,
                          taskCompletionStatus: taskCompletionStatus,
                        )));
                      }
                    },
                    child: Card(
                      child: Container(
                        width: MediaQuery.of(context).size.width - 20, // Adjust width here based on your layout preferences
                        child: ListTile(
                          title: Text("To do list: ${listData['title']}"),
                          subtitle: Text(
                            allCompleted ? "All completed!" : "Already done: $completedCount/${tasks.length}",
                            style: TextStyle(color: allCompleted ? Colors.green : Colors.red),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          } else {
            return Center(child: Text("No ToDo Lists found for this day."));
          }
        }
        return Center(child: CircularProgressIndicator());
      },
    );
  }



  void _loadPlanItems() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String itemsKey = 'items_${widget.plan.id}';
    List<String>? itemsJson = prefs.getStringList(itemsKey);
    if (itemsJson != null) {
      List<PlanItem> items = itemsJson.map((itemJson) => PlanItem.fromJson(json.decode(itemJson))).toList();
      setState(() {
        _planItems = items;
      });
    }
  }

  void _goToNextDay() {
    if (_currentDay < _totalDays) {
      setState(() {
        _currentDay++;
      });
    }
  }

  void _goToPreviousDay() {
    if (_currentDay > 0) {
      setState(() {
        _currentDay--;
      });
    }
  }


// 修改Item逻辑
  void _editItem(String itemId) {
    final index = _planItems.indexWhere((item) => item.id == itemId);
    if (index != -1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => DetailFormPage(planItem: _planItems[index],planId: _planItems[index].planId,type: _planItems[index].type ,day: _planItems[index].day)),
      ).then((_) => _loadPlanItems());
    }
  }

// 删除Item逻辑
  void _deleteItem(String itemId) async {
    final index = _planItems.indexWhere((item) => item.id == itemId);
    if (index != -1) {
      setState(() {
        _planItems.removeAt(index);
      });

      final prefs = await SharedPreferences.getInstance();
      final String itemsKey = 'items_${widget.plan.id}';
      await prefs.setStringList(
        itemsKey,
        _planItems.map((item) => json.encode(item.toJson())).toList(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.plan.name),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddNewItemPage(planId: widget.plan.id, day: _currentDay,)), // 确保这里正确传递planId
              );
              if (result != null) {
                _loadPlanItems();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHorizontalToDoLists(),
          Expanded(
            child: ListView.builder(
              itemCount: _planItems.where((item) => item.day == _currentDay).length,
              itemBuilder: (context, index) {
                final filteredItems = _planItems.where((item) => item.day == _currentDay).toList();
                final item = filteredItems[index];
                return Card(
                  child: ListTile(
                    title: Text(item.title),
                    subtitle: Text((item.startTime??'1')+'2'), // Customize with item details
                    trailing: PopupMenuButton<String>(
                      onSelected: (String result) {
                        if (result == 'modify') {
                          _editItem(item.id);
                        } else if (result == 'delete') {
                          _deleteItem(item.id);
                        }
                      },
                      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(
                          value: 'modify',
                          child: Text('Modify'),
                        ),
                        const PopupMenuItem<String>(
                          value: 'delete',
                          child: Text('Delete', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.only(left: arrowButtonPadding),
                child: IconButton(
                  icon: Icon(Icons.chevron_left),
                  onPressed: _currentDay > 0 ? _goToPreviousDay : null,
                ),
              ),
              Text('Day $_currentDay/${_totalDays}',
                  style: Theme.of(context).textTheme.titleLarge),
              Padding(
                padding: EdgeInsets.only(right: arrowButtonPadding),
                child: IconButton(
                  icon: Icon(Icons.chevron_right),
                  onPressed: _currentDay < _totalDays ? _goToNextDay : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
