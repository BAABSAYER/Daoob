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

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;

  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) {
        _isLoggedIn = false;
        _currentUser = null;
      } else {
        final response = await http.get(
          Uri.parse('${ApiService.baseUrl}/api/user'),
          headers: {'Authorization': 'Bearer $token'},
        );

        if (response.statusCode == 200) {
          final userData = json.decode(response.body);
          _currentUser = User.fromJson(userData);
          _isLoggedIn = true;
        } else {
          // Token is invalid or expired
          await _storage.delete(key: 'auth_token');
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

    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/api/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        _currentUser = User.fromJson(userData);
        
        // In a real production app, the server would return a JWT token
        // For now, we'll store a placeholder since our backend uses sessions
        await _storage.write(key: 'auth_token', value: 'session_active');
        
        _isLoggedIn = true;
        notifyListeners();
        return true;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to login. Please try again.');
      }
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

    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/api/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': username,
          'password': password,
          'email': email,
          'fullName': fullName,
          'userType': 'client', // Default user type for mobile app users
        }),
      );

      if (response.statusCode == 201) {
        final userData = json.decode(response.body);
        _currentUser = User.fromJson(userData);
        
        // Store auth token
        await _storage.write(key: 'auth_token', value: 'session_active');
        
        _isLoggedIn = true;
        notifyListeners();
        return true;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Registration failed. Please try again.');
      }
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

    try {
      await http.post(Uri.parse('${ApiService.baseUrl}/api/logout'));
      await _storage.delete(key: 'auth_token');
      _isLoggedIn = false;
      _currentUser = null;
    } catch (e) {
      debugPrint('Logout error: $e');
      // Even if the server call fails, clear local storage
      await _storage.delete(key: 'auth_token');
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
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
}