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

    const Color selected = Colors.blue;
    const Color unselected = Colors.black87;

    return NavigationBarTheme(
      data: NavigationBarThemeData(
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>(
              (Set<WidgetState> states) => states.contains(WidgetState.selected)
              ? const TextStyle(color: Colors.blue, fontSize: 13, fontWeight: FontWeight.bold)
              : const TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ),
      child: NavigationBar(
        height: 75,
        backgroundColor: Colors.white54,
        onDestinationSelected: onItemTapped,
        indicatorColor: Colors.blue[50],
        selectedIndex: currentPageIndex,
        destinations: const <Widget>[
          NavigationDestination(
            selectedIcon: ImageIcon(
              AssetImage('assets/images/appicon.png'), color: selected,
            ),
            icon: ImageIcon(
              AssetImage('assets/images/appicon.png',), color: unselected, // Replace with your image path
            ),
            label: 'Home',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.sos_outlined, color: selected,),
            icon: Icon(Icons.sos, color: Colors.red,),
            label: 'SOS Video',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.diversity_1_outlined, color: selected,),
            icon: Icon(Icons.diversity_1, color: unselected,),
            label: 'Circles', // Empty label for a cleaner look (optional)
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.settings_input_antenna_outlined, color: selected,),
            icon: Icon(Icons.settings_input_antenna, color: unselected,),
            label: 'Cases',
          ),
          NavigationDestination(
            selectedIcon: Icon(Icons.account_circle_outlined, color: selected,),
            icon: Icon(Icons.account_circle, color: unselected,),
            label: 'Profile', // Empty label for a cleaner look (optional)
          ),
        ],
      ),
    );
  }
}
