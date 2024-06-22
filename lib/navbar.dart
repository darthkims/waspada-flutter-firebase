import 'package:flutter/material.dart';

// custom_navigation_bar.dart
class CustomNavigationBar extends StatelessWidget {
  final int currentPageIndex;
  final Function(int) onItemTapped;

  const CustomNavigationBar({
    required this.currentPageIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBarTheme(
      data: NavigationBarThemeData(
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>(
              (Set<WidgetState> states) => states.contains(WidgetState.selected)
              ? const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)
              : const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ),
      child: NavigationBar(
        height: 75,
        backgroundColor: Colors.blue,
        onDestinationSelected: onItemTapped,
        indicatorColor: Colors.white,
        selectedIndex: currentPageIndex,
        destinations: const <Widget>[
          NavigationDestination(
            selectedIcon: ImageIcon(
              AssetImage('assets/images/appicon.png'), size: 30, // Replace with your image path
            ),
            icon: ImageIcon(
              AssetImage('assets/images/appicon.png',), size: 30, color: Colors.white, // Replace with your image path
            ),
            label: 'Home',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.sos_outlined, size: 30,),
            icon: Icon(Icons.sos, color: Colors.white, size: 30,),
            label: 'SOS Video',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.diversity_1_outlined, size: 30,),
            icon: Icon(Icons.diversity_1, color: Colors.white, size: 30,),
            label: 'Circles', // Empty label for a cleaner look (optional)
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.settings_input_antenna_outlined, size: 30,),
            icon: Icon(Icons.settings_input_antenna, color: Colors.white, size: 30,),
            label: 'Cases',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.account_circle_outlined, size: 30,),
            icon: Icon(Icons.account_circle, color: Colors.white, size: 30,),
            label: 'Profile', // Empty label for a cleaner look (optional)
          ),
        ],
      ),
    );
  }
}
