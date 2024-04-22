import 'package:EzTour/plans_add_new_item_forms.dart';
import 'package:EzTour/plans_add_new_item_tdl.dart';
import 'package:flutter/material.dart';

class AddNewItemPage extends StatelessWidget {
  final String planId;
  final int day;

  AddNewItemPage({Key? key, required this.planId, required this.day}) : super(key: key);


  @override
  Widget build(BuildContext context) {
    final List<String> itemTypes = ['To Do List','Attractions', 'Transportation', 'Dining', 'Accommodation'];

    return Scaffold(
      appBar: AppBar(
        title: Text('Add New Plan Item'),
      ),
      body: ListView.builder(
        itemCount: itemTypes.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(itemTypes[index]),
            onTap: () {
              if (itemTypes[index] == 'To Do List') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ToDoListPage(planId: planId, day: day),
                  ),
                );
              } else{
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetailFormPage(planId: planId, type: itemTypes[index], day: day),
                    ),
                );
              }
            },
          );
        },
      ),
    );
  }
}