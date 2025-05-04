import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:daoob_mobile/services/auth_service.dart';
import 'package:daoob_mobile/l10n/language_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    bool isArabic = languageProvider.locale.languageCode == 'ar';
    final authService = Provider.of<AuthService>(context);
    final user = authService.user;
    
    final List<Widget> pages = [
      // Home page content
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isArabic ? 'مرحبًا!' : 'Welcome!',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isArabic 
                ? 'أنت تستخدم تطبيق دؤوب بنجاح.'
                : 'You are successfully using the DAOOB app.',
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              user != null
                ? isArabic 
                  ? 'مسجل الدخول كـ: ${user.name ?? user.email}'
                  : 'Logged in as: ${user.name ?? user.email}'
                : isArabic
                  ? 'غير مسجل الدخول'
                  : 'Not logged in',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isArabic
                ? 'نوع المستخدم: ${user?.userType == 'vendor' ? 'مزود خدمة' : 'عميل'}'
                : 'User type: ${user?.userType == 'vendor' ? 'Vendor' : 'Client'}',
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 36),
            ElevatedButton(
              onPressed: () async {
                await authService.logout();
                if (mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6A3DE8),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                isArabic ? 'تسجيل الخروج' : 'Logout',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
      
      // Bookings page placeholder
      Center(
        child: Text(
          isArabic ? 'الحجوزات' : 'Bookings',
          style: const TextStyle(fontSize: 24),
        ),
      ),
      
      // Messages page placeholder
      Center(
        child: Text(
          isArabic ? 'الرسائل' : 'Messages',
          style: const TextStyle(fontSize: 24),
        ),
      ),
      
      // Profile page placeholder
      Center(
        child: Text(
          isArabic ? 'الملف الشخصي' : 'Profile',
          style: const TextStyle(fontSize: 24),
        ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isArabic ? 'دؤوب' : 'DAOOB',
          style: TextStyle(
            fontFamily: isArabic ? 'Almarai' : 'Roboto',
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF6A3DE8),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              isArabic ? Icons.language : Icons.translate,
              color: Colors.white,
            ),
            onPressed: () {
              // Toggle language
              languageProvider.setLocale(
                isArabic ? const Locale('en', '') : const Locale('ar', '')
              );
            },
          ),
        ],
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            label: isArabic ? 'الرئيسية' : 'Home',
            selectedIcon: const Icon(Icons.home),
          ),
          NavigationDestination(
            icon: const Icon(Icons.calendar_today_outlined),
            label: isArabic ? 'الحجوزات' : 'Bookings',
            selectedIcon: const Icon(Icons.calendar_today),
          ),
          NavigationDestination(
            icon: const Icon(Icons.chat_outlined),
            label: isArabic ? 'الرسائل' : 'Messages',
            selectedIcon: const Icon(Icons.chat),
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            label: isArabic ? 'حسابي' : 'Profile',
            selectedIcon: const Icon(Icons.person),
          ),
        ],
      ),
    );
  }
}
