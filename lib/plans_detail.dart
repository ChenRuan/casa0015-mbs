import 'package:EzTour/plans_add_new_item_forms.dart';
import 'package:EzTour/plans_add_new_item_tdl.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:EzTour/plans_add_new_item.dart';
import 'package:EzTour/data.dart';
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
  final double arrowButtonPadding = 16.0;
  List<PlanItem> _planItems = [];
  List<Map<String, dynamic>> _todoLists = [];

  @override
  void initState() {
    super.initState();
    _currentDay = 1;
    _totalDays = widget.plan.travelDays;
    _loadPlanItems();
    _loadToDoLists().then((data) {
      setState(() {
        _todoLists = data;
      });
    });
    print(widget.plan.id);
  }

  Future<List<Map<String, dynamic>>> _loadToDoLists() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final keys = prefs
        .getKeys()
        .where((key) => key.startsWith('todo_${widget.plan.id}_$_currentDay'))
        .toList();
    List<Map<String, dynamic>> allLists = [];


    for (String key in keys) {
      String? savedData = prefs.getString(key);
      if (savedData != null) {
        try {
          var decodedData = jsonDecode(savedData) as Map<String, dynamic>;
          List<dynamic> tasks = decodedData['tasks'] != null ? List.from(decodedData['tasks']) : [];
          allLists.add({
            'uid': decodedData['uid'],
            'title': decodedData['title'],
            'tasks': tasks, // 确保tasks字段总是一个列表
          });
          print('$key,$decodedData');
        } catch (e) {
          print("Error parsing ToDo list data for key $key: $e");
        }
      }
    }
    return allLists;
  }

  Widget _buildHorizontalToDoLists() {
    // Directly build the list view if data is already loaded
    if(_todoLists.isNotEmpty){
      return SizedBox(
        height: 80,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _todoLists.length,
          itemBuilder: (context, index) {
            var listData = _todoLists[index];
            List<dynamic> tasks = listData['tasks'] as List<dynamic>;
            int completedCount = tasks.where((t) => t['completed'] as bool).length;
            bool allCompleted = completedCount == tasks.length;
            return InkWell(
              onTap: () {
                var listData = _todoLists[index];
                List<String> tasks = listData['tasks'].map<String>((t) => t['task'].toString()).toList();
                List<String> taskCompletionStatus = listData['tasks'].map<String>((t) => t['completed'].toString()).toList();
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ToDoListPage(
                          planId: widget.plan.id,
                          day: _currentDay,
                          uid: listData['uid'],
                          title: listData['title'],
                          tasks: tasks,
                          taskCompletionStatus: taskCompletionStatus,
                        )
                    )
                ).then((_) => _loadToDoLists());
              },
              child: Card(
                child: Container(
                  width: MediaQuery.of(context).size.width - 20,
                  child: ListTile(
                    title: Text("${listData['title']} (To Do List)"),
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
    }else{
      return SizedBox(height: 0,);
    }
  }

  String _getCurrentDate() {
    if (_currentDay >= 0) {
      DateTime startDate = widget.plan.startDate;
      DateTime currentDate = startDate.add(Duration(days: _currentDay -1));
      print(currentDate);
      return DateFormat('MMMM dd, yyyy')
          .format(currentDate); // format the date as needed
    }
    return '';
  }

  void _loadPlanItems() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String itemsKey = 'items_${widget.plan.id}';
    List<String>? itemsJson = prefs.getStringList(itemsKey);
    if (itemsJson != null) {
      List<PlanItem> items = itemsJson
          .map((itemJson) => PlanItem.fromJson(json.decode(itemJson)))
          .toList();

      items.sort((a, b) {
        int startCompare = _compareTime(a.startTime, b.startTime);
        if (startCompare != 0) return startCompare;
        return _compareTime(a.endTime, b.endTime);
      });

      setState(() {
        _planItems = items;
      });
    }
  }

  int _compareTime(String? a, String? b) {
    if (a == null || a.isEmpty) return (b == null || b.isEmpty) ? 0 : 1;
    if (b == null || b.isEmpty) return -1;
    return a.compareTo(b);
  }

  void _goToNextDay() {
    if (_currentDay < _totalDays) {
      setState(() {
        _currentDay++;
        _loadToDoLists().then((data) {
          setState(() {
            _todoLists = data;
          });
        });
      });
    }
  }

  void _goToPreviousDay() {
    if (_currentDay > 0) {
      setState(() {
        _currentDay--;
        _loadToDoLists().then((data) {
          setState(() {
            _todoLists = data;
          });
        });
      });
    }
  }

  void _editItem(String itemId) {
    final index = _planItems.indexWhere((item) => item.id == itemId);
    if (index != -1) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => DetailFormPage(
                planItem: _planItems[index],
                planId: _planItems[index].planId,
                type: _planItems[index].type,
                day: _planItems[index].day)),
      ).then((_) => _loadPlanItems());
    }
  }

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

  String _formatSubtitle({
    String? startTime,
    String? endTime,
    String? location,
    String? destination,
  }) {
    String timeText = '';
    if (startTime != '' || endTime != '') {
      if (startTime != '' && endTime != '') {
        timeText = '$startTime - $endTime';
      } else if (startTime != '') {
        timeText = startTime ?? '';
      } else {
        timeText = 'endTime: $endTime';
      }
    }

    String extractPlaceName(String? place) {
      if (place == null) return '';
      var parts = place.split(RegExp(r'[,|-]'));
      return parts[0]
          .trim(); // Trim to remove any leading/trailing white spaces
    }

    String locationText = '';
    if (location != "" || destination != "") {
      if (location != "" && destination != "") {
        locationText =
            '${extractPlaceName(location)} - ${extractPlaceName(destination)}';
      } else if (location != "") {
        locationText = extractPlaceName(location);
      } else {
        locationText = 'Destination: ${extractPlaceName(destination)}';
      }
    }

    if (timeText.isNotEmpty && locationText.isNotEmpty) {
      return '$timeText\n$locationText';
    } else if (timeText.isNotEmpty) {
      return timeText;
    } else if (locationText.isNotEmpty) {
      return locationText;
    }

    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Plan: ${widget.plan.name}'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => AddNewItemPage(
                          planId: widget.plan.id,
                          day: _currentDay,
                        )), // 确保这里正确传递planId
              ).then((_) => _loadPlanItems());
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHorizontalToDoLists(),
          _planItems.where((item) => item.day == _currentDay).length == 0
              ? Padding(
            padding: EdgeInsets.only(top: 250.0),  // 在文本上方添加20像素的空间
            child: Center(
              child: Text(
                "No items today.",
                style: TextStyle(fontSize: 18),
              ),
            ),
          ) :
          Expanded(
            child: ListView.builder(
              itemCount:
                  _planItems.where((item) => item.day == _currentDay).length,
              itemBuilder: (context, index) {
                final filteredItems = _planItems
                    .where((item) => item.day == _currentDay)
                    .toList();
                final item = filteredItems[index];
                return Card(
                  child: ListTile(
                    title: Text('${item.title} (${item.type})'),
                    subtitle: Text(_formatSubtitle(
                      startTime: item.startTime,
                      endTime: item.endTime,
                      location: item.location,
                      destination: item.destination,
                    )), // Customize with item details
                    trailing: PopupMenuButton<String>(
                      onSelected: (String result) {
                        if (result == 'modify') {
                          _editItem(item.id);
                        } else if (result == 'delete') {
                          _deleteItem(item.id);
                        }
                      },
                      itemBuilder: (BuildContext context) =>
                          <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(
                          value: 'modify',
                          child: Text('Modify'),
                        ),
                        const PopupMenuItem<String>(
                          value: 'delete',
                          child: Text('Delete',
                              style: TextStyle(color: Colors.red)),
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
          padding: const EdgeInsets.symmetric(vertical: 3.0),
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
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Day $_currentDay/${_totalDays}',
                      style: Theme.of(context).textTheme.titleLarge),
                  Text(_getCurrentDate()) // Displaying the date here
                ],
              ),
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
