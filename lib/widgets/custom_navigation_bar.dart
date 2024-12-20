import 'package:flutter/material.dart';
import 'package:unshelf_buyer/views/home_view.dart';
import 'package:unshelf_buyer/views/notifications_view.dart';
import 'package:unshelf_buyer/views/order_tracking_view.dart';
import 'package:unshelf_buyer/views/stores_view.dart';
import 'package:unshelf_buyer/views/map_view.dart';
import 'package:unshelf_buyer/views/profile_view.dart';

class CustomBottomNavigationBar extends StatefulWidget {
  final int currentIndex;

  const CustomBottomNavigationBar({
    Key? key,
    required this.currentIndex,
  }) : super(key: key);

  @override
  _CustomBottomNavigationBarState createState() => _CustomBottomNavigationBarState();
}

class _CustomBottomNavigationBarState extends State<CustomBottomNavigationBar> {
  late int _selectedIndex;

  // List of pages for navigation
  final List<Widget> _pages = [
    HomeView(),
    const StoresView(),
    const OrderTrackingView(),
    const NotificationsView(),
    ProfileView(),
  ];

  final List<String> _labels = ['Home', 'Stores', 'Orders', 'Notifications', 'My Stuff'];
  final List<IconData> _icons = [Icons.home, Icons.store, Icons.event_note, Icons.notifications, Icons.person];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.currentIndex;
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => _pages[index],
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 200),
      ),
    );

    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: Colors.white,
      elevation: 10,
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
      items: List.generate(_icons.length, (index) {
        return BottomNavigationBarItem(
          icon: AnimatedScale(
            scale: _selectedIndex == index ? 1.2 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: Icon(_icons[index]),
          ),
          label: _labels[index],
        );
      }),
    );
  }
}
