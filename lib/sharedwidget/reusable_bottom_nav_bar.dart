import 'package:flutter/material.dart';

class NavBarItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;

  NavBarItem({
    required this.icon,
    this.activeIcon,
    required this.label,
  });
}

class ReusableBottomNavBar extends StatelessWidget {
  final List<NavBarItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Color? selectedItemColor;
  final Color? unselectedItemColor;
  final Color? backgroundColor;
  final BottomNavigationBarType? type;

  const ReusableBottomNavBar({
    Key? key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.selectedItemColor,
    this.unselectedItemColor,
    this.backgroundColor,
    this.type,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: items.map((item) {
        return BottomNavigationBarItem(
          icon: Icon(item.icon),
          activeIcon: item.activeIcon != null ? Icon(item.activeIcon) : null,
          label: item.label,
        );
      }).toList(),
      currentIndex: currentIndex,
      onTap: onTap,
      selectedItemColor: selectedItemColor ?? Theme.of(context).primaryColor,
      unselectedItemColor: unselectedItemColor ?? Colors.grey,
      backgroundColor: backgroundColor,
      type: type ?? BottomNavigationBarType.fixed,
    );
  }
}
