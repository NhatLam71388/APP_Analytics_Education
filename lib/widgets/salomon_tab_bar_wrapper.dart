import 'package:flutter/material.dart';
import 'salomon_tab_bar_provider.dart';

/// Helper function để wrap một widget với SalomonTabBarProvider từ context cha
Widget wrapWithSalomonTabBar(BuildContext context, Widget child) {
  final provider = SalomonTabBarProvider.findInAncestors(context);
  
  if (provider != null) {
    return SalomonTabBarProvider(
      items: provider.items,
      initialSelectedIndex: provider.initialSelectedIndex,
      currentIndex: provider.currentIndex,
      selectedItemColor: provider.selectedItemColor,
      unselectedItemColor: provider.unselectedItemColor,
      onTabSelected: provider.onTabSelected,
      child: child,
    );
  }
  
  return child;
}




