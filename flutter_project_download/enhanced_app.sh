#!/bin/bash

echo "=== Creating Enhanced DAOOB Flutter App with Full Functionality ==="

# Get the script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd "$SCRIPT_DIR"

# Check for Flutter
if ! command -v flutter &> /dev/null; then
    echo "Flutter is not installed or not in your PATH. Please install Flutter first."
    exit 1
fi

# Clean any previous attempts
if [ -d "eventora_mobile" ]; then
    echo "Removing existing eventora_mobile directory..."
    rm -rf eventora_mobile
fi

# Create the Flutter project from scratch
echo "Creating a new Flutter project..."
flutter create --org com.daoob eventora_mobile

# Navigate to the project
cd eventora_mobile

# Create necessary directories
mkdir -p assets/images lib/models lib/screens lib/services lib/widgets lib/utils lib/l10n
mkdir -p assets/lang

# Copy the logo
echo "Setting up app logo..."
cp "../WhatsApp Image 2025-04-06 at 21.40.44_8e7cb969.jpg" assets/images/daoob-logo.jpg

# Add a localization utility class to handle language switching
cat > lib/l10n/app_localizations.dart << 'EOL'
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocalizations {
  final Locale locale;
  Map<String, String> _localizedStrings = {};

  AppLocalizations(this.locale);

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  Future<bool> load() async {
    String jsonString = await rootBundle.loadString('assets/lang/${locale.languageCode}.json');
    Map<String, dynamic> jsonMap = json.decode(jsonString);
    _localizedStrings = jsonMap.map((key, value) {
      return MapEntry(key, value.toString());
    });
    return true;
  }

  String translate(String key) {
    return _localizedStrings[key] ?? key;
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'ar'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    AppLocalizations localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
EOL

# Add a language selection provider
cat > lib/l10n/language_provider.dart << 'EOL'
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');
  bool _isRTL = false;

  Locale get locale => _locale;
  bool get isRTL => _isRTL;

  LanguageProvider() {
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString('language_code');
    if (savedLanguage != null) {
      _locale = Locale(savedLanguage);
      _isRTL = savedLanguage == 'ar';
      notifyListeners();
    }
  }

  Future<void> setLocale(String languageCode) async {
    _locale = Locale(languageCode);
    _isRTL = languageCode == 'ar';
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', languageCode);
    
    notifyListeners();
  }
}
EOL

# Create model files
echo "Creating model files..."

# Booking Model
cat > lib/models/booking.dart << 'EOL'
class Booking {
  final int id;
  final int clientId;
  final int vendorId;
  final int? serviceId;
  final String eventType;
  final DateTime eventDate;
  final int guestCount;
  final String? specialRequests;
  final double totalPrice;
  final String status;
  final DateTime createdAt;
  String? vendorName;  // For display purposes
  String? serviceName; // For display purposes

  Booking({
    required this.id,
    required this.clientId,
    required this.vendorId,
    this.serviceId,
    required this.eventType,
    required this.eventDate,
    required this.guestCount,
    this.specialRequests,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
    this.vendorName,
    this.serviceName,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'],
      clientId: json['clientId'],
      vendorId: json['vendorId'],
      serviceId: json['serviceId'],
      eventType: json['eventType'],
      eventDate: DateTime.parse(json['eventDate']),
      guestCount: json['guestCount'],
      specialRequests: json['specialRequests'],
      totalPrice: json['totalPrice'].toDouble(),
      status: json['status'],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      vendorName: json['vendorName'],
      serviceName: json['serviceName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clientId': clientId,
      'vendorId': vendorId,
      'serviceId': serviceId,
      'eventType': eventType,
      'eventDate': eventDate.toIso8601String(),
      'guestCount': guestCount,
      'specialRequests': specialRequests,
      'totalPrice': totalPrice,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'vendorName': vendorName,
      'serviceName': serviceName,
    };
  }

  static List<Booking> sampleBookings() {
    return [
      Booking(
        id: 1,
        clientId: 1,
        vendorId: 1,
        serviceId: 1,
        eventType: 'wedding',
        eventDate: DateTime.now().add(Duration(days: 30)),
        guestCount: 100,
        specialRequests: 'Need vegetarian options',
        totalPrice: 5000.0,
        status: 'confirmed',
        createdAt: DateTime.now().subtract(Duration(days: 15)),
        vendorName: 'Elegant Events',
        serviceName: 'Premium Wedding Package',
      ),
      Booking(
        id: 2,
        clientId: 1,
        vendorId: 2,
        serviceId: 3,
        eventType: 'corporate',
        eventDate: DateTime.now().add(Duration(days: 15)),
        guestCount: 50,
        specialRequests: 'Projector needed for presentation',
        totalPrice: 2500.0,
        status: 'pending',
        createdAt: DateTime.now().subtract(Duration(days: 5)),
        vendorName: 'Corporate Solutions',
        serviceName: 'Business Conference Package',
      ),
      Booking(
        id: 3,
        clientId: 1,
        vendorId: 3,
        serviceId: 5,
        eventType: 'birthday',
        eventDate: DateTime.now().subtract(Duration(days: 10)),
        guestCount: 30,
        specialRequests: 'Birthday cake with "Happy 30th" text',
        totalPrice: 1200.0,
        status: 'completed',
        createdAt: DateTime.now().subtract(Duration(days: 45)),
        vendorName: 'Celebration Masters',
        serviceName: 'Birthday Bash Package',
      ),
    ];
  }
}
EOL

# Vendor Model
cat > lib/models/vendor.dart << 'EOL'
class Vendor {
  final int id;
  final int userId;
  final String businessName;
  final String category;
  final String description;
  final double basePrice;
  final String location;
  final String? logo;
  final List<String>? portfolioImages;
  final double? rating;
  final int? reviewCount;

  Vendor({
    required this.id,
    required this.userId,
    required this.businessName,
    required this.category,
    required this.description,
    required this.basePrice,
    required this.location,
    this.logo,
    this.portfolioImages,
    this.rating,
    this.reviewCount,
  });

  factory Vendor.fromJson(Map<String, dynamic> json) {
    return Vendor(
      id: json['id'],
      userId: json['userId'],
      businessName: json['businessName'],
      category: json['category'],
      description: json['description'],
      basePrice: json['basePrice'].toDouble(),
      location: json['location'],
      logo: json['logo'],
      portfolioImages: json['portfolioImages'] != null
          ? List<String>.from(json['portfolioImages'])
          : null,
      rating: json['rating']?.toDouble(),
      reviewCount: json['reviewCount'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'businessName': businessName,
      'category': category,
      'description': description,
      'basePrice': basePrice,
      'location': location,
      'logo': logo,
      'portfolioImages': portfolioImages,
      'rating': rating,
      'reviewCount': reviewCount,
    };
  }

  static List<Vendor> sampleVendors() {
    return [
      Vendor(
        id: 1,
        userId: 101,
        businessName: 'Elegant Events',
        category: 'Event Planner',
        description: 'We specialize in creating beautiful, memorable events for all occasions.',
        basePrice: 2000.0,
        location: 'New York, NY',
        rating: 4.8,
        reviewCount: 120,
      ),
      Vendor(
        id: 2,
        userId: 102,
        businessName: 'Delicious Catering',
        category: 'Catering',
        description: 'Providing exceptional food and service for your special event.',
        basePrice: 25.0, // per person
        location: 'Los Angeles, CA',
        rating: 4.5,
        reviewCount: 85,
      ),
      Vendor(
        id: 3,
        userId: 103,
        businessName: 'Celebration Masters',
        category: 'Event Planner',
        description: 'Full-service event planning for birthdays, anniversaries, and special occasions.',
        basePrice: 1500.0,
        location: 'Chicago, IL',
        rating: 4.7,
        reviewCount: 93,
      ),
      Vendor(
        id: 4,
        userId: 104,
        businessName: 'Picture Perfect Photography',
        category: 'Photography',
        description: 'Capturing your special moments with artistic and creative photography.',
        basePrice: 1200.0,
        location: 'Miami, FL',
        rating: 4.9,
        reviewCount: 150,
      ),
      Vendor(
        id: 5,
        userId: 105,
        businessName: 'Melodic Moments',
        category: 'Music & Entertainment',
        description: 'Professional DJs and live bands for any event.',
        basePrice: 800.0,
        location: 'Nashville, TN',
        rating: 4.6,
        reviewCount: 78,
      ),
    ];
  }
}
EOL

# Service Model
cat > lib/models/service.dart << 'EOL'
class Service {
  final int id;
  final int vendorId;
  final String name;
  final String description;
  final double price;
  final String? image;

  Service({
    required this.id,
    required this.vendorId,
    required this.name,
    required this.description,
    required this.price,
    this.image,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'],
      vendorId: json['vendorId'],
      name: json['name'],
      description: json['description'],
      price: json['price'].toDouble(),
      image: json['image'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vendorId': vendorId,
      'name': name,
      'description': description,
      'price': price,
      'image': image,
    };
  }

  static List<Service> getServicesForVendor(int vendorId) {
    List<Service> allServices = [
      Service(
        id: 1,
        vendorId: 1,
        name: 'Basic Wedding Package',
        description: 'Essential planning services for your wedding day.',
        price: 3000.0,
      ),
      Service(
        id: 2,
        vendorId: 1,
        name: 'Premium Wedding Package',
        description: 'Comprehensive wedding planning from engagement to reception.',
        price: 5000.0,
      ),
      Service(
        id: 3,
        vendorId: 2,
        name: 'Standard Catering Package',
        description: 'Buffet-style service with a variety of menu options.',
        price: 25.0, // per person
      ),
      Service(
        id: 4,
        vendorId: 2,
        name: 'Deluxe Catering Package',
        description: 'Plated service with premium menu options and open bar.',
        price: 40.0, // per person
      ),
      Service(
        id: 5,
        vendorId: 3,
        name: 'Birthday Bash Package',
        description: 'Complete birthday party planning and coordination.',
        price: 1200.0,
      ),
      Service(
        id: 6,
        vendorId: 4,
        name: 'Event Photography Package',
        description: '4 hours of photography coverage with edited digital photos.',
        price: 1200.0,
      ),
      Service(
        id: 7,
        vendorId: 5,
        name: 'DJ Services',
        description: '4 hours of DJ services with professional sound equipment.',
        price: 800.0,
      ),
      Service(
        id: 8,
        vendorId: 5,
        name: 'Live Band Performance',
        description: '3 hours of live music with a 5-piece band.',
        price: 2000.0,
      ),
    ];

    return allServices.where((service) => service.vendorId == vendorId).toList();
  }
}
EOL

# Message Model
cat > lib/models/message.dart << 'EOL'
class Message {
  final int id;
  final int senderId;
  final int receiverId;
  final String content;
  final DateTime timestamp;
  final bool isRead;
  final String? senderName; // For display purposes

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.timestamp,
    required this.isRead,
    this.senderName,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      senderId: json['senderId'],
      receiverId: json['receiverId'],
      content: json['content'],
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['isRead'] ?? false,
      senderName: json['senderName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'senderName': senderName,
    };
  }

  static List<Message> getConversation(int userId, int receiverId) {
    List<Message> allMessages = [
      Message(
        id: 1,
        senderId: 1,
        receiverId: 101,
        content: 'Hello, I\'m interested in your services for my wedding.',
        timestamp: DateTime.now().subtract(Duration(days: 5, hours: 3)),
        isRead: true,
        senderName: 'John Doe',
      ),
      Message(
        id: 2,
        senderId: 101,
        receiverId: 1,
        content: 'Hi John! Thank you for your interest. When is your wedding date?',
        timestamp: DateTime.now().subtract(Duration(days: 5, hours: 2)),
        isRead: true,
        senderName: 'Elegant Events',
      ),
      Message(
        id: 3,
        senderId: 1,
        receiverId: 101,
        content: 'We\'re planning for June 15th next year.',
        timestamp: DateTime.now().subtract(Duration(days: 5, hours: 1)),
        isRead: true,
        senderName: 'John Doe',
      ),
      Message(
        id: 4,
        senderId: 101,
        receiverId: 1,
        content: 'That\'s a beautiful time for a wedding! Do you know roughly how many guests you\'ll have?',
        timestamp: DateTime.now().subtract(Duration(days: 4, hours: 23)),
        isRead: true,
        senderName: 'Elegant Events',
      ),
      Message(
        id: 5,
        senderId: 1,
        receiverId: 101,
        content: 'We\'re expecting around 100 guests.',
        timestamp: DateTime.now().subtract(Duration(days: 4, hours: 22)),
        isRead: true,
        senderName: 'John Doe',
      ),
      Message(
        id: 6,
        senderId: 1,
        receiverId: 102,
        content: 'Hi, do you offer vegetarian options in your catering menu?',
        timestamp: DateTime.now().subtract(Duration(days: 3, hours: 5)),
        isRead: true,
        senderName: 'John Doe',
      ),
      Message(
        id: 7,
        senderId: 102,
        receiverId: 1,
        content: 'Yes, we have several vegetarian options available! Would you like to see our menu?',
        timestamp: DateTime.now().subtract(Duration(days: 3, hours: 4)),
        isRead: true,
        senderName: 'Delicious Catering',
      ),
      Message(
        id: 8,
        senderId: 1,
        receiverId: 102,
        content: 'That would be great, thank you!',
        timestamp: DateTime.now().subtract(Duration(days: 3, hours: 3)),
        isRead: true,
        senderName: 'John Doe',
      ),
    ];

    return allMessages.where((message) => 
      (message.senderId == userId && message.receiverId == receiverId) || 
      (message.senderId == receiverId && message.receiverId == userId)).toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  static List<Message> getConversationsPreview(int userId) {
    // Group all messages by conversation partner
    Map<int, List<Message>> conversationMessages = {};
    List<Message> allMessages = [];
    
    // Add the static messages we defined previously
    allMessages.addAll([
      Message(
        id: 1,
        senderId: 1,
        receiverId: 101,
        content: 'Hello, I\'m interested in your services for my wedding.',
        timestamp: DateTime.now().subtract(Duration(days: 5, hours: 3)),
        isRead: true,
        senderName: 'John Doe',
      ),
      Message(
        id: 2,
        senderId: 101,
        receiverId: 1,
        content: 'Hi John! Thank you for your interest. When is your wedding date?',
        timestamp: DateTime.now().subtract(Duration(days: 5, hours: 2)),
        isRead: true,
        senderName: 'Elegant Events',
      ),
      Message(
        id: 6,
        senderId: 1,
        receiverId: 102,
        content: 'Hi, do you offer vegetarian options in your catering menu?',
        timestamp: DateTime.now().subtract(Duration(days: 3, hours: 5)),
        isRead: true,
        senderName: 'John Doe',
      ),
      Message(
        id: 7,
        senderId: 102,
        receiverId: 1,
        content: 'Yes, we have several vegetarian options available! Would you like to see our menu?',
        timestamp: DateTime.now().subtract(Duration(days: 3, hours: 4)),
        isRead: true,
        senderName: 'Delicious Catering',
      ),
    ]);
    
    // Filter for messages relevant to this user
    List<Message> userMessages = allMessages.where((message) => 
      message.senderId == userId || message.receiverId == userId).toList();
    
    // Group by conversation partner
    for (var message in userMessages) {
      int partnerId = message.senderId == userId ? message.receiverId : message.senderId;
      if (!conversationMessages.containsKey(partnerId)) {
        conversationMessages[partnerId] = [];
      }
      conversationMessages[partnerId]!.add(message);
    }
    
    // Get latest message from each conversation
    List<Message> latestMessages = [];
    conversationMessages.forEach((partnerId, messages) {
      messages.sort((a, b) => b.timestamp.compareTo(a.timestamp)); // sort desc
      latestMessages.add(messages.first);
    });
    
    // Sort conversations by latest message
    latestMessages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return latestMessages;
  }
}
EOL

# User Model
cat > lib/models/user.dart << 'EOL'
class User {
  final int id;
  final String name;
  final String email;
  final String role;
  final String? phone;
  final String? profileImage;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.profileImage,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'] ?? json['username'] ?? 'Unknown',
      email: json['email'],
      role: json['role'],
      phone: json['phone'],
      profileImage: json['profileImage'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'phone': phone,
      'profileImage': profileImage,
    };
  }

  static User offlineUser() {
    return User(
      id: 1,
      name: 'John Doe',
      email: 'john@example.com',
      role: 'client',
      phone: '555-123-4567',
    );
  }

  static User getUser(int id) {
    List<User> users = [
      User(
        id: 1,
        name: 'John Doe',
        email: 'john@example.com',
        role: 'client',
        phone: '555-123-4567',
      ),
      User(
        id: 101,
        name: 'Elegant Events',
        email: 'contact@elegantevents.com',
        role: 'vendor',
        phone: '555-987-6543',
      ),
      User(
        id: 102,
        name: 'Delicious Catering',
        email: 'info@deliciouscatering.com',
        role: 'vendor',
        phone: '555-567-8901',
      ),
    ];
    
    return users.firstWhere((user) => user.id == id, 
      orElse: () => User(
        id: id,
        name: 'User $id',
        email: 'user$id@example.com',
        role: 'client',
      ));
  }
}
EOL

# Create Services
echo "Creating enhanced services..."

# Enhanced Auth Service
cat > lib/services/auth_service.dart << 'EOL'
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eventora_mobile/models/user.dart';

class AuthService extends ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isLoading = false;
  bool _offlineMode = false;
  String? _errorMessage;
  String? _token;
  User? _user;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  bool get offlineMode => _offlineMode;
  String? get errorMessage => _errorMessage;
  String? get token => _token;
  User? get user => _user;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _offlineMode = prefs.getBool('offline_mode') ?? false;
    
    if (_offlineMode) {
      _isAuthenticated = true;
      _user = User.offlineUser();
      notifyListeners();
      return;
    }
    
    final storedToken = prefs.getString('auth_token');
    if (storedToken != null) {
      _token = storedToken;
      final userJson = prefs.getString('user_data');
      if (userJson != null) {
        try {
          _user = User.fromJson(json.decode(userJson));
          _isAuthenticated = true;
        } catch (e) {
          // Invalid user data, clear it
          await prefs.remove('user_data');
        }
      }
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    if (_offlineMode) {
      _isAuthenticated = true;
      _user = User.offlineUser();
      notifyListeners();
      return true;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Simulate API call
      await Future.delayed(Duration(seconds: 1));
      
      // Check credentials (mock validation)
      if (email.isNotEmpty && password.length >= 3) {
        _isAuthenticated = true;
        _token = 'sample_token_${DateTime.now().millisecondsSinceEpoch}';
        _user = User(
          id: 1,
          name: email.split('@')[0],
          email: email,
          role: 'client',
          phone: '555-123-4567',
        );
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', _token!);
        await prefs.setString('user_data', json.encode(_user!.toJson()));
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _isLoading = false;
        _errorMessage = 'Invalid email or password';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _isAuthenticated = false;
    _token = null;
    _user = null;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
    
    notifyListeners();
  }

  Future<void> setOfflineMode(bool value) async {
    _offlineMode = value;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('offline_mode', value);
    
    if (value) {
      _isAuthenticated = true;
      _user = User.offlineUser();
    } else {
      // Revert to online state
      await logout();
    }
    
    notifyListeners();
  }

  Future<bool> register(String name, String email, String password) async {
    if (_offlineMode) {
      _isAuthenticated = true;
      _user = User(
        id: 1,
        name: name,
        email: email,
        role: 'client',
      );
      notifyListeners();
      return true;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Simulate API call
      await Future.delayed(Duration(seconds: 1));
      
      _isAuthenticated = true;
      _token = 'sample_token_${DateTime.now().millisecondsSinceEpoch}';
      _user = User(
        id: 1,
        name: name,
        email: email,
        role: 'client',
      );
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', _token!);
      await prefs.setString('user_data', json.encode(_user!.toJson()));
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
EOL

# Enhanced API Service with mock data
cat > lib/services/api_service.dart << 'EOL'
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eventora_mobile/models/booking.dart';
import 'package:eventora_mobile/models/vendor.dart';
import 'package:eventora_mobile/models/service.dart';
import 'package:eventora_mobile/models/message.dart';
import 'package:eventora_mobile/models/user.dart';

class ApiService {
  static String get baseUrl {
    if (Platform.isAndroid) {
      // Android emulator localhost
      return 'http://10.0.2.2:5000';
    } else if (Platform.isIOS) {
      // iOS simulator localhost
      return 'http://localhost:5000';
    }
    // Web or other platforms
    return 'http://localhost:5000';
  }

  static Future<bool> isOfflineMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('offline_mode') ?? false;
  }

  // VENDORS
  static Future<List<Vendor>> getVendors({String? category}) async {
    if (await isOfflineMode()) {
      await Future.delayed(Duration(milliseconds: 500)); // Simulate network delay
      final vendors = Vendor.sampleVendors();
      if (category != null && category.isNotEmpty) {
        return vendors.where((v) => v.category.toLowerCase() == category.toLowerCase()).toList();
      }
      return vendors;
    }

    try {
      String endpoint = '/api/vendors';
      if (category != null && category.isNotEmpty) {
        endpoint += '?category=$category';
      }
      
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: await _getHeaders(),
      );
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Vendor.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load vendors: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching vendors: $e');
      return Vendor.sampleVendors();
    }
  }

  static Future<Vendor?> getVendorDetails(int vendorId) async {
    if (await isOfflineMode()) {
      await Future.delayed(Duration(milliseconds: 500)); // Simulate network delay
      final vendors = Vendor.sampleVendors();
      return vendors.firstWhere((v) => v.id == vendorId, orElse: () => vendors.first);
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/vendors/$vendorId'),
        headers: await _getHeaders(),
      );
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return Vendor.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load vendor details: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching vendor details: $e');
      return Vendor.sampleVendors().firstWhere((v) => v.id == vendorId, orElse: () => Vendor.sampleVendors().first);
    }
  }

  // SERVICES
  static Future<List<Service>> getVendorServices(int vendorId) async {
    if (await isOfflineMode()) {
      await Future.delayed(Duration(milliseconds: 500)); // Simulate network delay
      return Service.getServicesForVendor(vendorId);
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/vendors/$vendorId/services'),
        headers: await _getHeaders(),
      );
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Service.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load services: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching services: $e');
      return Service.getServicesForVendor(vendorId);
    }
  }

  // BOOKINGS
  static Future<List<Booking>> getBookings() async {
    if (await isOfflineMode()) {
      await Future.delayed(Duration(milliseconds: 500)); // Simulate network delay
      return Booking.sampleBookings();
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/bookings'),
        headers: await _getHeaders(),
      );
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Booking.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load bookings: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching bookings: $e');
      return Booking.sampleBookings();
    }
  }

  static Future<Booking> createBooking(Map<String, dynamic> bookingData) async {
    if (await isOfflineMode()) {
      await Future.delayed(Duration(milliseconds: 800)); // Simulate network delay
      final sampleBookings = Booking.sampleBookings();
      return Booking(
        id: sampleBookings.length + 1,
        clientId: 1,
        vendorId: bookingData['vendorId'],
        serviceId: bookingData['serviceId'],
        eventType: bookingData['eventType'],
        eventDate: DateTime.parse(bookingData['eventDate']),
        guestCount: bookingData['guestCount'],
        specialRequests: bookingData['specialRequests'],
        totalPrice: bookingData['totalPrice'].toDouble(),
        status: 'pending',
        createdAt: DateTime.now(),
        vendorName: 'Mock Vendor Name',
      );
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/bookings'),
        headers: await _getHeaders(),
        body: json.encode(bookingData),
      );
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return Booking.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to create booking: ${response.statusCode}');
      }
    } catch (e) {
      print('Error creating booking: $e');
      throw e;
    }
  }

  // MESSAGES
  static Future<List<Message>> getConversations() async {
    if (await isOfflineMode()) {
      await Future.delayed(Duration(milliseconds: 500)); // Simulate network delay
      return Message.getConversationsPreview(1); // User ID 1 in offline mode
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/conversations'),
        headers: await _getHeaders(),
      );
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Message.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load conversations: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching conversations: $e');
      return Message.getConversationsPreview(1);
    }
  }

  static Future<List<Message>> getMessages(int userId) async {
    if (await isOfflineMode()) {
      await Future.delayed(Duration(milliseconds: 500)); // Simulate network delay
      return Message.getConversation(1, userId); // User ID 1 in offline mode
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/messages/$userId'),
        headers: await _getHeaders(),
      );
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Message.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load messages: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching messages: $e');
      return Message.getConversation(1, userId);
    }
  }

  static Future<Message> sendMessage(Map<String, dynamic> messageData) async {
    if (await isOfflineMode()) {
      await Future.delayed(Duration(milliseconds: 800)); // Simulate network delay
      final existingMessages = Message.getConversation(
        messageData['senderId'], 
        messageData['receiverId']
      );
      return Message(
        id: existingMessages.length + 1,
        senderId: messageData['senderId'],
        receiverId: messageData['receiverId'],
        content: messageData['content'],
        timestamp: DateTime.now(),
        isRead: false,
        senderName: 'You',
      );
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/messages'),
        headers: await _getHeaders(),
        body: json.encode(messageData),
      );
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return Message.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to send message: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending message: $e');
      throw e;
    }
  }

  // USER
  static Future<User> getUserDetails(int userId) async {
    if (await isOfflineMode()) {
      await Future.delayed(Duration(milliseconds: 500)); // Simulate network delay
      return User.getUser(userId);
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/users/$userId'),
        headers: await _getHeaders(),
      );
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return User.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load user details: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching user details: $e');
      return User.getUser(userId);
    }
  }

  // Helper method to get headers including auth token
  static Future<Map<String, String>> _getHeaders() async {
    final headers = {'Content-Type': 'application/json'};
    
    if (await isOfflineMode()) {
      return headers;
    }
    
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    return headers;
  }
}
EOL

# Create UI Screens
echo "Creating enhanced screens..."

# Create basic vendor listing screen
cat > lib/screens/vendor_listing_screen.dart << 'EOL'
import 'package:flutter/material.dart';
import 'package:eventora_mobile/models/vendor.dart';
import 'package:eventora_mobile/services/api_service.dart';

class VendorListingScreen extends StatefulWidget {
  const VendorListingScreen({super.key});

  @override
  State<VendorListingScreen> createState() => _VendorListingScreenState();
}

class _VendorListingScreenState extends State<VendorListingScreen> {
  List<Vendor> _vendors = [];
  bool _isLoading = true;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadVendors();
  }

  Future<void> _loadVendors() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final vendors = await ApiService.getVendors(category: _selectedCategory);
      setState(() {
        _vendors = vendors;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading vendors: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildCategoryFilter(),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _vendors.isEmpty
                  ? const Center(child: Text('No vendors found'))
                  : ListView.builder(
                      itemCount: _vendors.length,
                      itemBuilder: (context, index) {
                        final vendor = _vendors[index];
                        return _buildVendorCard(vendor);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildCategoryFilter() {
    const categories = [
      'All',
      'Event Planner',
      'Catering',
      'Photography',
      'Music & Entertainment',
      'Venue',
    ];

    return Container(
      padding: const EdgeInsets.all(8.0),
      color: Colors.grey[100],
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: categories.map((category) {
            final isSelected = category == 'All'
                ? _selectedCategory == null
                : _selectedCategory == category;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: FilterChip(
                selected: isSelected,
                label: Text(category),
                onSelected: (_) {
                  setState(() {
                    _selectedCategory = category == 'All' ? null : category;
                  });
                  _loadVendors();
                },
                selectedColor: const Color(0xFF6A3DE8).withOpacity(0.2),
                checkmarkColor: const Color(0xFF6A3DE8),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildVendorCard(Vendor vendor) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/vendor-details',
            arguments: vendor.id,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: vendor.logo != null
                        ? Image.network(vendor.logo!)
                        : const Icon(Icons.business, size: 40, color: Colors.grey),
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vendor.businessName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18.0,
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          vendor.category,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 4.0),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 16, color: Colors.grey),
                            const SizedBox(width: 4.0),
                            Text(
                              vendor.location,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              Text(
                vendor.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Starting at \$${vendor.basePrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6A3DE8),
                    ),
                  ),
                  if (vendor.rating != null)
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 18),
                        const SizedBox(width: 4.0),
                        Text('${vendor.rating} (${vendor.reviewCount ?? 0})'),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
EOL

# Create vendor details screen
cat > lib/screens/vendor_detail_screen.dart << 'EOL'
import 'package:flutter/material.dart';
import 'package:eventora_mobile/models/vendor.dart';
import 'package:eventora_mobile/models/service.dart';
import 'package:eventora_mobile/services/api_service.dart';
import 'package:eventora_mobile/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class VendorDetailScreen extends StatefulWidget {
  final int vendorId;

  const VendorDetailScreen({super.key, required this.vendorId});

  @override
  State<VendorDetailScreen> createState() => _VendorDetailScreenState();
}

class _VendorDetailScreenState extends State<VendorDetailScreen> {
  Vendor? _vendor;
  List<Service> _services = [];
  bool _isLoading = true;
  bool _isBookingFormVisible = false;
  Service? _selectedService;
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 30));
  final _guestCountController = TextEditingController(text: '50');
  final _specialRequestsController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;
  bool _bookingSuccess = false;

  @override
  void initState() {
    super.initState();
    _loadVendorDetails();
  }

  @override
  void dispose() {
    _guestCountController.dispose();
    _specialRequestsController.dispose();
    super.dispose();
  }

  Future<void> _loadVendorDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final vendor = await ApiService.getVendorDetails(widget.vendorId);
      final services = await ApiService.getVendorServices(widget.vendorId);
      
      setState(() {
        _vendor = vendor;
        _services = services;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading vendor details: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _toggleBookingForm() {
    setState(() {
      _isBookingFormVisible = !_isBookingFormVisible;
      _errorMessage = null;
      _bookingSuccess = false;
    });
  }

  Future<void> _submitBooking() async {
    if (!_validateForm()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.user;
      
      if (user == null) {
        setState(() {
          _errorMessage = 'You must be logged in to book';
          _isSubmitting = false;
        });
        return;
      }

      final eventType = 'corporate'; // Default for demo
      final guestCount = int.parse(_guestCountController.text);
      final specialRequests = _specialRequestsController.text;
      
      // Calculate price based on guest count and service
      double totalPrice = _calculateTotalPrice();

      // Prepare booking data
      final bookingData = {
        'vendorId': _vendor!.id,
        'serviceId': _selectedService?.id,
        'eventType': eventType,
        'eventDate': _selectedDate.toIso8601String(),
        'guestCount': guestCount,
        'specialRequests': specialRequests,
        'totalPrice': totalPrice,
      };

      // Submit booking
      await ApiService.createBooking(bookingData);
      
      setState(() {
        _isSubmitting = false;
        _bookingSuccess = true;
        // Reset form
        _selectedService = null;
        _selectedDate = DateTime.now().add(const Duration(days: 30));
        _guestCountController.text = '50';
        _specialRequestsController.clear();
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error creating booking: $e';
        _isSubmitting = false;
      });
    }
  }

  bool _validateForm() {
    if (_selectedDate.isBefore(DateTime.now())) {
      setState(() {
        _errorMessage = 'Selected date must be in the future';
      });
      return false;
    }

    try {
      final guestCount = int.parse(_guestCountController.text);
      if (guestCount <= 0) {
        setState(() {
          _errorMessage = 'Guest count must be positive';
        });
        return false;
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Guest count must be a valid number';
      });
      return false;
    }

    return true;
  }

  double _calculateTotalPrice() {
    final guestCount = int.parse(_guestCountController.text);
    
    if (_selectedService != null) {
      return _selectedService!.price;
    } else {
      // Calculate based on base price and guest count
      return _vendor!.basePrice * guestCount * 0.1;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_vendor?.businessName ?? 'Vendor Details'),
        backgroundColor: const Color(0xFF6A3DE8),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _vendor == null
              ? const Center(child: Text('Vendor not found'))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildVendorHeader(),
                      const SizedBox(height: 16.0),
                      _buildVendorDescription(),
                      const SizedBox(height: 16.0),
                      _buildServicesList(),
                      const SizedBox(height: 16.0),
                      _buildBookingSection(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildVendorHeader() {
    return Container(
      width: double.infinity,
      height: 200,
      color: Colors.grey[300],
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.business, size: 60, color: Colors.grey),
                const SizedBox(height: 8.0),
                Text(
                  _vendor!.businessName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24.0,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              color: Colors.black.withOpacity(0.6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _vendor!.category,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_vendor!.rating != null)
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 18),
                        const SizedBox(width: 4.0),
                        Text(
                          '${_vendor!.rating} (${_vendor!.reviewCount ?? 0})',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVendorDescription() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18.0,
            ),
          ),
          const SizedBox(height: 8.0),
          Text(_vendor!.description),
          const SizedBox(height: 12.0),
          Row(
            children: [
              const Icon(Icons.location_on, size: 16, color: Colors.grey),
              const SizedBox(width: 4.0),
              Text(
                _vendor!.location,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          Text(
            'Starting at \$${_vendor!.basePrice.toStringAsFixed(2)}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF6A3DE8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Services',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18.0,
            ),
          ),
        ),
        const SizedBox(height: 8.0),
        _services.isEmpty
            ? const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text('No services available'),
              )
            : SizedBox(
                height: 160,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _services.length,
                  itemBuilder: (context, index) {
                    final service = _services[index];
                    return _buildServiceCard(service);
                  },
                ),
              ),
      ],
    );
  }

  Widget _buildServiceCard(Service service) {
    return Card(
      margin: const EdgeInsets.only(left: 16.0, right: 8.0, bottom: 8.0),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedService = service;
            _isBookingFormVisible = true;
          });
        },
        child: Container(
          width: 200,
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                service.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16.0,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8.0),
              Expanded(
                child: Text(
                  service.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                '\$${service.price.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6A3DE8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookingSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ElevatedButton(
            onPressed: _toggleBookingForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6A3DE8),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              minimumSize: const Size(double.infinity, 48),
            ),
            child: Text(_isBookingFormVisible ? 'Cancel Booking' : 'Book Now'),
          ),
          if (_isBookingFormVisible) ...[
            const SizedBox(height: 16.0),
            _buildBookingForm(),
          ],
        ],
      ),
    );
  }

  Widget _buildBookingForm() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _bookingSuccess
            ? _buildBookingSuccess()
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Book This Vendor',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18.0,
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  _buildServiceDropdown(),
                  const SizedBox(height: 16.0),
                  _buildDatePicker(),
                  const SizedBox(height: 16.0),
                  TextField(
                    controller: _guestCountController,
                    decoration: const InputDecoration(
                      labelText: 'Number of Guests',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16.0),
                  TextField(
                    controller: _specialRequestsController,
                    decoration: const InputDecoration(
                      labelText: 'Special Requests',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16.0),
                  _buildPriceSummary(),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 8.0),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                  const SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitBooking,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6A3DE8),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: _isSubmitting
                        ? const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          )
                        : const Text('Confirm Booking'),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildServiceDropdown() {
    return DropdownButtonFormField<Service?>(
      decoration: const InputDecoration(
        labelText: 'Select a Service',
        border: OutlineInputBorder(),
      ),
      value: _selectedService,
      items: [
        const DropdownMenuItem<Service?>(
          value: null,
          child: Text('Custom Service'),
        ),
        ..._services.map((service) {
          return DropdownMenuItem<Service>(
            value: service,
            child: Text(service.name),
          );
        }).toList(),
      ],
      onChanged: (value) {
        setState(() {
          _selectedService = value;
        });
      },
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _selectedDate,
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (picked != null) {
          setState(() {
            _selectedDate = picked;
          });
        }
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Event Date',
          border: OutlineInputBorder(),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(DateFormat('MMM d, yyyy').format(_selectedDate)),
            const Icon(Icons.calendar_today),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceSummary() {
    final totalPrice = _calculateTotalPrice();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Price Summary',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16.0,
          ),
        ),
        const SizedBox(height: 8.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Total'),
            Text(
              '\$${totalPrice.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF6A3DE8),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBookingSuccess() {
    return Column(
      children: [
        const Icon(
          Icons.check_circle,
          color: Colors.green,
          size: 60,
        ),
        const SizedBox(height: 16.0),
        const Text(
          'Booking Successful!',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20.0,
          ),
        ),
        const SizedBox(height: 8.0),
        const Text(
          'Your booking request has been sent to the vendor. You can view your booking status in the Bookings tab.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16.0),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6A3DE8),
            foregroundColor: Colors.white,
          ),
          child: const Text('View My Bookings'),
        ),
      ],
    );
  }
}
EOL

# Create bookings screen
cat > lib/screens/bookings_screen.dart << 'EOL'
import 'package:flutter/material.dart';
import 'package:eventora_mobile/models/booking.dart';
import 'package:eventora_mobile/services/api_service.dart';
import 'package:intl/intl.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> with SingleTickerProviderStateMixin {
  List<Booking> _bookings = [];
  bool _isLoading = true;
  late TabController _tabController;
  List<String> _tabs = ['Upcoming', 'Past', 'Pending'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final bookings = await ApiService.getBookings();
      setState(() {
        _bookings = bookings;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading bookings: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Booking> _getFilteredBookings() {
    final now = DateTime.now();
    switch (_tabController.index) {
      case 0: // Upcoming
        return _bookings
            .where((booking) =>
                booking.eventDate.isAfter(now) &&
                booking.status != 'cancelled' &&
                booking.status != 'pending')
            .toList();
      case 1: // Past
        return _bookings
            .where((booking) =>
                booking.eventDate.isBefore(now) ||
                booking.status == 'completed' ||
                booking.status == 'cancelled')
            .toList();
      case 2: // Pending
        return _bookings
            .where((booking) => booking.status == 'pending')
            .toList();
      default:
        return _bookings;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
          labelColor: const Color(0xFF6A3DE8),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF6A3DE8),
          onTap: (_) {
            setState(() {});
          },
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadBookings,
                  child: _buildBookingsList(),
                ),
        ),
      ],
    );
  }

  Widget _buildBookingsList() {
    final filteredBookings = _getFilteredBookings();
    
    if (filteredBookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.calendar_today, size: 60, color: Colors.grey),
            const SizedBox(height: 16.0),
            Text(
              'No ${_tabs[_tabController.index].toLowerCase()} bookings',
              style: const TextStyle(
                fontSize: 18.0,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: filteredBookings.length,
      itemBuilder: (context, index) {
        final booking = filteredBookings[index];
        return _buildBookingCard(booking);
      },
    );
  }

  Widget _buildBookingCard(Booking booking) {
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

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: () {
          // View booking details
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              color: const Color(0xFF6A3DE8).withOpacity(0.1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    booking.vendorName ?? 'Unknown Vendor',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: Text(
                      booking.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12.0,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.event, size: 16, color: Colors.grey),
                      const SizedBox(width: 8.0),
                      Text(DateFormat('MMM d, yyyy').format(booking.eventDate)),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  Row(
                    children: [
                      const Icon(Icons.category, size: 16, color: Colors.grey),
                      const SizedBox(width: 8.0),
                      Text(
                        booking.eventType.toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  Row(
                    children: [
                      const Icon(Icons.people, size: 16, color: Colors.grey),
                      const SizedBox(width: 8.0),
                      Text('${booking.guestCount} guests'),
                    ],
                  ),
                  if (booking.serviceName != null) ...[
                    const SizedBox(height: 8.0),
                    Row(
                      children: [
                        const Icon(Icons.room_service, size: 16, color: Colors.grey),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: Text(
                            booking.serviceName!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${booking.totalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6A3DE8),
                          fontSize: 18.0,
                        ),
                      ),
                      if (booking.status == 'pending')
                        TextButton(
                          onPressed: () {
                            // Cancel booking
                          },
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
EOL

# Create messages screen
cat > lib/screens/messages_screen.dart << 'EOL'
import 'package:flutter/material.dart';
import 'package:eventora_mobile/models/message.dart';
import 'package:eventora_mobile/models/user.dart';
import 'package:eventora_mobile/services/api_service.dart';
import 'package:eventora_mobile/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  List<Message> _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final conversations = await ApiService.getConversations();
      setState(() {
        _conversations = conversations;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading conversations: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadConversations,
            child: _conversations.isEmpty
                ? _buildEmptyState()
                : _buildConversationsList(),
          );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.message, size: 60, color: Colors.grey),
          const SizedBox(height: 16.0),
          const Text(
            'No conversations yet',
            style: TextStyle(
              fontSize: 18.0,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8.0),
          const Text(
            'Start a conversation with a vendor',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16.0),
          ElevatedButton(
            onPressed: () {
              // Navigate to vendors
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6A3DE8),
              foregroundColor: Colors.white,
            ),
            child: const Text('Browse Vendors'),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationsList() {
    return ListView.builder(
      itemCount: _conversations.length,
      itemBuilder: (context, index) {
        final message = _conversations[index];
        final authService = Provider.of<AuthService>(context);
        final currentUserId = authService.user?.id ?? 1;
        
        // Determine if the user is the sender or receiver
        final otherUserId = message.senderId == currentUserId
            ? message.receiverId
            : message.senderId;
        
        final isUserSender = message.senderId == currentUserId;
        
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: const Color(0xFF6A3DE8),
            child: Text(
              (isUserSender ? 'Me' : message.senderName ?? 'User')[0].toUpperCase(),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          title: Text(isUserSender
              ? 'To: ${message.senderName ?? 'User $otherUserId'}'
              : message.senderName ?? 'User $otherUserId'),
          subtitle: Text(
            message.content,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                DateFormat('MMM d').format(message.timestamp),
                style: const TextStyle(fontSize: 12.0),
              ),
              const SizedBox(height: 4.0),
              Text(
                DateFormat('h:mm a').format(message.timestamp),
                style: TextStyle(
                  fontSize: 10.0,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(userId: otherUserId),
              ),
            );
          },
        );
      },
    );
  }
}

class ChatScreen extends StatefulWidget {
  final int userId;

  const ChatScreen({super.key, required this.userId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<Message> _messages = [];
  bool _isLoading = true;
  final _textController = TextEditingController();
  User? _user;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _loadUserDetails();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final messages = await ApiService.getMessages(widget.userId);
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading messages: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUserDetails() async {
    try {
      final user = await ApiService.getUserDetails(widget.userId);
      setState(() {
        _user = user;
      });
    } catch (e) {
      print('Error loading user details: $e');
    }
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUserId = authService.user?.id ?? 1;

    try {
      final messageData = {
        'senderId': currentUserId,
        'receiverId': widget.userId,
        'content': text,
      };

      _textController.clear();

      // Optimistically add message to UI
      final tempMessage = Message(
        id: -1, // temporary ID
        senderId: currentUserId,
        receiverId: widget.userId,
        content: text,
        timestamp: DateTime.now(),
        isRead: false,
        senderName: 'You',
      );

      setState(() {
        _messages.add(tempMessage);
      });

      // Send message
      await ApiService.sendMessage(messageData);
      
      // Reload messages to get the actual message with server ID
      _loadMessages();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending message: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_user?.name ?? 'Chat'),
        backgroundColor: const Color(0xFF6A3DE8),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? _buildEmptyChat()
                    : _buildMessageList(),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildEmptyChat() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.chat, size: 60, color: Colors.grey),
          const SizedBox(height: 16.0),
          const Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 18.0,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            'Start a conversation with ${_user?.name ?? 'this user'}',
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    final authService = Provider.of<AuthService>(context);
    final currentUserId = authService.user?.id ?? 1;
    
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _messages.length,
      reverse: false,
      itemBuilder: (context, index) {
        final message = _messages[index];
        final isMe = message.senderId == currentUserId;
        
        return _buildMessageBubble(message, isMe);
      },
    );
  }

  Widget _buildMessageBubble(Message message, bool isMe) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe)
            CircleAvatar(
              backgroundColor: Colors.grey[300],
              child: Text(
                (_user?.name ?? 'User')[0].toUpperCase(),
                style: const TextStyle(color: Colors.black87),
              ),
            ),
          const SizedBox(width: 8.0),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFF6A3DE8) : Colors.grey[200],
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    DateFormat('h:mm a').format(message.timestamp),
                    style: TextStyle(
                      fontSize: 10.0,
                      color: isMe ? Colors.white70 : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8.0),
          if (isMe)
            CircleAvatar(
              backgroundColor: const Color(0xFF6A3DE8),
              child: const Text(
                'Me',
                style: TextStyle(color: Colors.white, fontSize: 10.0),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 4.0,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(24.0)),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Color(0xFFEEEEEE),
                contentPadding: EdgeInsets.symmetric(horizontal: 16.0),
              ),
            ),
          ),
          const SizedBox(width: 8.0),
          CircleAvatar(
            backgroundColor: const Color(0xFF6A3DE8),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}
EOL

# Create profile screen
cat > lib/screens/profile_screen.dart << 'EOL'
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eventora_mobile/services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  String _selectedLanguage = 'English';
  List<String> _languages = ['English', 'Arabic', 'French', 'Spanish'];

  @override
  void initState() {
    super.initState();
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.user;
    
    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  void _saveProfile() {
    // In a real app, save profile changes here
    setState(() {
      _isEditing = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated successfully')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.user;
    final isOfflineMode = authService.offlineMode;
    
    if (user == null) {
      return const Center(child: Text('Not logged in'));
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileHeader(user.name),
          const SizedBox(height: 24.0),
          _buildProfileInfo(),
          const SizedBox(height: 24.0),
          _buildSettings(isOfflineMode),
          const SizedBox(height: 24.0),
          _buildLogoutButton(),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(String name) {
    return Center(
      child: Column(
        children: [
          const CircleAvatar(
            radius: 50,
            backgroundColor: Color(0xFF6A3DE8),
            child: Icon(
              Icons.person,
              size: 50,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16.0),
          Text(
            name,
            style: const TextStyle(
              fontSize: 24.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfo() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Personal Information',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(_isEditing ? Icons.save : Icons.edit),
                  onPressed: _isEditing ? _saveProfile : _toggleEdit,
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8.0),
            _buildProfileField(
              label: 'Name',
              value: _nameController.text,
              controller: _nameController,
            ),
            const SizedBox(height: 16.0),
            _buildProfileField(
              label: 'Email',
              value: _emailController.text,
              controller: _emailController,
              enabled: false, // Email cannot be edited
            ),
            const SizedBox(height: 16.0),
            _buildProfileField(
              label: 'Phone',
              value: _phoneController.text,
              controller: _phoneController,
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileField({
    required String label,
    required String value,
    required TextEditingController controller,
    TextInputType? keyboardType,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14.0,
          ),
        ),
        const SizedBox(height: 4.0),
        _isEditing && enabled
            ? TextField(
                controller: controller,
                keyboardType: keyboardType,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 8.0,
                  ),
                ),
              )
            : Text(
                value,
                style: const TextStyle(
                  fontSize: 16.0,
                ),
              ),
      ],
    );
  }

  Widget _buildSettings(bool isOfflineMode) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Settings',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            const SizedBox(height: 8.0),
            _buildOfflineModeToggle(isOfflineMode),
            const SizedBox(height: 16.0),
            _buildLanguageSelector(),
            const SizedBox(height: 16.0),
            _buildNotificationSettings(),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineModeToggle(bool isOfflineMode) {
    final authService = Provider.of<AuthService>(context);
    
    return SwitchListTile(
      title: const Text('Offline Mode'),
      subtitle: const Text('Use app without internet connection'),
      value: isOfflineMode,
      activeColor: const Color(0xFF6A3DE8),
      onChanged: (value) {
        authService.setOfflineMode(value);
      },
    );
  }

  Widget _buildLanguageSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Language'),
        const SizedBox(height: 8.0),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 8.0,
            ),
          ),
          value: _selectedLanguage,
          items: _languages.map((language) {
            return DropdownMenuItem<String>(
              value: language,
              child: Text(language),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedLanguage = value;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildNotificationSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Notifications'),
        const SizedBox(height: 8.0),
        SwitchListTile(
          title: const Text('Booking Updates'),
          subtitle: const Text('Receive updates about your bookings'),
          value: true,
          activeColor: const Color(0xFF6A3DE8),
          contentPadding: EdgeInsets.zero,
          onChanged: (value) {
            // Toggle notification setting
          },
        ),
        SwitchListTile(
          title: const Text('Messages'),
          subtitle: const Text('Receive notifications about new messages'),
          value: true,
          activeColor: const Color(0xFF6A3DE8),
          contentPadding: EdgeInsets.zero,
          onChanged: (value) {
            // Toggle notification setting
          },
        ),
        SwitchListTile(
          title: const Text('Promotions'),
          subtitle: const Text('Receive promotional offers and news'),
          value: false,
          activeColor: const Color(0xFF6A3DE8),
          contentPadding: EdgeInsets.zero,
          onChanged: (value) {
            // Toggle notification setting
          },
        ),
      ],
    );
  }

  Widget _buildLogoutButton() {
    final authService = Provider.of<AuthService>(context);
    
    return ElevatedButton(
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  authService.logout();
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: const Text('Logout'),
              ),
            ],
          ),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 48),
      ),
      child: const Text('Logout'),
    );
  }
}
EOL

# Create login screen
cat > lib/screens/login_screen.dart << 'EOL'
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eventora_mobile/services/auth_service.dart';
import 'package:eventora_mobile/screens/app_wrapper.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final authService = Provider.of<AuthService>(context, listen: false);
    
    try {
      bool success;
      if (_isLogin) {
        success = await authService.login(
          _emailController.text,
          _passwordController.text,
        );
      } else {
        success = await authService.register(
          _nameController.text,
          _emailController.text,
          _passwordController.text,
        );
      }

      if (success) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AppWrapper())
        );
      } else {
        setState(() {
          _isLoading = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(authService.errorMessage ?? 'Authentication failed')),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _toggleAuthMode() {
    setState(() {
      _isLogin = !_isLogin;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/daoob-logo.jpg',
                    width: 120,
                    height: 120,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _isLogin ? 'Welcome Back' : 'Create Account',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isLogin ? 'Sign in to continue' : 'Sign up to get started',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 32),
                  if (!_isLogin) ...[
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (!_isLogin && value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6A3DE8),
                        foregroundColor: Colors.white,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            )
                          : Text(_isLogin ? 'Login' : 'Sign Up'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_isLogin
                          ? 'Don\'t have an account?'
                          : 'Already have an account?'),
                      TextButton(
                        onPressed: _toggleAuthMode,
                        child: Text(_isLogin ? 'Sign Up' : 'Login'),
                      ),
                    ],
                  ),
                  if (_isLogin)
                    TextButton(
                      onPressed: () {
                        // Forgot password functionality
                      },
                      child: const Text('Forgot Password?'),
                    ),
                  const SizedBox(height: 24),
                  _buildOfflineModeButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOfflineModeButton() {
    final authService = Provider.of<AuthService>(context);
    
    return TextButton.icon(
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Offline Mode'),
            content: const Text(
              'In offline mode, you can use the app without internet connection. '
              'This is for demonstration purposes only.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  authService.setOfflineMode(true);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const AppWrapper()),
                  );
                },
                child: const Text('Continue Offline'),
              ),
            ],
          ),
        );
      },
      icon: const Icon(Icons.offline_bolt),
      label: const Text('Continue in Offline Mode'),
    );
  }
}
EOL

# Update the App Wrapper
cat > lib/screens/app_wrapper.dart << 'EOL'
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eventora_mobile/services/auth_service.dart';
import 'package:eventora_mobile/screens/vendor_listing_screen.dart';
import 'package:eventora_mobile/screens/bookings_screen.dart';
import 'package:eventora_mobile/screens/messages_screen.dart';
import 'package:eventora_mobile/screens/profile_screen.dart';

class AppWrapper extends StatefulWidget {
  const AppWrapper({super.key});

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> {
  int _currentIndex = 0;
  final List<String> _titles = ['Vendors', 'Bookings', 'Messages', 'Profile'];
  final List<Widget> _screens = [
    const VendorListingScreen(),
    const BookingsScreen(),
    const MessagesScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        backgroundColor: const Color(0xFF6A3DE8),
        foregroundColor: Colors.white,
        actions: [
          if (_currentIndex == 0)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                // Show search
              },
            ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF6A3DE8),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.store),
            label: 'Vendors',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Bookings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
EOL

# Create splash screen
cat > lib/screens/splash_screen.dart << 'EOL'
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eventora_mobile/services/auth_service.dart';
import 'package:eventora_mobile/screens/login_screen.dart';
import 'package:eventora_mobile/screens/app_wrapper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.initialize();
    
    // Short delay to show the splash screen
    await Future.delayed(const Duration(seconds: 2));
    
    if (authService.isAuthenticated) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AppWrapper()),
        );
      }
    } else {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF6A3DE8), Color(0xFF8F6FF2)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(75),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(75),
                  child: Image.asset(
                    'assets/images/daoob-logo.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              // App name
              const Text(
                'DAOOB',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Event Management Platform',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 50),
              // Loading indicator
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              const SizedBox(height: 20),
              // Toggle for offline mode (development only)
              Consumer<AuthService>(
                builder: (context, authService, _) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Offline Mode',
                        style: TextStyle(color: Colors.white),
                      ),
                      Switch(
                        value: authService.offlineMode,
                        onChanged: (value) {
                          authService.setOfflineMode(value);
                        },
                        activeColor: Colors.white,
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
EOL

# Create main.dart to connect everything
cat > lib/main.dart << 'EOL'
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:eventora_mobile/services/auth_service.dart';
import 'package:eventora_mobile/screens/splash_screen.dart';
import 'package:eventora_mobile/screens/login_screen.dart';
import 'package:eventora_mobile/screens/app_wrapper.dart';
import 'package:eventora_mobile/screens/vendor_detail_screen.dart';
import 'package:eventora_mobile/l10n/app_localizations.dart';
import 'package:eventora_mobile/l10n/language_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AuthService(),
      child: MaterialApp(
        title: 'DAOOB',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6A3DE8)),
          useMaterial3: true,
          primaryColor: const Color(0xFF6A3DE8),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF6A3DE8),
            foregroundColor: Colors.white,
          ),
        ),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en'),
          Locale('ar'),
        ],
        initialRoute: '/',
        onGenerateRoute: (settings) {
          if (settings.name == '/vendor-details') {
            final vendorId = settings.arguments as int;
            return MaterialPageRoute(
              builder: (context) => VendorDetailScreen(vendorId: vendorId),
            );
          }
          return null;
        },
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/home': (context) => const AppWrapper(),
        },
      ),
    );
  }
}
EOL

# Create pubspec.yaml file
cat > pubspec.yaml << 'EOL'
name: eventora_mobile
description: "DAOOB Event Management Platform"
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  cupertino_icons: ^1.0.2
  shared_preferences: ^2.2.0
  http: ^1.1.0
  intl: ^0.19.0
  provider: ^6.0.5
  flutter_launcher_icons: ^0.13.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^2.0.0

flutter:
  uses-material-design: true
  assets:
    - assets/images/
    - assets/lang/

flutter_icons:
  android: true
  ios: true
  image_path: "assets/images/daoob-logo.jpg"
  adaptive_icon_background: "#6A3DE8"
EOL

# Add localization files
mkdir -p assets/lang
cat > assets/lang/ar.json << 'EOL'
{
  "app_name": "دعوب",
  "welcome": "مرحبا بك في دعوب",
  "login": "تسجيل الدخول",
  "email": "البريد الإلكتروني",
  "password": "كلمة المرور",
  "forgot_password": "نسيت كلمة المرور؟",
  "home": "الرئيسية",
  "bookings": "الحجوزات",
  "messages": "الرسائل",
  "profile": "الملف الشخصي",
  "settings": "الإعدادات",
  "language": "اللغة",
  "offline_mode": "الوضع دون اتصال",
  "logout": "تسجيل الخروج"
}
EOL

# Add EN locale file
cat > assets/lang/en.json << 'EOL'
{
  "app_name": "DAOOB",
  "welcome": "Welcome to DAOOB",
  "login": "Login",
  "email": "Email",
  "password": "Password",
  "forgot_password": "Forgot Password?",
  "home": "Home",
  "bookings": "Bookings",
  "messages": "Messages",
  "profile": "Profile",
  "settings": "Settings",
  "language": "Language",
  "offline_mode": "Offline Mode",
  "logout": "Logout"
}
EOL

# Fix Android NDK version in build.gradle files
if [ -f "android/app/build.gradle" ]; then
  if ! grep -q "ndkVersion" android/app/build.gradle; then
    sed -i '/defaultConfig {/a \        ndkVersion "27.0.12077973"' android/app/build.gradle
    echo "Added ndkVersion to android/app/build.gradle"
  fi
fi

if [ -f "android/app/build.gradle.kts" ]; then
  if ! grep -q "ndkVersion" android/app/build.gradle.kts; then
    sed -i '/android {/a \    ndkVersion = "27.0.12077973"' android/app/build.gradle.kts
    echo "Added ndkVersion to android/app/build.gradle.kts"
  fi
fi

# Get dependencies
echo "Getting dependencies..."
flutter pub get

# Setup app icon
echo "Setting up app icon..."
flutter pub run flutter_launcher_icons

echo "=== Building APK ==="
flutter build apk --release

echo "=== Setup complete! ==="
echo "APK has been built and is located at:"
echo "$(pwd)/build/app/outputs/flutter-apk/app-release.apk"