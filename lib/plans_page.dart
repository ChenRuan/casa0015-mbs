import 'package:EzTour/data.dart';
import 'package:EzTour/plans_add_new_plan.dart';
import 'package:EzTour/plans_detail.dart';
import 'package:EzTour/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:event_bus/event_bus.dart';

class PlansPage extends StatefulWidget {
  @override
  _PlansPageState createState() => _PlansPageState();
}

class _PlansPageState extends State<PlansPage> {
  List<dynamic> _items = [];

  @override
  void initState() {
    super.initState();
    _loadPlans();
    eventBus.on<DownloadCompleteEvent>().listen((event) {
      setState(() {
        _loadPlans();
      });
    });
  }

  void _loadPlans() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? savedPlansString = prefs.getStringList('plans');
    if (savedPlansString != null) {
      List<Plan> loadedPlans = savedPlansString.map((planString) => Plan.fromJson(json.decode(planString))).toList();

      DateTime today = DateTime.now();
      List<Plan> ongoingPlans = loadedPlans.where((plan) => plan.startDate.isBefore(today) && plan.endDate.isAfter(today.subtract(Duration(days: 1)))).toList();
      List<Plan> futurePlans = loadedPlans.where((plan) => plan.startDate.isAfter(today)).toList();
      List<Plan> pastPlans = loadedPlans.where((plan) => plan.endDate.isBefore(today.subtract(Duration(days: 1)))).toList();

      ongoingPlans.sort((a, b) => a.startDate.compareTo(b.startDate));
      futurePlans.sort((a, b) => a.startDate.compareTo(b.startDate));
      pastPlans.sort((a, b) => b.startDate.compareTo(a.startDate));

      List<dynamic> tempList = [];
      tempList.addAll(ongoingPlans);
      if (futurePlans.isNotEmpty) {
        tempList.add("—————— Future Plans ——————");
        tempList.addAll(futurePlans);
      }
      if (pastPlans.isNotEmpty) {
        tempList.add("—————— History Plans ——————");
        tempList.addAll(pastPlans);
      }

      setState(() {
        _items = tempList;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Plans'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddNewPlanPage()),
              ).then((_) => _loadPlans());
            },
          ),
        ],
      ),
      body: _items.isEmpty
          ? Align(
        alignment: Alignment.center,
        child: Text("There is no plan. \n\nClick the add button to create one.", style: TextStyle(fontSize: 18),textAlign: TextAlign.center,),
      ):ListView.builder(
        itemCount: _items.length,
        itemBuilder: (context, index) {
          final item = _items[index];
          if (item is String) { // Check if it is a header
            return Container(
              padding: EdgeInsets.symmetric(vertical: 3, horizontal: 10),  // Adjust vertical and horizontal padding
              child: Text(
                _items[index],
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.grey,  // Set text color
                    fontSize: 12,  // Set font size
                    fontWeight: FontWeight.bold  // Set font weight
                ),
              ),
            );
          } else if (item is Plan) { // Check if it is a Plan
            final plan = _items[index] as Plan;
            bool isOngoing = DateTime.now().isAfter(plan.startDate) && DateTime.now().subtract(Duration(days: 1)).isBefore(plan.endDate);
            return Card(
              color: isOngoing ? Colors.orange[100] : null,
              child: ListTile(
                title: Text(item.name),
                subtitle: Text('Date: ${DateFormat('yyyy-MM-dd').format(item.startDate)} - ${DateFormat('yyyy-MM-dd').format(item.endDate)}'),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) => _handleMenuSelection(value, item),
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
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => PlanDetailPage(plan: item),
                    ),
                  ).then((_) => _loadPlans());
                  eventBus.fire(DownloadCompleteEvent());
                },
              ),
            );
          }
          return SizedBox.shrink(); // Just in case there's an unexpected item type
        },
      ),
    );
  }

  void _handleMenuSelection(String value, Plan plan) {
    switch (value) {
      case 'edit':
        _editPlan(plan);
        break;
      case 'delete':
        _deletePlan(plan);
        break;
      default:
        break;
    }
  }

  void _editPlan(Plan plan) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddNewPlanPage(plan: plan)),
    ).then((_) => _loadPlans());
    eventBus.fire(DownloadCompleteEvent());
  }

  void _deletePlan(Plan plan) async {
    setState(() {
      _items.remove(plan);
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'plans',
      _items.where((item) => item is Plan).map((plan) => json.encode((plan as Plan).toJson())).toList(),
    );
    eventBus.fire(DownloadCompleteEvent());
  }
}

