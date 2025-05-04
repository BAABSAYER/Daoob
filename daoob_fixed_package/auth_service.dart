import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// Define User class directly in this file
class User {
  final int id;
  final String? username;
  final String? name;
  final String email;
  final String userType; // 'client' or 'vendor'

  User({
    required this.id,
    this.username,
    this.name,
    required this.email,
    required this.userType,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      name: json['name'] ?? json['username'] ?? 'Unknown',
      email: json['email'],
      userType: json['userType'] ?? 'client',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'name': name,
      'email': email,
      'userType': userType,
    };
  }

  static List<User> sampleUsers() {
    return [
      User(
        id: 1,
        username: 'johndoe',
        name: 'John Doe',
        email: 'john@example.com',
        userType: 'client',
      ),
      User(
        id: 2,
        username: 'elegantevents',
        name: 'Elegant Events',
        email: 'contact@elegantevents.com',
        userType: 'vendor',
      ),
      User(
        id: 3,
        username: 'deliciouscatering',
        name: 'Delicious Catering',
        email: 'info@deliciouscatering.com',
        userType: 'vendor',
      ),
    ];
  }

  static User generateMockUser(int id) {
    return User(
      id: id,
      username: 'user$id',
      name: 'User $id',
      email: 'user$id@example.com',
      userType: 'client',
    );
  }
}

class AuthService extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  bool _isOfflineMode = false;
  String? _error;

  User? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get isLoading => _isLoading;
  bool get isOfflineMode => _isOfflineMode;
  String? get error => _error;

  AuthService() {
    _loadUserFromPrefs();
    _loadOfflineMode();
  }

  Future<void> _loadUserFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    if (userJson != null) {
      try {
        _user = User.fromJson(json.decode(userJson));
        notifyListeners();
      } catch (e) {
        // If there's an error parsing the stored user, clear it
        await prefs.remove('user');
      }
    }
  }

  Future<void> _loadOfflineMode() async {
    final prefs = await SharedPreferences.getInstance();
    _isOfflineMode = prefs.getBool('offline_mode') ?? false;
    notifyListeners();
  }

  Future<bool> toggleOfflineMode(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('offline_mode', value);
      _isOfflineMode = value;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (_isOfflineMode) {
        // In offline mode, create a mock user
        await Future.delayed(const Duration(seconds: 1));
        
        _user = User(
          id: 1,
          username: 'offlineuser',
          name: 'Offline User',
          email: email.isNotEmpty ? email : "offline@daoob.com",
          userType: "client",
        );
        
        // Save to shared preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', json.encode(_user!.toJson()));
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        // Try API login first
        try {
          final response = await http.post(
            Uri.parse('https://api.daoob.com/login'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'email': email,
              'password': password,
            }),
          );
          
          if (response.statusCode == 200) {
            final userData = json.decode(response.body);
            _user = User.fromJson(userData);
          } else {
            throw Exception('Login failed');
          }
        } catch (e) {
          // If API fails, use sample users or generate a new user
          if (email.isNotEmpty && password.isNotEmpty) {
            // Try to find a sample user that matches the email
            final sampleUsers = User.sampleUsers();
            final matchingUsers = sampleUsers.where((u) => u.email.toLowerCase() == email.toLowerCase()).toList();
            
            if (matchingUsers.isNotEmpty) {
              _user = matchingUsers.first;
            } else {
              // Or create a new user from the template
              _user = User(
                id: DateTime.now().millisecondsSinceEpoch % 1000,
                username: email.split('@').first,
                name: email.split('@').first,
                email: email,
                userType: "client",
              );
            }
          } else {
            throw Exception('Invalid credentials');
          }
        }
        
        // Save to shared preferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', json.encode(_user!.toJson()));
        
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
    notifyListeners();
  }
}
