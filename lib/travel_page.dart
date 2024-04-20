import 'package:eztour/travel_mode_page.dart';
import 'package:flutter/material.dart';
import 'package:eztour/data.dart'; // Ensure you have a Plan class and related methods
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class TravelPage extends StatefulWidget {
  @override
  _TravelPageState createState() => _TravelPageState();
}

class _TravelPageState extends State<TravelPage> {
  List<Plan> _plans = [];
  Plan? _selectedPlan;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  void _loadPlans() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? savedPlansString = prefs.getStringList('plans');
    DateTime today = DateTime.now();
    if (savedPlansString != null) {
      List<Plan> loadedPlans = savedPlansString.map((planString) => Plan.fromJson(json.decode(planString))).toList();
      setState(() {
        _plans = loadedPlans.where((plan) =>
        today.isAfter(plan.startDate.subtract(Duration(days: 1))) && today.subtract(Duration(days: 1)).isBefore(plan.endDate)
        ).toList();
      });
    }
  }

  void _navigateToSelectedPlan() {
    final _selectedPlan = this._selectedPlan;
    if (_selectedPlan != null) {
      print("Navigating with selected plan: ${_selectedPlan.name}");
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => TravelModePage(plan: _selectedPlan!)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Please choose a travel plan", style: TextStyle(color: Colors.black),),
        backgroundColor: Colors.white,
        showCloseIcon: true,
        duration: Duration(seconds: 1),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Travel'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text("Please choose the travel plan you want", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _plans.length,
              itemBuilder: (context, index) {
                final plan = _plans[index];
                return ListTile(
                  title: Text('Plan: ${plan.name} (Days: ${plan.travelDays})'),
                  subtitle: Text('Date: ${plan.startDate.toLocal().toString().split(' ')[0]} - ${plan.endDate.toLocal().toString().split(' ')[0]}'),
                  tileColor: _selectedPlan == plan ? Colors.blue[100] : null,
                  onTap: () => setState(() {
                    _selectedPlan = plan;
                  }),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: ElevatedButton(
              onPressed: _navigateToSelectedPlan,
              child: Text("Enter the selected plan!"),
            ),
          ),
        ],
      ),
    );
  }
}
