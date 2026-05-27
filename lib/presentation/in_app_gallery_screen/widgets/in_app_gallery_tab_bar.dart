import 'package:flutter/material.dart';

class InAppGalleryTabBar extends StatelessWidget {
  const InAppGalleryTabBar({
    super.key,
    required this.tabController,
    this.tabBarIndicatorSize,
    required this.imagesTabText,
    required this.videosTabText,
  });

  final TabController tabController;
  final TabBarIndicatorSize? tabBarIndicatorSize;
  final String imagesTabText;
  final String videosTabText;

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
      tabs: [
        Tab(text: imagesTabText, height: 36),
        Tab(text: videosTabText, height: 36),
      ],
    );
  }
}
