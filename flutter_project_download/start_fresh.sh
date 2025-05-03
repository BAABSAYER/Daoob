#!/bin/bash

echo "=== Starting a fresh build of the DAOOB Flutter app ==="

# Get the script directory (works on all Unix-like systems)
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

# Create the Flutter project from scratch with modern Gradle
echo "Creating a new Flutter project..."
flutter create --org com.daoob eventora_mobile

# Navigate to the project
cd eventora_mobile

# Create necessary directories
mkdir -p assets/images assets/lang lib/models lib/screens lib/services

# Copy the logo
echo "Setting up app logo..."
cp "../WhatsApp Image 2025-04-06 at 21.40.44_8e7cb969.jpg" assets/images/daoob-logo.jpg

# Create basic service files
echo "Creating auth service..."
cat > lib/services/auth_service.dart << 'EOL'
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class AuthService extends ChangeNotifier {
  bool _isAuthenticated = false;
  bool _isLoading = false;
  bool _offlineMode = false;
  String? _errorMessage;
  String? _token;
  Map<String, dynamic>? _userData;

  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  bool get offlineMode => _offlineMode;
  String? get errorMessage => _errorMessage;
  String? get token => _token;
  Map<String, dynamic>? get userData => _userData;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _offlineMode = prefs.getBool('offline_mode') ?? false;
    
    if (_offlineMode) {
      _isAuthenticated = true;
      _userData = {
        'id': 1,
        'name': 'Offline User',
        'email': 'offline@example.com',
        'role': 'client'
      };
      notifyListeners();
      return;
    }
    
    final storedToken = prefs.getString('auth_token');
    if (storedToken != null) {
      _token = storedToken;
      await _validateToken();
    }
  }

  Future<void> _validateToken() async {
    // In a real app, validate the token with server
    _isAuthenticated = true;
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    if (_offlineMode) {
      _isAuthenticated = true;
      _userData = {
        'id': 1,
        'name': 'Offline User',
        'email': email,
        'role': 'client'
      };
      notifyListeners();
      return true;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Simulate API call
      await Future.delayed(Duration(seconds: 2));
      _isAuthenticated = true;
      _token = 'sample_token';
      _userData = {
        'id': 1,
        'name': 'John Doe',
        'email': email,
        'role': 'client'
      };
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', _token!);
      
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

  Future<void> logout() async {
    _isAuthenticated = false;
    _token = null;
    _userData = null;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    
    notifyListeners();
  }

  Future<void> setOfflineMode(bool value) async {
    _offlineMode = value;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('offline_mode', value);
    
    if (value) {
      _isAuthenticated = true;
      _userData = {
        'id': 1,
        'name': 'Offline User',
        'email': 'offline@example.com',
        'role': 'client'
      };
    } else {
      // Revert to online state
      _isAuthenticated = false;
      _userData = null;
      initialize();
    }
    
    notifyListeners();
  }
}
EOL

echo "Creating API service..."
cat > lib/services/api_service.dart << 'EOL'
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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

  static Future<Map<String, dynamic>> get({required String endpoint}) async {
    if (await isOfflineMode()) {
      return getMockData(endpoint);
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<Map<String, dynamic>> post({
    required String endpoint,
    required Map<String, dynamic> data,
  }) async {
    if (await isOfflineMode()) {
      return postMockData(endpoint, data);
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode(data),
      );
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to post data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Mock data for offline mode
  static Future<Map<String, dynamic>> getMockData(String endpoint) async {
    await Future.delayed(Duration(milliseconds: 500)); // Simulate network delay
    
    if (endpoint.startsWith('/api/user')) {
      return {
        'id': 1,
        'name': 'Offline User',
        'email': 'offline@example.com',
        'role': 'client'
      };
    }
    
    // Default fallback
    return {'message': 'Offline mode active', 'data': []};
  }

  static Future<Map<String, dynamic>> postMockData(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    await Future.delayed(Duration(milliseconds: 800)); // Simulate network delay
    
    if (endpoint == '/api/login') {
      return {
        'id': 1,
        'name': 'Offline User',
        'email': data['email'] ?? 'offline@example.com',
        'role': 'client',
        'token': 'mock_token_12345'
      };
    }
    
    // Default fallback
    return {'message': 'Data saved in offline mode', 'success': true};
  }
}
EOL

# Create a basic splash screen
echo "Creating splash screen..."
cat > lib/screens/splash_screen.dart << 'EOL'
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eventora_mobile/services/auth_service.dart';
import 'package:eventora_mobile/screens/app_wrapper.dart';
import 'package:eventora_mobile/screens/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _offlineMode = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.initialize();
    
    Future.delayed(const Duration(seconds: 2), () {
      if (authService.isAuthenticated) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AppWrapper())
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen())
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/daoob-logo.jpg',
              width: 150,
              height: 150,
            ),
            const SizedBox(height: 30),
            const Text(
              'DAOOB',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6A3DE8),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Event Management Platform',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 50),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6A3DE8)),
            ),
            const SizedBox(height: 50),
            // Development mode toggle for offline/online
            SwitchListTile(
              title: const Text('Offline Mode (Development)'),
              value: _offlineMode,
              onChanged: (value) {
                setState(() {
                  _offlineMode = value;
                });
                authService.setOfflineMode(value);
              },
            ),
          ],
        ),
      ),
    );
  }
}
EOL

# Create login screen
echo "Creating login screen..."
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
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final authService = Provider.of<AuthService>(context, listen: false);
    final success = await authService.login(
      _emailController.text,
      _passwordController.text,
    );

    if (success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AppWrapper())
      );
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(authService.errorMessage ?? 'Login failed'))
        );
      }
    }
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
                  const Text(
                    'Welcome Back',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sign in to continue',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 32),
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
                          : const Text('Login'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      // Add forgot password functionality
                    },
                    child: const Text('Forgot Password?'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
EOL

# Create app wrapper
echo "Creating app wrapper..."
cat > lib/screens/app_wrapper.dart << 'EOL'
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eventora_mobile/services/auth_service.dart';

class AppWrapper extends StatefulWidget {
  const AppWrapper({super.key});

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> {
  int _currentIndex = 0;
  final List<String> _titles = ['Home', 'Bookings', 'Messages', 'Profile'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        backgroundColor: const Color(0xFF6A3DE8),
        foregroundColor: Colors.white,
        actions: [
          if (_titles[_currentIndex] == 'Profile')
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                _showLogoutDialog();
              },
            ),
        ],
      ),
      body: _buildBody(),
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
            icon: Icon(Icons.home),
            label: 'Home',
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

  Widget _buildBody() {
    final authService = Provider.of<AuthService>(context);
    final isOffline = authService.offlineMode;
    
    switch (_currentIndex) {
      case 0:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/daoob-logo.jpg',
                width: 100,
                height: 100,
              ),
              const SizedBox(height: 20),
              const Text(
                'Welcome to DAOOB',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                isOffline ? 'App running in OFFLINE mode' : 'App running in ONLINE mode',
                style: TextStyle(
                  fontSize: 16,
                  color: isOffline ? Colors.orange : Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'Find and book the perfect venue and services for your event',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        );
      case 1:
        return const Center(child: Text('Bookings coming soon'));
      case 2:
        return const Center(child: Text('Messages coming soon'));
      case 3:
        return _buildProfileScreen();
      default:
        return const Center(child: Text('Page not found'));
    }
  }

  Widget _buildProfileScreen() {
    final authService = Provider.of<AuthService>(context);
    final userData = authService.userData;
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Color(0xFF6A3DE8),
              child: Icon(
                Icons.person,
                size: 50,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Personal Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text('Name'),
                    subtitle: Text(userData?['name'] ?? 'Not available'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.email),
                    title: const Text('Email'),
                    subtitle: Text(userData?['email'] ?? 'Not available'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.badge),
                    title: const Text('Role'),
                    subtitle: Text(userData?['role'] ?? 'Not available'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('Offline Mode'),
                    subtitle: const Text('Use app without internet connection'),
                    value: authService.offlineMode,
                    onChanged: (value) {
                      authService.setOfflineMode(value);
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.language),
                    title: const Text('Language'),
                    subtitle: const Text('English'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // Open language selection
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Provider.of<AuthService>(context, listen: false).logout();
              Navigator.of(context).pushReplacementNamed('/login');
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
EOL

# Create main.dart file
echo "Creating main.dart..."
cat > lib/main.dart << 'EOL'
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:eventora_mobile/services/auth_service.dart';
import 'package:eventora_mobile/screens/splash_screen.dart';
import 'package:eventora_mobile/screens/login_screen.dart';
import 'package:eventora_mobile/screens/app_wrapper.dart';

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

# Create a better pubspec.yaml file
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

# Add AR locale file
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

# Fix Android NDK version in build.gradle
if [ -f "android/app/build.gradle" ]; then
  if ! grep -q "ndkVersion" android/app/build.gradle; then
    sed -i '/defaultConfig {/a \        ndkVersion "27.0.12077973"' android/app/build.gradle
    echo "Added ndkVersion to android/app/build.gradle"
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