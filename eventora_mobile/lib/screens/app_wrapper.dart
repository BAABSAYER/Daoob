import 'package:flutter/material.dart';
import 'package:eventora_app/screens/home/home_screen.dart';
import 'package:eventora_app/screens/explore/explore_screen.dart';
import 'package:eventora_app/screens/bookings/bookings_screen.dart';
import 'package:eventora_app/screens/messages/messages_screen.dart';
import 'package:eventora_app/screens/profile/profile_screen.dart';
import 'package:eventora_app/widgets/bottom_nav.dart';

class AppWrapper extends StatefulWidget {
  const AppWrapper({Key? key}) : super(key: key);

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> {
  int _currentIndex = 0;
  
  final List<Widget> _screens = [
    const HomeScreen(),
    const ExploreScreen(),
    const BookingsScreen(),
    const MessagesScreen(),
    const ProfileScreen(),
  ];
  
  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNav(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}