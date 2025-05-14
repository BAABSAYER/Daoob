import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:daoob_mobile/screens/messages_screen.dart';
import 'package:daoob_mobile/screens/chat_screen.dart';
import 'package:daoob_mobile/screens/event_selection_screen.dart';
import 'package:daoob_mobile/screens/event_requests_screen.dart';
import 'package:daoob_mobile/services/auth_service.dart';
import 'package:daoob_mobile/services/booking_service.dart';
import 'package:daoob_mobile/services/message_service.dart';
import 'package:daoob_mobile/l10n/language_provider.dart';
import 'package:daoob_mobile/providers/event_provider.dart';
import 'package:daoob_mobile/models/booking.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Load data when the home screen is created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = Provider.of<AuthService>(context, listen: false);
      final bookingService = Provider.of<BookingService>(context, listen: false);
      final messageService = Provider.of<MessageService>(context, listen: false);
      
      // Load bookings
      bookingService.loadBookings(authService);
      
      // Initialize message service
      messageService.initialize(authService);
    });
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    bool isArabic = languageProvider.locale.languageCode == 'ar';
    final authService = Provider.of<AuthService>(context);
    final bookingService = Provider.of<BookingService>(context);
    final user = authService.user;
    
    // Initialize EventProvider
    final eventProvider = Provider.of<EventProvider>(context);
    
    final List<Widget> pages = [
      // Home page content with categories
      Center(
        child: Column(
          children: [
            const SizedBox(height: 24),
            Text(
              isArabic ? 'مرحبًا، ${user?.name ?? ''}!' : 'Welcome, ${user?.name ?? ''}!',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isArabic 
                ? 'ماذا تخطط اليوم؟'
                : 'What are you planning today?',
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            
            // New Event Request button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6A3DE8),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EventSelectionScreen(),
                    ),
                  );
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.celebration, size: 24),
                    SizedBox(width: 10),
                    Text(
                      isArabic ? 'طلب تنظيم حدث جديد' : 'Plan a New Event',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 24),
            
            // Categories section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isArabic ? 'الفئات' : 'Categories',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/categories');
                    },
                    child: Text(
                      isArabic ? 'عرض الكل' : 'View All',
                      style: const TextStyle(
                        color: Color(0xFF6A3DE8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Category cards
            SizedBox(
              height: 140,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                children: [
                  _buildCategoryCard(
                    context,
                    isArabic ? 'زفاف' : 'Wedding',
                    Icons.favorite,
                    onTap: () => _navigateToCategory('wedding'),
                  ),
                  _buildCategoryCard(
                    context,
                    isArabic ? 'شركات' : 'Corporate',
                    Icons.business,
                    onTap: () => _navigateToCategory('corporate'),
                  ),
                  _buildCategoryCard(
                    context,
                    isArabic ? 'أعياد ميلاد' : 'Birthday',
                    Icons.cake,
                    onTap: () => _navigateToCategory('birthday'),
                  ),
                  _buildCategoryCard(
                    context,
                    isArabic ? 'مناسبة مخصصة' : 'Custom',
                    Icons.edit,
                    onTap: () => Navigator.pushNamed(context, '/custom-event'),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Recent bookings section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isArabic ? 'الحجوزات الأخيرة' : 'Recent Bookings',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedIndex = 1; // Switch to bookings tab
                      });
                    },
                    child: Text(
                      isArabic ? 'عرض الكل' : 'View All',
                      style: const TextStyle(
                        color: Color(0xFF6A3DE8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Recent bookings list
            Expanded(
              child: bookingService.isLoading
                ? const Center(child: CircularProgressIndicator())
                : bookingService.bookings.isEmpty
                  ? Center(
                      child: Text(
                        isArabic 
                          ? 'لا توجد حجوزات حتى الآن'
                          : 'No bookings yet',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      itemCount: bookingService.bookings.length > 3 
                        ? 3 
                        : bookingService.bookings.length,
                      itemBuilder: (context, index) {
                        final booking = bookingService.bookings[index];
                        return _buildBookingCard(context, booking, isArabic);
                      },
                    ),
            ),
          ],
        ),
      ),
      
      // Event Requests page (replacing Bookings)
      const EventRequestsScreen(),
      
      // Messages page
      const MessagesScreen(),
      
      // Profile page
      _buildProfilePage(context, authService, languageProvider, isArabic),
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
            icon: const Icon(Icons.event_note_outlined),
            label: isArabic ? 'الطلبات' : 'Requests',
            selectedIcon: const Icon(Icons.event_note),
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

  void _navigateToCategory(String categoryId) {
    // Navigate to event questionnaire for this category
    Navigator.pushNamed(
      context, 
      '/event-questionnaire',
      arguments: categoryId,
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    String title,
    IconData icon, {
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF6A3DE8).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: const Color(0xFF6A3DE8),
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard(BuildContext context, Booking booking, bool isArabic) {
    // Determine status color
    Color statusColor;
    switch (booking.status) {
      case 'confirmed':
        statusColor = Colors.green;
        break;
      case 'pending':
        statusColor = Colors.orange;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        break;
      case 'completed':
        statusColor = Colors.blue;
        break;
      default:
        statusColor = Colors.grey;
    }

    String statusText = booking.status;
    if (isArabic) {
      switch (booking.status) {
        case 'confirmed':
          statusText = 'مؤكد';
          break;
        case 'pending':
          statusText = 'قيد الانتظار';
          break;
        case 'cancelled':
          statusText = 'ملغى';
          break;
        case 'completed':
          statusText = 'مكتمل';
          break;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  booking.eventType ?? 'Unknown Event',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.event,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 8),
                Text(
                  '${booking.eventDate.day}/${booking.eventDate.month}/${booking.eventDate.year}',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.payments_outlined,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 8),
                Text(
                  '\$${booking.totalPrice.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                  ),
                ),
                const Spacer(),
                Text(
                  booking.packageType,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6A3DE8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingsPage(
    BuildContext context, 
    BookingService bookingService, 
    bool isArabic,
    User? user,
  ) {
    if (bookingService.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (bookingService.bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              isArabic ? 'لا توجد حجوزات' : 'No bookings yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isArabic 
                ? 'ابدأ باستكشاف الفئات وحجز مناسبتك القادمة'
                : 'Start exploring categories and book your next event',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6A3DE8),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                setState(() {
                  _selectedIndex = 0; // Go to home tab
                });
              },
              child: Text(
                isArabic ? 'استكشاف الفئات' : 'Explore Categories'
              ),
            ),
          ],
        ),
      );
    }

    // Group bookings by status
    final Map<String, List<Booking>> bookingsByStatus = {
      'pending': [],
      'confirmed': [],
      'completed': [],
      'cancelled': [],
    };

    for (final booking in bookingService.bookings) {
      if (bookingsByStatus.containsKey(booking.status)) {
        bookingsByStatus[booking.status]!.add(booking);
      } else {
        bookingsByStatus['pending']!.add(booking);
      }
    }

    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: isArabic ? 'قيد الانتظار' : 'Pending'),
              Tab(text: isArabic ? 'مؤكد' : 'Confirmed'),
              Tab(text: isArabic ? 'مكتمل' : 'Completed'),
              Tab(text: isArabic ? 'ملغى' : 'Cancelled'),
            ],
            labelColor: const Color(0xFF6A3DE8),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF6A3DE8),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildBookingsList(bookingsByStatus['pending']!, isArabic),
                _buildBookingsList(bookingsByStatus['confirmed']!, isArabic),
                _buildBookingsList(bookingsByStatus['completed']!, isArabic),
                _buildBookingsList(bookingsByStatus['cancelled']!, isArabic),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingsList(List<Booking> bookings, bool isArabic) {
    if (bookings.isEmpty) {
      return Center(
        child: Text(
          isArabic ? 'لا توجد حجوزات في هذه الفئة' : 'No bookings in this category',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        return _buildBookingCard(context, bookings[index], isArabic);
      },
    );
  }

  Widget _buildProfilePage(
    BuildContext context, 
    AuthService authService, 
    LanguageProvider languageProvider,
    bool isArabic,
  ) {
    final user = authService.user;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile header
          Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF6A3DE8).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    user?.name?.isNotEmpty == true 
                      ? user!.name![0].toUpperCase() 
                      : 'U',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6A3DE8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.name ?? 'User',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      user?.email ?? '',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                      ),
                    ),
                    Text(
                      isArabic
                        ? user?.userType == 'vendor' ? 'مزود خدمة' : 'عميل'
                        : user?.userType == 'vendor' ? 'Vendor' : 'Client',
                      style: TextStyle(
                        color: const Color(0xFF6A3DE8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Settings section
          Text(
            isArabic ? 'الإعدادات' : 'Settings',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Language setting
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.language),
            title: Text(isArabic ? 'اللغة' : 'Language'),
            trailing: DropdownButton<String>(
              value: isArabic ? 'ar' : 'en',
              underline: Container(),
              items: [
                DropdownMenuItem(
                  value: 'en',
                  child: const Text('English'),
                ),
                DropdownMenuItem(
                  value: 'ar',
                  child: const Text('العربية'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  languageProvider.setLocale(Locale(value, ''));
                }
              },
            ),
          ),
          
          // Removed offline mode toggle as we now always use server API
          
          const Divider(),
          
          // Logout button
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(
              Icons.logout,
              color: Colors.red,
            ),
            title: Text(
              isArabic ? 'تسجيل الخروج' : 'Logout',
              style: const TextStyle(
                color: Colors.red,
              ),
            ),
            onTap: () async {
              await authService.logout();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
          
          const SizedBox(height: 32),
          
          // App info
          Center(
            child: Column(
              children: [
                const Text(
                  'DAOOB',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6A3DE8),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isArabic ? 'منصة إدارة الأحداث الذكية' : 'Smart Event Management Platform',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
