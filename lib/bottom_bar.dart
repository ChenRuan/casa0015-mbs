import 'package:flutter/material.dart';

class BottomNavScreen extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const BottomNavScreen({
    Key? key,
    required this.selectedIndex,
    required this.onItemSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: ImageIcon(AssetImage("assets/icon_setting.png")),
          label: 'Settings',
        ),
        BottomNavigationBarItem(
          icon: ImageIcon(AssetImage("assets/icon_tour.png")),
          label: 'Tour',
        ),
        BottomNavigationBarItem(
          icon: ImageIcon(AssetImage("assets/icon_plans.png")),
          label: 'Plans',
        ),
      ],
      currentIndex: selectedIndex,
      selectedItemColor: Colors.amber[800],
      onTap: onItemSelected,
      // Other customizable parameters
      backgroundColor: Colors.white,
      unselectedItemColor: Colors.grey,
      selectedFontSize: 14.0,
      unselectedFontSize: 12.0,
      type: BottomNavigationBarType.fixed,
      showUnselectedLabels: true,
      elevation: 5.0,
    );
  }
}
