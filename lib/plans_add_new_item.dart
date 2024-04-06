import 'package:eztour/plans_add_item_form.dart';
import 'package:flutter/material.dart';

class AddNewItemPage extends StatelessWidget {
  final String planId;
  final int day;

  AddNewItemPage({Key? key, required this.planId, required this.day}) : super(key: key);


  @override
  Widget build(BuildContext context) {
    // 这里是一个示例项目类型列表
    final List<String> itemTypes = ['准备项目', '交通', '饮食', '休闲'];

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
              // 点击后，导航到详细表单页面
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetailFormPage(planId: planId, type: itemTypes[index], day: day),
                ),
              );
            },
          );
        },
      ),
    );
  }
}