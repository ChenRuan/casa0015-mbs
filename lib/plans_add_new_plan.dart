import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class Plan {
  String name;
  DateTime startDate;
  DateTime endDate;

  Plan({required this.name, required this.startDate, required this.endDate});

  Map<String, dynamic> toJson() => {
    'name': name,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
  };

  factory Plan.fromJson(Map<String, dynamic> json) => Plan(
    name: json['name'],
    startDate: DateTime.parse(json['startDate']),
    endDate: DateTime.parse(json['endDate']),
  );
}

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

  @override
  void initState() {
    super.initState();
    // Initial the modified plan
    if (widget.plan != null) {
      _nameController.text = widget.plan!.name;
      _startDateController.text = widget.plan!.startDate.toIso8601String().split('T').first;
      _endDateController.text = widget.plan!.endDate.toIso8601String().split('T').first;
    }
  }

  Future<void> _savePlan() async {
    if (_formKey.currentState!.validate()) {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> plansList = prefs.getStringList('plans') ?? [];

      if (widget.plan != null) {
        // Modify the plan
        final index = plansList.indexWhere((plan) =>
        Plan.fromJson(json.decode(plan)).name == widget.plan!.name);
        if (index != -1) {
          plansList[index] = json.encode(Plan(
            name: _nameController.text,
            startDate: DateTime.parse(_startDateController.text),
            endDate: DateTime.parse(_endDateController.text),
          ).toJson());
        }
      } else {
        // Add a new plan
        plansList.add(json.encode(Plan(
          name: _nameController.text,
          startDate: DateTime.parse(_startDateController.text),
          endDate: DateTime.parse(_endDateController.text),
        ).toJson()));
      }

      // Save new plan list
      await prefs.setStringList('plans', plansList);

      // Go back
      Navigator.pop(context);
    }
  }

  // Helper function to show date picker dialog
  Future<void> _selectDate(BuildContext context, TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: controller.text.isNotEmpty ? DateTime.parse(controller.text) : DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != DateTime.parse(controller.text)) {
      // Format the selected date and show it in the text field
      controller.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.plan != null ? 'Modify the Plan' : 'Add New Plan'),
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
              },
              validator: (value) {
                if (value == null || value.isEmpty || DateTime.tryParse(value) == null) {
                  return 'Please enter a valid end date';
                }
                return null;
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _savePlan,
              child: Text('Save Plan'),
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
    super.dispose();
  }
}