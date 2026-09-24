import 'package:flutter/material.dart';

/// Bottom sheet controls panel containing the tab bar and tab views.
class EditorBottomControls extends StatelessWidget {
  final TabController tabController;
  final Color primaryColor;
  final Widget cropTab;
  final Widget rotateTab;
  final Widget qualityTab;

  const EditorBottomControls({
    super.key,
    required this.tabController,
    required this.primaryColor,
    required this.cropTab,
    required this.rotateTab,
    required this.qualityTab,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Tab Selector
            Container(
              height: 40,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(20),
              ),
              child: TabBar(
                controller: tabController,
                dividerColor: Colors.transparent,
                dividerHeight: 0.0,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white54,
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                tabs: const [
                  Tab(iconMargin: EdgeInsets.zero, text: 'Crop & Ratio'),
                  Tab(iconMargin: EdgeInsets.zero, text: 'Rotate'),
                  Tab(iconMargin: EdgeInsets.zero, text: 'Resize & Quality'),
                ],
              ),
            ),

            // Tab Content
            SizedBox(
              height: 115,
              child: TabBarView(
                controller: tabController,
                children: [
                  cropTab,
                  rotateTab,
                  qualityTab,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
