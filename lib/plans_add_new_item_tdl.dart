import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';

class ToDoListPage extends StatefulWidget {
  final String planId;
  final int day;
  final String? title;
  final List<String>? tasks;
  final List<String>? taskCompletionStatus;
  final String? uid;
  ToDoListPage({Key? key, required this.planId, required this.day, this.title, this.tasks, this.taskCompletionStatus, this.uid}) : super(key: key);

  @override
  _ToDoListPageState createState() => _ToDoListPageState();
}

class _ToDoListPageState extends State<ToDoListPage> {
  TextEditingController titleController = TextEditingController();
  List<TextEditingController> controllers = [];
  List<bool> taskStatus = [];
  String? uid;

  @override
  void initState() {
    super.initState();
    uid = widget.uid ?? Uuid().v4();
    if (widget.title != null) {
      titleController.text = widget.title!;
    }
    if (widget.tasks != null && widget.taskCompletionStatus != null) {
      for (int i = 0; i < widget.tasks!.length; i++) {
        controllers.add(TextEditingController(text: widget.tasks![i]));
        bool completed = widget.taskCompletionStatus![i].toString() == 'true';
        taskStatus.add(completed);
      }
    } else {
      addNewTask(); // Only add a new task if creating a new list
    }
  }

  void addNewTask() {
    setState(() {
      controllers.add(TextEditingController());
      taskStatus.add(false);
    });
  }

  void deleteTask(int index) {
    setState(() {
      controllers.removeAt(index);
      taskStatus.removeAt(index);
    });
  }

  void _confirmDelete(int index) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Delete'),
          content: Text('Are you sure you want to delete this task?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (result ?? false) {
      deleteTask(index);
    }
  }

  Future<void> saveTasks() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String key = 'todo_${widget.planId}_${widget.day}_$uid';
    List<Map<String, dynamic>> taskData = [
      for (int i = 0; i < controllers.length; i++)
        {
          'task': controllers[i].text,
          'completed': taskStatus[i]
        }
    ];

    await prefs.setString(key, jsonEncode({'uid': uid, 'title': titleController.text, 'tasks': taskData}));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('List saved!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('To-Do List for Day ${widget.day}'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: saveTasks,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: 'List Title',
                border: UnderlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: ReorderableListView.builder(
              itemCount: controllers.length,
              itemBuilder: (context, index) {
                return ListTile(
                  contentPadding: EdgeInsets.only(left: 10.0,top: 0.0,right: 0.0,bottom: 0.0),
                  key: ValueKey('${index}_${controllers[index].text}'),
                  leading: Checkbox(
                    value: taskStatus[index],
                    onChanged: (bool? newValue) {
                      setState(() {
                        taskStatus[index] = newValue ?? false;
                      });
                    },
                  ),
                  title: TextField(
                    controller: controllers[index],
                    decoration: InputDecoration(
                      hintText: 'New task',
                      border: UnderlineInputBorder(),
                    ),
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _confirmDelete(index),
                    iconSize: 20,
                  ),
                );
              },
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) {
                    newIndex -= 1;
                  }
                  final item = controllers.removeAt(oldIndex);
                  final status = taskStatus.removeAt(oldIndex);
                  controllers.insert(newIndex, item);
                  taskStatus.insert(newIndex, status);
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text("Long press to drag and sort.", style: TextStyle(fontSize: 12, color: Colors.grey)), // 添加底部小字
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: addNewTask,
        tooltip: 'Add Task',
        child: Icon(Icons.add),
      ),
    );
  }
}