import 'package:flutter/material.dart';

class DrawerItem {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  DrawerItem({
    required this.icon,
    required this.title,
    this.onTap,
  });
}

class ReusableDrawer extends StatelessWidget {
  final String? headerTitle;
  final String? headerSubtitle;
  final Widget? headerWidget;
  final List<DrawerItem> items;
  final Color? backgroundColor;
  final Color? headerColor;

  const ReusableDrawer({
    Key? key,
    this.headerTitle,
    this.headerSubtitle,
    this.headerWidget,
    required this.items,
    this.backgroundColor,
    this.headerColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: backgroundColor,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          if (headerWidget != null)
            headerWidget!
          else
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(
                color: headerColor ?? Theme.of(context).primaryColor,
              ),
              accountName: Text(
                headerTitle ?? 'Reusable Widgets',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              accountEmail: Text(headerSubtitle ?? 'Demo Application'),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, size: 40, color: Colors.blue),
              ),
            ),
          ...items.map((item) => ListTile(
                leading: Icon(item.icon),
                title: Text(item.title),
                onTap: () {
                  Navigator.pop(context);
                  item.onTap?.call();
                },
              )),
        ],
      ),
    );
  }
}
