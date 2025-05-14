import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../config/api_config.dart';

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
  bool _isOfflineMode = false;

  User? get user => _user;
  String? get token => _token;
  String? get error => _error;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  bool get isOfflineMode => _isOfflineMode;

  AuthService() {
    _loadStoredData();
  }

  Future<void> _loadStoredData() async {
    final prefs = await SharedPreferences.getInstance();
    final storedUser = prefs.getString('user');
    final storedToken = prefs.getString('token');
    final offlineMode = prefs.getBool('offline_mode') ?? false;
    
    _isOfflineMode = offlineMode;
    
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
    
    // If offline mode is active, create a mock user and succeed
    if (_isOfflineMode) {
      await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
      
      _user = User(
        id: 1,
        name: 'Offline User',
        email: '$username@example.com',
        userType: 'client',
        username: username,
      );
      
      _token = 'offline_mock_token';
      _isLoggedIn = true;
      
      // Save to preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', json.encode(_user!.toJson()));
      await prefs.setString('token', _token!);
      
      _isLoading = false;
      notifyListeners();
      return true;
    }
    
    try {
      final client = http.Client();
      
      // Set up a custom HttpClient to handle cookies
      final httpClient = HttpClient();
      httpClient.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
      
      // First request to login and get the cookie
      final response = await client.post(
        Uri.parse(ApiConfig.loginEndpoint),
        headers: ApiConfig.jsonHeaders,
        body: json.encode({
          'username': username,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        // Store the session cookies
        final cookies = response.headers['set-cookie'];
        
        if (cookies != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('cookies', cookies);
        }
        
        // Get user info from the current session
        final userResponse = await client.get(
          Uri.parse(ApiConfig.userEndpoint),
          headers: {
            ...ApiConfig.jsonHeaders,
            if (cookies != null) 'Cookie': cookies,
          },
        ).timeout(const Duration(seconds: 10));
        
        if (userResponse.statusCode == 200) {
          final Map<String, dynamic> userData = json.decode(userResponse.body);
          
          _user = User(
            id: userData['id'],
            name: userData['firstName'] ?? userData['username'],
            email: userData['email'] ?? '$username@example.com',
            userType: userData['permissions']?.contains('admin') ? 'admin' : 'client',
            username: userData['username'] ?? username,
          );
          
          // Use the cookies as the token for session-based auth
          _token = cookies;
          _isLoggedIn = true;
          
          // Save to preferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user', json.encode(_user!.toJson()));
          await prefs.setString('token', _token!);
          
          _isLoading = false;
          notifyListeners();
          return true;
        } else {
          _error = 'Failed to get user info after login';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      } else {
        try {
          _error = json.decode(response.body)['message'] ?? 'Login failed';
        } catch (e) {
          _error = 'Login failed: ${response.statusCode}';
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
    
    // If offline mode is active, create a mock user and succeed
    if (_isOfflineMode) {
      await Future.delayed(const Duration(seconds: 1)); // Simulate network delay
      
      _user = User(
        id: 1,
        name: name,
        email: email,
        userType: userType,
      );
      
      _token = 'offline_mock_token';
      _isLoggedIn = true;
      
      // Save to preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', json.encode(_user!.toJson()));
      await prefs.setString('token', _token!);
      
      _isLoading = false;
      notifyListeners();
      return true;
    }
    
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
    if (!_isOfflineMode && _token != null) {
      try {
        // Call the logout endpoint
        await http.post(
          Uri.parse(ApiConfig.logoutEndpoint),
          headers: ApiConfig.authHeaders(_token!),
        ).timeout(const Duration(seconds: 5));
      } catch (e) {
        // Ignore errors during logout
        print('Error during logout: $e');
      }
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
    await prefs.remove('token');
    
    _user = null;
    _token = null;
    _isLoggedIn = false;
    
    notifyListeners();
  }
  
  Future<void> toggleOfflineMode(bool value) async {
    _isOfflineMode = value;
    
    // Save offline mode preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('offline_mode', value);
    
    notifyListeners();
  }
}
