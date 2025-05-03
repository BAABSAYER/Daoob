#!/bin/bash

cd eventora_app

# Create service files
mkdir -p lib/services

# Create API service
cat > lib/services/api_service.dart << 'EOF'
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  bool _isOfflineMode = false;
  String _baseUrl = '';
  Map<String, String> _headers = {
    'Content-Type': 'application/json',
  };

  bool get isOfflineMode => _isOfflineMode;
  
  Future<void> init() async {
    // Get offline mode setting from shared preferences
    final prefs = await SharedPreferences.getInstance();
    _isOfflineMode = prefs.getBool('offlineMode') ?? false;
    
    // Determine base URL based on platform
    if (!_isOfflineMode) {
      if (Platform.isAndroid) {
        // Android emulator needs 10.0.2.2 to connect to host
        _baseUrl = 'http://10.0.2.2:5000';
      } else if (Platform.isIOS) {
        // iOS simulator can use localhost
        _baseUrl = 'http://localhost:5000';
      } else {
        // Web or other platforms
        _baseUrl = 'http://localhost:5000';
      }
    }

    debugPrint('ApiService initialized with offline mode: $_isOfflineMode, baseUrl: $_baseUrl');
  }

  Future<void> setOfflineMode(bool value) async {
    _isOfflineMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('offlineMode', value);
    debugPrint('Offline mode set to: $value');
  }

  Future<dynamic> get(String endpoint) async {
    if (_isOfflineMode) {
      return await _getMockData(endpoint);
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl$endpoint'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));

      return _handleResponse(response);
    } catch (e) {
      debugPrint('API GET Error: $e');
      throw Exception('Failed to load data: $e');
    }
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    if (_isOfflineMode) {
      return await _postMockData(endpoint, data);
    }

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl$endpoint'),
        headers: _headers,
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 10));

      return _handleResponse(response);
    } catch (e) {
      debugPrint('API POST Error: $e');
      throw Exception('Failed to send data: $e');
    }
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    if (_isOfflineMode) {
      return await _putMockData(endpoint, data);
    }

    try {
      final response = await http.put(
        Uri.parse('$_baseUrl$endpoint'),
        headers: _headers,
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 10));

      return _handleResponse(response);
    } catch (e) {
      debugPrint('API PUT Error: $e');
      throw Exception('Failed to update data: $e');
    }
  }

  Future<dynamic> delete(String endpoint) async {
    if (_isOfflineMode) {
      return await _deleteMockData(endpoint);
    }

    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl$endpoint'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));

      return _handleResponse(response);
    } catch (e) {
      debugPrint('API DELETE Error: $e');
      throw Exception('Failed to delete data: $e');
    }
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      // Update cookies from response
      _updateCookies(response);
      
      if (response.body.isNotEmpty) {
        return jsonDecode(response.body);
      }
      return {};
    } else {
      final message = response.body.isNotEmpty 
          ? response.body
          : 'Server error: ${response.statusCode}';
      throw Exception(message);
    }
  }

  void _updateCookies(http.Response response) {
    final cookies = response.headers['set-cookie'];
    if (cookies != null) {
      _headers['Cookie'] = cookies;
    }
  }

  // Mock data methods for offline mode
  Future<dynamic> _getMockData(String endpoint) async {
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay
    
    if (endpoint == '/api/user') {
      return {
        'id': 1,
        'username': 'demouser',
        'email': 'demo@example.com',
        'fullName': 'Demo User',
        'userType': 'client',
        'phone': '123-456-7890',
        'createdAt': DateTime.now().toIso8601String(),
      };
    } else if (endpoint.startsWith('/api/vendors')) {
      return _getMockVendors();
    } else if (endpoint.startsWith('/api/bookings')) {
      return _getMockBookings();
    } else if (endpoint.startsWith('/api/services')) {
      return _getMockServices();
    }
    
    return {};
  }

  Future<dynamic> _postMockData(String endpoint, Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay
    
    if (endpoint == '/api/login') {
      if (data['username'] == 'demouser' && data['password'] == 'password') {
        return {
          'id': 1,
          'username': 'demouser',
          'email': 'demo@example.com',
          'fullName': 'Demo User',
          'userType': 'client',
          'phone': '123-456-7890',
          'createdAt': DateTime.now().toIso8601String(),
        };
      } else if (data['username'] == 'demovendor' && data['password'] == 'password') {
        return {
          'id': 2,
          'username': 'demovendor',
          'email': 'vendor@example.com',
          'fullName': 'Demo Vendor',
          'userType': 'vendor',
          'phone': '123-456-7890',
          'createdAt': DateTime.now().toIso8601String(),
        };
      } else {
        throw Exception('Invalid credentials');
      }
    } else if (endpoint == '/api/register') {
      return {
        'id': 3,
        'username': data['username'],
        'email': data['email'],
        'fullName': data['fullName'],
        'userType': data['userType'],
        'phone': data['phone'],
        'createdAt': DateTime.now().toIso8601String(),
      };
    } else if (endpoint == '/api/bookings') {
      return {
        'id': 10,
        'clientId': data['clientId'],
        'vendorId': data['vendorId'],
        'serviceId': data['serviceId'],
        'date': data['date'],
        'status': 'pending',
        'totalPrice': data['totalPrice'],
        'notes': data['notes'],
        'createdAt': DateTime.now().toIso8601String(),
      };
    }
    
    return {};
  }

  Future<dynamic> _putMockData(String endpoint, Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay
    return data..addAll({'id': 1, 'updatedAt': DateTime.now().toIso8601String()});
  }

  Future<dynamic> _deleteMockData(String endpoint) async {
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay
    return {'success': true};
  }

  List<Map<String, dynamic>> _getMockVendors() {
    return [
      {
        'id': 1,
        'userId': 2,
        'businessName': 'Elegant Events',
        'description': 'Premier event planning and coordination services',
        'category': 'event_planner',
        'location': 'New York, NY',
        'contactEmail': 'info@elegantevents.com',
        'contactPhone': '212-555-1234',
        'website': 'https://elegantevents.com',
        'profileImage': 'https://example.com/profile1.jpg',
        'rating': 4.8,
        'verified': true,
        'createdAt': '2023-01-15T08:00:00Z',
      },
      {
        'id': 2,
        'userId': 3,
        'businessName': 'Gourmet Delights Catering',
        'description': 'Fine dining catering for all occasions',
        'category': 'catering',
        'location': 'Los Angeles, CA',
        'contactEmail': 'events@gourmetdelights.com',
        'contactPhone': '323-555-6789',
        'website': 'https://gourmetdelights.com',
        'profileImage': 'https://example.com/profile2.jpg',
        'rating': 4.7,
        'verified': true,
        'createdAt': '2023-02-20T10:30:00Z',
      },
      {
        'id': 3,
        'userId': 4,
        'businessName': 'SoundWave Entertainment',
        'description': 'Professional DJ and entertainment services',
        'category': 'entertainment',
        'location': 'Chicago, IL',
        'contactEmail': 'bookings@soundwave.com',
        'contactPhone': '312-555-9876',
        'website': 'https://soundwaveentertainment.com',
        'profileImage': 'https://example.com/profile3.jpg',
        'rating': 4.9,
        'verified': true,
        'createdAt': '2023-03-10T14:15:00Z',
      },
    ];
  }

  List<Map<String, dynamic>> _getMockServices() {
    return [
      {
        'id': 1,
        'vendorId': 1,
        'name': 'Full Event Planning Package',
        'description': 'Comprehensive event planning from concept to execution',
        'price': 2500.00,
        'duration': 8,
        'category': 'event_planner',
        'images': ['https://example.com/event1.jpg', 'https://example.com/event2.jpg'],
        'availability': ['weekday', 'weekend'],
        'createdAt': '2023-01-20T09:30:00Z',
      },
      {
        'id': 2,
        'vendorId': 2,
        'name': 'Premium Buffet Service',
        'description': 'Luxury buffet setup with a wide selection of gourmet dishes',
        'price': 75.00,
        'duration': 4,
        'category': 'catering',
        'images': ['https://example.com/buffet1.jpg', 'https://example.com/buffet2.jpg'],
        'availability': ['weekday', 'weekend'],
        'createdAt': '2023-02-25T11:45:00Z',
      },
      {
        'id': 3,
        'vendorId': 3,
        'name': 'DJ & Lighting Package',
        'description': 'Professional DJ services with premium sound and lighting setup',
        'price': 1200.00,
        'duration': 5,
        'category': 'entertainment',
        'images': ['https://example.com/dj1.jpg', 'https://example.com/dj2.jpg'],
        'availability': ['weekend'],
        'createdAt': '2023-03-15T15:20:00Z',
      },
    ];
  }

  List<Map<String, dynamic>> _getMockBookings() {
    return [
      {
        'id': 1,
        'clientId': 1,
        'vendorId': 1,
        'serviceId': 1,
        'date': '2023-06-15T18:00:00Z',
        'status': 'confirmed',
        'totalPrice': 2500.00,
        'notes': 'Wedding planning for 150 guests',
        'createdAt': '2023-04-10T10:00:00Z',
        'vendorName': 'Elegant Events',
        'serviceName': 'Full Event Planning Package',
      },
      {
        'id': 2,
        'clientId': 1,
        'vendorId': 2,
        'serviceId': 2,
        'date': '2023-06-15T18:00:00Z',
        'status': 'pending',
        'totalPrice': 11250.00,
        'notes': 'Catering for 150 guests at wedding',
        'createdAt': '2023-04-12T14:30:00Z',
        'vendorName': 'Gourmet Delights Catering',
        'serviceName': 'Premium Buffet Service',
      },
      {
        'id': 3,
        'clientId': 1,
        'vendorId': 3,
        'serviceId': 3,
        'date': '2023-06-15T20:00:00Z',
        'status': 'pending',
        'totalPrice': 1200.00,
        'notes': 'DJ services for wedding reception',
        'createdAt': '2023-04-15T16:45:00Z',
        'vendorName': 'SoundWave Entertainment',
        'serviceName': 'DJ & Lighting Package',
      },
    ];
  }
}
EOF

# Create Auth service
cat > lib/services/auth_service.dart << 'EOF'
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eventora_app/models/user.dart';
import 'package:eventora_app/services/api_service.dart';

class AuthService with ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  final ApiService _apiService = ApiService();

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _currentUser != null;
  
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _apiService.init();
      await _loadUser();
    } catch (e) {
      debugPrint('Auth init error: $e');
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login({required String username, required String password}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final response = await _apiService.post('/api/login', {
        'username': username,
        'password': password,
      });
      
      _currentUser = User.fromJson(response);
      _saveUser(_currentUser!);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Login failed: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String username,
    required String email,
    required String password,
    required String fullName,
    required String userType,
    String? phone,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final response = await _apiService.post('/api/register', {
        'username': username,
        'email': email,
        'password': password,
        'fullName': fullName,
        'userType': userType,
        'phone': phone,
      });
      
      _currentUser = User.fromJson(response);
      _saveUser(_currentUser!);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Registration failed: ${e.toString()}';
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      if (!_apiService.isOfflineMode) {
        await _apiService.post('/api/logout', {});
      }
      
      _currentUser = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user');
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Logout failed: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> getCurrentUser() async {
    if (_apiService.isOfflineMode) {
      // In offline mode, use the cached user
      await _loadUser();
      return;
    }
    
    _isLoading = true;
    notifyListeners();
    
    try {
      final response = await _apiService.get('/api/user');
      _currentUser = User.fromJson(response);
      _saveUser(_currentUser!);
    } catch (e) {
      _currentUser = null;
      debugPrint('Get current user error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setOfflineMode(bool value) async {
    await _apiService.setOfflineMode(value);
    
    if (value && _currentUser == null) {
      // If switching to offline mode and no user is logged in,
      // create a demo user account
      _currentUser = User(
        id: 1,
        username: 'demouser',
        email: 'demo@example.com',
        fullName: 'Demo User',
        userType: 'client',
        createdAt: DateTime.now(),
      );
      _saveUser(_currentUser!);
    } else if (!value) {
      // If switching to online mode, clear the user if it was a demo account
      await getCurrentUser();
    }
    
    notifyListeners();
  }

  Future<void> _saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', jsonEncode(user.toJson()));
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user');
    
    if (userData != null) {
      try {
        _currentUser = User.fromJson(jsonDecode(userData));
      } catch (e) {
        debugPrint('Error parsing user data: $e');
        await prefs.remove('user');
        _currentUser = null;
      }
    } else if (_apiService.isOfflineMode) {
      // Create a demo user for offline mode
      _currentUser = User(
        id: 1,
        username: 'demouser',
        email: 'demo@example.com',
        fullName: 'Demo User',
        userType: 'client',
        createdAt: DateTime.now(),
      );
      _saveUser(_currentUser!);
    }
  }

  Future<void> updateProfile({
    required String fullName,
    required String email,
    String? phone,
  }) async {
    if (_currentUser == null) return;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      final response = await _apiService.put('/api/user/${_currentUser!.id}', {
        'fullName': fullName,
        'email': email,
        'phone': phone,
      });
      
      _currentUser = User.fromJson(response);
      _saveUser(_currentUser!);
    } catch (e) {
      _errorMessage = 'Update profile failed: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
EOF

# Create splash screen with offline toggle
cat > lib/screens/splash_screen.dart << 'EOF'
import 'package:flutter/material.dart';
import 'package:eventora_app/config/theme.dart';
import 'package:eventora_app/services/auth_service.dart';
import 'package:eventora_app/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onInitComplete;
  
  const SplashScreen({
    Key? key,
    required this.onInitComplete,
  }) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  bool _isOfflineMode = false;
  bool _isInitialized = false;
  String _statusMessage = 'Initializing...';
  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();
  
  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    
    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );
    
    _animationController.forward();
    _loadOfflineMode();
    _initialize();
  }
  
  Future<void> _loadOfflineMode() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isOfflineMode = prefs.getBool('offlineMode') ?? false;
    });
  }
  
  Future<void> _initialize() async {
    try {
      setState(() {
        _statusMessage = 'Initializing services...';
      });
      
      await _apiService.init();
      await _authService.init();
      
      setState(() {
        _statusMessage = _isOfflineMode
            ? 'Ready (Offline Mode)'
            : 'Connected to server';
        _isInitialized = true;
      });
      
      // Wait a moment to show the ready message
      await Future.delayed(const Duration(seconds: 1));
      widget.onInitComplete();
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: ${e.toString()}';
      });
    }
  }
  
  Future<void> _toggleOfflineMode(bool value) async {
    setState(() {
      _isOfflineMode = value;
      _isInitialized = false;
      _statusMessage = 'Switching mode...';
    });
    
    try {
      await _apiService.setOfflineMode(value);
      await _authService.setOfflineMode(value);
      
      setState(() {
        _statusMessage = value
            ? 'Ready (Offline Mode)'
            : 'Connected to server';
        _isInitialized = true;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: ${e.toString()}';
      });
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeInAnimation.value,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'D',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 72,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 32),
                    
                    // App name
                    Text(
                      'DAOOB',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                      ),
                    ),
                    
                    Text(
                      'Event Management Platform',
                      style: TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 16,
                      ),
                    ),
                    
                    SizedBox(height: 64),
                    
                    // Status message
                    Text(
                      _statusMessage,
                      style: TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 14,
                      ),
                    ),
                    
                    SizedBox(height: 16),
                    
                    // Loading indicator
                    if (!_isInitialized)
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.primaryColor,
                        ),
                      ),
                    
                    SizedBox(height: 32),
                    
                    // Offline mode toggle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Offline Mode',
                          style: TextStyle(
                            color: AppTheme.textPrimaryColor,
                            fontSize: 16,
                          ),
                        ),
                        
                        SizedBox(width: 16),
                        
                        Switch(
                          value: _isOfflineMode,
                          onChanged: _toggleOfflineMode,
                          activeColor: AppTheme.primaryColor,
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
EOF

# Add shared_preferences to pubspec.yaml and http package
cat >> lib/pubspec.yaml << 'EOL'

# Add dependencies for API and offline functionality
dependencies:
  shared_preferences: ^2.2.0
  http: ^1.1.0
EOL

echo "Service files created successfully."