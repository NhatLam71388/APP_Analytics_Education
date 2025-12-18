import 'package:flutter/material.dart';
// import 'package:motion_tab_bar/MotionTabBar.dart'; // Đã chuyển sang salomon_bottom_bar

class MotionTabBarProvider extends InheritedWidget {
  final List<String> labels;
  final List<IconData> icons;
  final String initialSelectedTab;
  final Color selectedColor;
  final ValueChanged<int> onTabSelected;

  const MotionTabBarProvider({
    super.key,
    required super.child,
    required this.labels,
    required this.icons,
    required this.initialSelectedTab,
    required this.selectedColor,
    required this.onTabSelected,
  });

  static MotionTabBarProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<MotionTabBarProvider>();
  }

  // Tìm provider từ context cha (kể cả khi màn hình con được push)
  static MotionTabBarProvider? findInAncestors(BuildContext context) {
    return context.findAncestorWidgetOfExactType<MotionTabBarProvider>();
  }

  @override
  bool updateShouldNotify(MotionTabBarProvider oldWidget) {
    return labels != oldWidget.labels ||
        icons != oldWidget.icons ||
        initialSelectedTab != oldWidget.initialSelectedTab ||
        selectedColor != oldWidget.selectedColor;
  }

  Widget buildMotionTabBar(BuildContext context) {
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

    // MotionTabBar đã được thay thế bằng SalomonBottomBar
    // Giữ lại method này để tương thích với code cũ nhưng không sử dụng
    return const SizedBox.shrink();
    /* return MotionTabBar(
      labels: labels,
      initialSelectedTab: initialSelectedTab,
      icons: icons,
      tabSize: 50,
      tabBarHeight: 60,
      textStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      tabIconColor: Colors.grey.shade400,
      tabIconSize: 28.0,
      tabIconSelectedSize: 26.0,
      tabSelectedColor: selectedColor,
      tabIconSelectedColor: Colors.white,
      tabBarColor: Colors.white,
      onTabItemSelected: onTabItemSelected,
    ); */
  }
}
