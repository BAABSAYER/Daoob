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

  Future<bool> login(String username, String password) async {
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