import 'package:EzTour/data.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class AddNewPlanPage extends StatefulWidget {
  final Plan? plan;
  AddNewPlanPage({Key? key, this.plan}) : super(key: key);
  @override
  _AddPlanPageState createState() => _AddPlanPageState();
}

class _AddPlanPageState extends State<AddNewPlanPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  final _travelDaysController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initial the modified plan
    if (widget.plan != null) {
      _nameController.text = widget.plan!.name;
      _startDateController.text = widget.plan!.startDate.toIso8601String().split('T').first;
      _endDateController.text = widget.plan!.endDate.toIso8601String().split('T').first;
      _travelDaysController.text = widget.plan!.travelDays.toString();
      _notesController.text = widget.plan!.notes;
    }
  }

  Future<void> _savePlan() async {
    if (_formKey.currentState!.validate()) {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> plansList = prefs.getStringList('plans') ?? [];
      int travelDays = int.tryParse(_travelDaysController.text) ?? 0;

      Plan newPlan = Plan(
        id: widget.plan?.id ?? Uuid().v4(),
        name: _nameController.text,
        startDate: DateTime.parse(_startDateController.text),
        endDate: DateTime.parse(_endDateController.text),
        travelDays: travelDays,
        notes: _notesController.text,
      );

      String planJson = json.encode(newPlan.toJson());

      if (widget.plan != null) {
        // 修改现有计划
        final index = plansList.indexWhere((plan) =>
        Plan.fromJson(json.decode(plan)).id == widget.plan!.id);
        if (index != -1) {
          plansList[index] = planJson;
        }
      } else {
        // 添加新计划
        plansList.add(planJson);
      }

      // 保存新计划列表
      await prefs.setStringList('plans', plansList);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Plan saved!')));
      // 返回上一页面
      Navigator.pop(context);
    }
  }

  // Helper function to show date picker dialog
// Helper function to show date picker dialog
  Future<void> _selectDate(BuildContext context, TextEditingController controller, {bool isStartDate = true}) async {
    final DateTime initialDate = controller.text.isNotEmpty
        ? DateTime.parse(controller.text)
        : DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != initialDate) {
      // Format the selected date and show it in the text field
      controller.text = DateFormat('yyyy-MM-dd').format(picked);
      // After date is picked, update days or the end date accordingly
      if (isStartDate) {
        // If start date was picked, update the end date based on travel days
        _updateDatesAndDays(updateDays: false);
      } else {
        // If end date was picked, just update travel days
        _updateDatesAndDays(updateDays: false);
      }
    }
  }

  void _updateDatesAndDays({bool updateDays = false}) {
    final DateTime? startDate = DateTime.tryParse(_startDateController.text);
    if (startDate != null) {
      if (updateDays) {
        // User changed the travel days
        int days = int.tryParse(_travelDaysController.text) ?? 0;
        _endDateController.text = DateFormat('yyyy-MM-dd').format(
            startDate.add(Duration(days: days - 1)) // Adjust for inclusive counting
        );
      } else {
        // User changed the date
        final DateTime? endDate = DateTime.tryParse(_endDateController.text);
        if (endDate != null) {
          int days = endDate.difference(startDate).inDays + 1; // +1 to include both start and end days in the count
          _travelDaysController.text = days.toString();
        }
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.plan != null ? 'Modify the Plan' : 'Add New Plan'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.check),
            onPressed: _savePlan, // 这里使用先前定义的 _savePlan 方法
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16.0),
          children: <Widget>[
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(labelText: 'Plan Name'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter the plan name';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _startDateController,
              decoration: InputDecoration(labelText: 'Start Date (YYYY-MM-DD)'),
              readOnly: true,
              onTap: () {
                _selectDate(context, _startDateController);
                _updateDatesAndDays();
              },
              validator: (value) {
                if (value == null || value.isEmpty || DateTime.tryParse(value) == null) {
                  return 'Please enter a valid start date';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _endDateController,
              decoration: InputDecoration(labelText: 'End Date (YYYY-MM-DD)'),
              readOnly: true, // 使文本字段只读
              onTap: () {
                _selectDate(context, _endDateController);
                _updateDatesAndDays();
              },
              validator: (value) {
                if (value == null || value.isEmpty || DateTime.tryParse(value) == null) {
                  return 'Please enter a valid end date';
                }
                return null;
              },
            ),
            TextFormField(
              controller: _travelDaysController,
              decoration: InputDecoration(labelText: 'Travel Days'),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                if (value.isNotEmpty) {
                  _updateDatesAndDays(updateDays: true);
                }
              },
            ),
            TextFormField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: 'Notes (Optional)',
                alignLabelWithHint: true,
              ),
              keyboardType: TextInputType.multiline,  // 设置键盘类型为多行文本
              textInputAction: TextInputAction.newline,  // 设置回车键动作为换行，适用于某些键盘布局
              maxLines: null,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    _nameController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}