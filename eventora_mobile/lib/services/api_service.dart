import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static const String baseUrl = 'https://eventora-app.replit.app'; // Replace with your deployed app URL
  static const _storage = FlutterSecureStorage();

  // HTTP GET request with authorization
  static Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: _getHeaders(token),
      );
      
      return _handleResponse(response);
    } catch (e) {
      debugPrint('GET request error: $e');
      rethrow;
    }
  }

  // HTTP POST request with authorization
  static Future<Map<String, dynamic>> post(String endpoint, dynamic data) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: _getHeaders(token),
        body: json.encode(data),
      );
      
      return _handleResponse(response);
    } catch (e) {
      debugPrint('POST request error: $e');
      rethrow;
    }
  }

  // HTTP PUT request with authorization
  static Future<Map<String, dynamic>> put(String endpoint, dynamic data) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: _getHeaders(token),
        body: json.encode(data),
      );
      
      return _handleResponse(response);
    } catch (e) {
      debugPrint('PUT request error: $e');
      rethrow;
    }
  }

  // HTTP DELETE request with authorization
  static Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      final token = await _storage.read(key: 'auth_token');
      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: _getHeaders(token),
      );
      
      return _handleResponse(response);
    } catch (e) {
      debugPrint('DELETE request error: $e');
      rethrow;
    }
  }

  // Helper method to get request headers
  static Map<String, String> _getHeaders(String? token) {
    final headers = {
      'Content-Type': 'application/json',
    };
    
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    return headers;
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