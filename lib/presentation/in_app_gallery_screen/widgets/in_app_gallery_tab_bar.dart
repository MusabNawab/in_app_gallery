import 'package:flutter/material.dart';

class InAppGalleryTabBar extends StatelessWidget {
  const InAppGalleryTabBar({
    super.key,
    required this.tabController,
    this.tabBarIndicatorSize,
  });

  final TabController tabController;
  final TabBarIndicatorSize? tabBarIndicatorSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final tabBarTheme = theme.tabBarTheme;

    return TabBar(
      controller: tabController,
      dividerColor: Colors.transparent,
      isScrollable: true,
      tabAlignment: TabAlignment.center,

      indicatorPadding: const EdgeInsets.symmetric(horizontal: 8.0),

      labelPadding: const EdgeInsets.symmetric(horizontal: 50),

      indicatorSize: tabBarIndicatorSize ?? TabBarIndicatorSize.tab,
      splashBorderRadius: BorderRadius.circular(30),
      indicator: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: tabBarTheme.indicatorColor ?? colorScheme.secondary,
      ),
      labelColor: Colors.white,
      unselectedLabelColor: tabBarTheme.unselectedLabelColor ?? Colors.grey,
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      tabs: const [
        Tab(text: 'Images', height: 36),
        Tab(text: 'Videos', height: 36),
      ],
    );
  }
}
