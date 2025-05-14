import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../config/api_config.dart';
import './api_service.dart';

class User {
  final int id;
  final String? name;
  final String email;
  final String userType;
  final String? phone;  // Added phone field
  final String? username;  // Added username field for compatibility
  
  User({
    required this.id,
    required this.name,
    required this.email,
    required this.userType,
    this.phone,  // Added to constructor
    this.username,  // Added to constructor
  });
  
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      userType: json['userType'],
      phone: json['phone'],  // Added to fromJson
      username: json['username'],  // Added to fromJson
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'userType': userType,
      'phone': phone,  // Added to toJson
      'username': username,  // Added to toJson
    };
  }
}

class AuthService extends ChangeNotifier {
  User? _user;
  String? _token;
  String? _error;
  bool _isLoading = false;
  bool _isLoggedIn = false;
  int _unreadMessageCount = 0;
  
  // API Service for consistent API communication
  final ApiService _apiService = ApiService();

  User? get user => _user;
  String? get token => _token;
  String? get error => _error;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  int get unreadMessageCount => _unreadMessageCount;
  
  // Update unread message count
  void updateUnreadMessageCount(int count) {
    _unreadMessageCount = count;
    notifyListeners();
  }

  AuthService() {
    _loadStoredData();
  }

  Future<void> _loadStoredData() async {
    final prefs = await SharedPreferences.getInstance();
    final storedUser = prefs.getString('user');
    final storedToken = prefs.getString('token');
    
    if (storedUser != null) {
      _user = User.fromJson(json.decode(storedUser));
      _token = storedToken;
      _isLoggedIn = true;
    }
    
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // Login using the ApiService
      final loginResponse = await _apiService.post(
        ApiConfig.loginEndpoint,
        {
          'username': username,
          'password': password,
        },
      );
      
      if (loginResponse.statusCode == 200) {
        try {
          // Get user info from the current session
          final userResponse = await _apiService.get(ApiConfig.userEndpoint);
          
          if (userResponse.statusCode == 200) {
            final dynamic userData = json.decode(userResponse.body);
            print("User data from server: $userData");
            
            try {
              // Use more flexible parsing to handle different response formats
              _user = User(
                id: userData['id'],
                name: userData['fullName'] ?? userData['username'] ?? username,
                email: userData['email'] ?? '$username@example.com',
                userType: userData['userType'] ?? 'client',
                phone: userData['phone'],
                username: userData['username'] ?? username,
              );
              
              // For debugging
              print("Successfully created user object: ${_user!.toJson()}");
              
              // Cookie-based authentication is handled by the ApiService
              _isLoggedIn = true;
              
              // Save user data to preferences
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('user', json.encode(_user!.toJson()));
              
              _isLoading = false;
              notifyListeners();
              return true;
            } catch (parseError) {
              _error = 'Error parsing user data: ${parseError.toString()}\nData: $userData';
              _isLoading = false;
              notifyListeners();
              return false;
            }
          } else {
            _error = 'Failed to get user info after login. Status: ${userResponse.statusCode}, Body: ${userResponse.body}';
            _isLoading = false;
            notifyListeners();
            return false;
          }
        } catch (e) {
          _error = 'Error getting user data: ${e.toString()}';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      } else {
        try {
          _error = json.decode(loginResponse.body)['message'] ?? 'Login failed';
        } catch (e) {
          _error = 'Login failed: ${loginResponse.statusCode}';
        }
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Network error: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String name, String email, String password, String userType) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.registerEndpoint),
        headers: ApiConfig.jsonHeaders,
        body: json.encode({
          'name': name,
          'email': email,
          'password': password,
          'userType': userType,
        }),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);
        
        _user = User.fromJson(data['user']);
        _token = data['token'];
        _isLoggedIn = true;
        
        // Save to preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', json.encode(_user!.toJson()));
        await prefs.setString('token', _token!);
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = json.decode(response.body)['message'] ?? 'Registration failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Network error: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    try {
      // Call the logout endpoint using ApiService (which handles cookies)
      await _apiService.post(ApiConfig.logoutEndpoint, {});
    } catch (e) {
      // Ignore errors during logout
      print('Error during logout: $e');
    }
    
    // Clear stored data
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
    await prefs.remove('token');
    await prefs.remove('cookies');
    
    _user = null;
    _token = null;
    _isLoggedIn = false;
    
    notifyListeners();
  }
  
  // Server connectivity check
  Future<bool> testServerConnectivity() async {
    try {
      final response = await http.get(Uri.parse("${ApiConfig.apiUrl}/health"))
          .timeout(const Duration(seconds: 5));
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      print("Server connectivity test failed: $e");
      return false;
    }
  }
}
