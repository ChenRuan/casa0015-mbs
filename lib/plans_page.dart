import 'package:eztour/plans_add_new_plan.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class PlansPage extends StatefulWidget {
  @override
  _PlansPageState createState() => _PlansPageState();
}

class _PlansPageState extends State<PlansPage> {
  List<Plan> _plans = [];

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? savedPlansString = prefs.getStringList('plans');
    if (savedPlansString != null) {
      setState(() {
        _plans = savedPlansString.map((planString) => Plan.fromJson(json.decode(planString))).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Plans Page'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddNewPlanPage()),
              ).then((_) => _loadPlans()); // Reload plans when a new one is added
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _plans.length,
        itemBuilder: (context, index) {
          final plan = _plans[index];
          return Card(
            child: ListTile(
              title: Text(plan.name),
              subtitle: Text('Start Time: ${plan.startDate.toLocal().toString().split(' ')[0]}'),
              trailing: PopupMenuButton<String>(
                onSelected: (value) => _handleMenuSelection(value, index),
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'edit',
                    child: Text('Edit'),
                  ),
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Text('Delete', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
  // Handle menu selection
  void _handleMenuSelection(String value, int index) {
    switch (value) {
      case 'edit':
        _editPlan(index);
        break;
      case 'delete':
        _deletePlan(index);
        break;
      default:
        break;
    }
  }

  // Edit plan logic
  void _editPlan(int index) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddNewPlanPage(plan: _plans[index])),
    ).then((_) => _loadPlans());
  }

  // Delete plan logic
  void _deletePlan(int index) async {
    // Remove the plan from the list and update SharedPreferences
    setState(() {
      _plans.removeAt(index);
    });
    final prefs = await SharedPreferences.getInstance();
    // Update the stored plans
    await prefs.setStringList(
      'plans',
      _plans.map((plan) => json.encode(plan.toJson())).toList(),
    );
  }
}