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