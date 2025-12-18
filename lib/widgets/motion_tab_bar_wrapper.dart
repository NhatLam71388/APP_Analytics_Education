import 'package:flutter/material.dart';
import 'motion_tab_bar_provider.dart';

/// Helper function để wrap một widget với MotionTabBarProvider từ context cha
Widget wrapWithMotionTabBar(BuildContext context, Widget child) {
  final provider = MotionTabBarProvider.findInAncestors(context);
  
  if (provider != null) {
    return MotionTabBarProvider(
      labels: provider.labels,
      icons: provider.icons,
      initialSelectedTab: provider.initialSelectedTab,
      selectedColor: provider.selectedColor,
      onTabSelected: provider.onTabSelected,
      child: child,
    );
  }
  
  return child;
}
