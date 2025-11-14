import 'package:flutter/material.dart';

class TabItem {
  final String title;
  final IconData? icon;
  final Widget content;

  TabItem({
    required this.title,
    this.icon,
    required this.content,
  });
}

class ReusableTabBar extends StatelessWidget {
  final List<TabItem> tabs;
  final Color? indicatorColor;
  final Color? labelColor;
  final Color? unselectedLabelColor;
  final bool isScrollable;

  const ReusableTabBar({
    Key? key,
    required this.tabs,
    this.indicatorColor,
    this.labelColor,
    this.unselectedLabelColor,
    this.isScrollable = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: tabs.length,
      child: Column(
        children: [
          TabBar(
            isScrollable: isScrollable,
            indicatorColor: indicatorColor ?? Theme.of(context).primaryColor,
            labelColor: labelColor ?? Theme.of(context).primaryColor,
            unselectedLabelColor: unselectedLabelColor ?? Colors.grey,
            tabs: tabs.map((tab) {
              if (tab.icon != null) {
                return Tab(
                  icon: Icon(tab.icon),
                  text: tab.title,
                );
              }
              return Tab(text: tab.title);
            }).toList(),
          ),
          Expanded(
            child: TabBarView(
              children: tabs.map((tab) => tab.content).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
