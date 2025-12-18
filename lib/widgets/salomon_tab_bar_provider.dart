import 'package:flutter/material.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';

class SalomonTabBarProvider extends InheritedWidget {
  final List<SalomonBottomBarItem> items;
  final int initialSelectedIndex;
  final int currentIndex;
  final Color selectedItemColor;
  final Color unselectedItemColor;
  final ValueChanged<int> onTabSelected;

  const SalomonTabBarProvider({
    super.key,
    required super.child,
    required this.items,
    required this.initialSelectedIndex,
    required this.currentIndex,
    required this.selectedItemColor,
    required this.unselectedItemColor,
    required this.onTabSelected,
  });

  static SalomonTabBarProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<SalomonTabBarProvider>();
  }

  // Tìm provider từ context cha (kể cả khi màn hình con được push)
  static SalomonTabBarProvider? findInAncestors(BuildContext context) {
    return context.findAncestorWidgetOfExactType<SalomonTabBarProvider>();
  }

  @override
  bool updateShouldNotify(SalomonTabBarProvider oldWidget) {
    return items != oldWidget.items ||
        initialSelectedIndex != oldWidget.initialSelectedIndex ||
        currentIndex != oldWidget.currentIndex ||
        selectedItemColor != oldWidget.selectedItemColor ||
        unselectedItemColor != oldWidget.unselectedItemColor;
  }

  Widget buildSalomonBottomBar(BuildContext context) {
    // Tạo callback wrapper để pop về màn hình chính nếu đang ở màn hình con
    void onTabItemSelected(int index) {
      final navigator = Navigator.of(context);
      
      // Kiểm tra xem có phải đang ở màn hình con không (có thể pop được)
      if (navigator.canPop()) {
        // CHUYỂN TAB TRƯỚC khi pop để tránh hiển thị trang chủ
        // Gọi onTabSelected ngay để cập nhật state và jump đến đúng trang
        onTabSelected(index);
        
        // Đợi một frame để đảm bảo PageController đã jump đến đúng trang
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // Sau đó mới pop về màn hình chính
          // Lúc này màn hình chính đã ở đúng tab rồi, không còn hiển thị trang chủ
          navigator.popUntil((route) => route.isFirst);
        });
      } else {
        // Nếu đã ở màn hình chính, chuyển tab ngay
        onTabSelected(index);
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: SalomonBottomBar(
          currentIndex: this.currentIndex,
          selectedItemColor: selectedItemColor,
          unselectedItemColor: unselectedItemColor,
          onTap: onTabItemSelected,
          items: items,
        ),
      ),
    );
  }
}

