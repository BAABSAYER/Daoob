#!/bin/bash

# Navigate to the Flutter project directory
cd ./eventora_mobile || exit

# Fix the login method in auth_service.dart to use named parameters
cat > lib/services/auth_service.dart << 'EOL'
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:eventora_app/models/user.dart';
import 'package:eventora_app/services/api_service.dart';

class AuthService extends ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  User? _currentUser;
  bool _isLoggedIn = false;
  bool _isLoading = false;
  bool _isOfflineMode = false;

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  bool get isOfflineMode => _isOfflineMode;

  void setOfflineMode(bool value) {
    _isOfflineMode = value;
    notifyListeners();
  }

  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    // If offline mode is enabled, use demo data
    if (_isOfflineMode) {
      await _setupOfflineUser();
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      // Check if we have a session cookie
      final cookie = await _storage.read(key: 'session_cookie');
      
      if (cookie == null) {
        _isLoggedIn = false;
        _currentUser = null;
      } else {
        try {
          // Use ApiService which will handle cookies automatically
          final userData = await ApiService.get('/api/user');
          _currentUser = User.fromJson(userData);
          _isLoggedIn = true;
        } catch (e) {
          // Session is invalid or expired
          await _storage.delete(key: 'session_cookie');
          _isLoggedIn = false;
          _currentUser = null;
        }
      }
    } catch (e) {
      debugPrint('Error checking auth status: $e');
      _isLoggedIn = false;
      _currentUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Changed to use named parameters
  Future<bool> login({required String username, required String password}) async {
    _isLoading = true;
    notifyListeners();

    // If offline mode is enabled, use demo data
    if (_isOfflineMode) {
      await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay
      await _setupOfflineUser();
      _isLoading = false;
      notifyListeners();
      return true;
    }

    try {
      // Use ApiService for login which will handle cookies automatically
      final userData = await ApiService.post('/api/login', {
        'username': username,
        'password': password,
      });
      
      _currentUser = User.fromJson(userData);
      _isLoggedIn = true;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Login error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String username,
    required String password,
    required String email,
    required String fullName,
  }) async {
    _isLoading = true;
    notifyListeners();

    // If offline mode is enabled, use demo data
    if (_isOfflineMode) {
      await Future.delayed(const Duration(milliseconds: 800)); // Simulate network delay
      await _setupOfflineUser();
      _isLoading = false;
      notifyListeners();
      return true;
    }

    try {
      // Use ApiService for registration which will handle cookies automatically
      final userData = await ApiService.post('/api/register', {
        'username': username,
        'password': password,
        'email': email,
        'fullName': fullName,
        'userType': 'client', // Default user type for mobile app users
      });
      
      _currentUser = User.fromJson(userData);
      _isLoggedIn = true;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Registration error: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    // If offline mode is enabled, just clear local state
    if (_isOfflineMode) {
      await Future.delayed(const Duration(milliseconds: 300)); // Simulate network delay
      _isLoggedIn = false;
      _currentUser = null;
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      // Use ApiService for logout which will handle cookies automatically
      await ApiService.post('/api/logout', {});
      await _storage.delete(key: 'session_cookie');
      _isLoggedIn = false;
      _currentUser = null;
    } catch (e) {
      debugPrint('Logout error: $e');
      // Even if the server call fails, clear local storage
      await _storage.delete(key: 'session_cookie');
      _isLoggedIn = false;
      _currentUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    notifyListeners();

    try {
      // In a real app, this would call a password reset API endpoint
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Helper method to setup offline demo user
  Future<void> _setupOfflineUser() async {
    _currentUser = User(
      id: 1,
      username: 'demouser',
      email: 'demo@example.com',
      fullName: 'Demo User',
      userType: 'client',
      createdAt: DateTime.now(),
    );
    _isLoggedIn = true;
  }
}
EOL

# Fix login_screen.dart to use named parameters
cat > lib/screens/auth/login_screen.dart << 'EOL'
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eventora_app/config/theme.dart';
import 'package:eventora_app/services/auth_service.dart';
import 'package:eventora_app/widgets/app_button.dart';
import 'package:eventora_app/widgets/app_text_field.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onRegisterTap;
  final VoidCallback onForgotPasswordTap;
  
  const LoginScreen({
    Key? key,
    required this.onRegisterTap,
    required this.onForgotPasswordTap,
  }) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      // Updated to use named parameters
      await authService.login(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // App logo
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Image.asset(
                        'assets/images/daoob-logo.jpg',
                        width: 80,
                        height: 80,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Title
                const Text(
                  'Welcome Back',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to continue',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.textSecondaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 32),
                
                // Error message if any
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: AppTheme.errorColor,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                
                if (_errorMessage != null)
                  const SizedBox(height: 24),
                
                // Login form
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppTextField(
                        label: 'Username',
                        hint: 'Enter your username',
                        controller: _usernameController,
                        prefixIcon: const Icon(Icons.account_circle_outlined),
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your username';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      AppPasswordField(
                        label: 'Password',
                        hint: 'Enter your password',
                        controller: _passwordController,
                        textInputAction: TextInputAction.done,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Forgot password link
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: widget.onForgotPasswordTap,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          child: const Text('Forgot Password?'),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Login button
                      AppButton(
                        text: 'Sign In',
                        onPressed: _login,
                        isLoading: _isLoading,
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Register link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Don\'t have an account? ',
                            style: TextStyle(
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                          TextButton(
                            onPressed: widget.onRegisterTap,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                            ),
                            child: const Text('Sign Up'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
EOL

# Create or update API service to connect to local server
cat > lib/services/api_service.dart << 'EOL'
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  // Use different URLs for iOS simulator vs Android emulator
  static String get baseUrl {
    // When running on iOS simulator, use localhost
    if (Platform.isIOS) {
      return 'http://localhost:5000';
    }
    // When running on Android emulator, use 10.0.2.2 (special IP for Android emulator to reach host machine)
    else if (Platform.isAndroid) {
      return 'http://10.0.2.2:5000';
    }
    // Fallback for other platforms or web
    else {
      return 'http://localhost:5000';
    }
  }
  
  static const _storage = FlutterSecureStorage();
  
  // HTTP GET request with cookie-based session handling
  static Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final cookie = await _storage.read(key: 'session_cookie');
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: _getHeaders(cookie),
      );
      
      _saveSessionCookie(response);
      return _handleResponse(response);
    } catch (e) {
      debugPrint('GET request error: $e');
      rethrow;
    }
  }

  // HTTP POST request with cookie-based session handling
  static Future<Map<String, dynamic>> post(String endpoint, dynamic data) async {
    try {
      final cookie = await _storage.read(key: 'session_cookie');
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: _getHeaders(cookie),
        body: json.encode(data),
      );
      
      _saveSessionCookie(response);
      return _handleResponse(response);
    } catch (e) {
      debugPrint('POST request error: $e');
      rethrow;
    }
  }

  // HTTP PUT request with cookie-based session handling
  static Future<Map<String, dynamic>> put(String endpoint, dynamic data) async {
    try {
      final cookie = await _storage.read(key: 'session_cookie');
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: _getHeaders(cookie),
        body: json.encode(data),
      );
      
      _saveSessionCookie(response);
      return _handleResponse(response);
    } catch (e) {
      debugPrint('PUT request error: $e');
      rethrow;
    }
  }

  // HTTP DELETE request with cookie-based session handling
  static Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      final cookie = await _storage.read(key: 'session_cookie');
      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: _getHeaders(cookie),
      );
      
      _saveSessionCookie(response);
      return _handleResponse(response);
    } catch (e) {
      debugPrint('DELETE request error: $e');
      rethrow;
    }
  }

  // Helper method to get request headers with cookie
  static Map<String, String> _getHeaders(String? cookie) {
    final headers = {
      'Content-Type': 'application/json',
    };
    
    if (cookie != null) {
      headers['Cookie'] = cookie;
    }
    
    return headers;
  }
  
  // Helper method to save session cookie
  static Future<void> _saveSessionCookie(http.Response response) async {
    String? rawCookie = response.headers['set-cookie'];
    if (rawCookie != null) {
      await _storage.write(key: 'session_cookie', value: rawCookie);
      debugPrint('Saved session cookie: $rawCookie');
    }
  }

  // Helper method to handle HTTP responses
  static Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return {};
      }
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized access. Please login again.');
    } else {
      try {
        final errorJson = json.decode(response.body);
        final errorMessage = errorJson['message'] ?? 'An error occurred';
        throw Exception(errorMessage);
      } catch (e) {
        throw Exception('Request failed with status: ${response.statusCode}');
      }
    }
  }
}
EOL

# Update splash_screen.dart for offline toggle
cat > lib/screens/splash_screen.dart << 'EOL'
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eventora_app/config/theme.dart';
import 'package:eventora_app/services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _offlineMode = false;

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App logo
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Image.asset(
                    'assets/images/daoob-logo.jpg',
                    width: 120,
                    height: 120,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // App name
              const Text(
                'DAOOB',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              
              // Tagline
              Text(
                'Plan your perfect event',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.8),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 32),
              
              // Offline mode toggle
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Offline Demo Mode',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Switch(
                      value: _offlineMode,
                      onChanged: (value) {
                        setState(() {
                          _offlineMode = value;
                        });
                        authService.setOfflineMode(value);
                      },
                      activeColor: Colors.white,
                      activeTrackColor: Colors.green,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              // Loading indicator
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
              
              // Connection status
              if (_offlineMode)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    'Using demo data (offline mode)',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
EOL

# Exit with a message
echo "Flutter files have been updated. The build should now complete successfully."
echo "To run the app, use: 'cd eventora_mobile && flutter run'"