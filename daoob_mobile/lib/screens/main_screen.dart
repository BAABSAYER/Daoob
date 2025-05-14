import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:daoob_mobile/screens/home_screen.dart';
import 'package:daoob_mobile/screens/event_requests_screen.dart';
import 'package:daoob_mobile/screens/chat_list_screen.dart';
import 'package:daoob_mobile/screens/profile_screen.dart';
import 'package:daoob_mobile/services/auth_service.dart';
import 'package:daoob_mobile/l10n/language_provider.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final List<Widget> _screenOptions = [];
  
  @override
  void initState() {
    super.initState();
    
    // Initialize screens once
    _screenOptions.addAll([
      const HomeScreen(),
      const EventRequestsScreen(),
      const ChatListScreen(),
      const ProfileScreen(),
    ]);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final translations = languageProvider.getTranslations();
    final authService = Provider.of<AuthService>(context);
    
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screenOptions,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Theme.of(context).primaryColor,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white.withOpacity(0.6),
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: translations['home'] ?? 'Home',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.event_note),
            label: translations['myRequests'] ?? 'My Requests',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              isLabelVisible: authService.unreadMessageCount > 0,
              label: Text(
                authService.unreadMessageCount.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
              child: const Icon(Icons.chat),
            ),
            label: translations['messages'] ?? 'Messages',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: translations['profile'] ?? 'Profile',
          ),
        ],
      ),
    );
  }
}