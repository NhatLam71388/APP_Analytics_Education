import 'package:flutter/material.dart';
import 'giao_vien_home.dart';
import 'ai_assistant_screen.dart';
import '../widgets/salomon_tab_bar_provider.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';

class GiaoVienMain extends StatefulWidget {
  const GiaoVienMain({super.key});

  @override
  State<GiaoVienMain> createState() => _GiaoVienMainState();
}

class _GiaoVienMainState extends State<GiaoVienMain> {
  late PageController _pageController;
  int _currentIndex = 0;

  final List<SalomonBottomBarItem> _navBarItems = [
    SalomonBottomBarItem(
      icon: const Icon(Icons.home),
      title: const Text("Trang chủ"),
      selectedColor: Colors.green,
    ),
    SalomonBottomBarItem(
      icon: const Icon(Icons.auto_awesome),
      title: const Text("Trợ lý AI"),
      selectedColor: Colors.green,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    return SalomonTabBarProvider(
      items: _navBarItems,
      initialSelectedIndex: 0,
      currentIndex: _currentIndex,
      selectedItemColor: Colors.green,
      unselectedItemColor: Colors.grey,
      onTabSelected: _onTabSelected,
      child: Builder(
        builder: (context) => Scaffold(
          body: PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            children: const [
              GiaoVienHome(),
              GiaoVienAIAssistantScreen(),
            ],
          ),
          bottomNavigationBar: SalomonTabBarProvider.of(context)!.buildSalomonBottomBar(context),
        ),
      ),
    );
  }
}
