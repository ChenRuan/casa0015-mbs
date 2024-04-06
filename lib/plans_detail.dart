import 'package:eztour/plans_add_item_form.dart';
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

  void _loadPlanItems() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String itemsKey = 'items_${widget.plan.id}';
    List<String>? itemsJson = prefs.getStringList(itemsKey);

    if (itemsJson != null) {
      List<PlanItem> items = itemsJson.map((itemJson) => PlanItem.fromJson(json.decode(itemJson))).toList();

      // 假设PlanItem有一个DateTime属性来表示日期和时间，你可以根据它来排序
      // 这里仅根据day属性进行排序，你可以根据实际情况调整
      items.sort((a, b) => a.day.compareTo(b.day));

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
        MaterialPageRoute(builder: (context) => DetailFormPage(planItem: _planItems[index],planId: _planItems[index].id,type: _planItems[index].type ,day: _planItems[index].day)),
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
          Expanded(
            child: ListView.builder(
              itemCount: _planItems.where((item) => item.day == _currentDay).length,
              itemBuilder: (context, index) {
                final filteredItems = _planItems.where((item) => item.day == _currentDay).toList();
                final item = filteredItems[index];
                return Card(
                  child: ListTile(
                    title: Text(item.title),
                    subtitle: Text(item.type), // Customize with item details
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
                  style: Theme.of(context).textTheme.headline6),
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
