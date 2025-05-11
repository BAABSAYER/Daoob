import 'dart:io';

class ApiConfig {
  // Determine the base URL based on the environment
  static String get baseUrl {
    // For real device on the same network, this should be replaced with your local IP
    // during deployment, e.g., 'http://192.168.1.100:5000'
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:5000'; // Special IP for Android emulator to reach host
    } else if (Platform.isIOS) {
      return 'http://localhost:5000'; // Works for iOS simulator
    } else {
      return 'http://localhost:5000'; // Default for other platforms
    }
  }

  // API endpoints
  static String get apiUrl => '$baseUrl/api';
  static String get wsUrl => baseUrl.replaceFirst('http', 'ws') + '/ws';
  
  // Auth endpoints
  static String get loginEndpoint => '$apiUrl/login';
  static String get registerEndpoint => '$apiUrl/register';
  static String get userEndpoint => '$apiUrl/user';
  static String get logoutEndpoint => '$apiUrl/logout';
  
  // Vendor endpoints
  static String get vendorsEndpoint => '$apiUrl/vendors';
  
  // Booking endpoints
  static String get bookingsEndpoint => '$apiUrl/bookings';
  
  // Review endpoints
  static String get reviewsEndpoint => '$apiUrl/reviews';
  
  // Message endpoints
  static String get messagesEndpoint => '$apiUrl/messages';
  
  // Event Management endpoints
  static String get eventTypesEndpoint => '$apiUrl/event-types';
  static String get eventRequestsEndpoint => '$apiUrl/event-requests';
  static String get quotationsEndpoint => '$apiUrl/quotations';
  
  // Offline mode settings
  static const bool defaultOfflineMode = false;
  static const int cacheExpirationHours = 24;
  
  // Headers
  static Map<String, String> get jsonHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  static Map<String, String> authHeaders(String token) => {
    ...jsonHeaders,
    'Authorization': 'Bearer $token',
  };
}