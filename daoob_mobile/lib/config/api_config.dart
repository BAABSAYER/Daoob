import 'dart:io';

class ApiConfig {
  // API URLs for different environments
  static const String productionApiUrl = 'https://api.daoob.com';
  
  // Update this URL to match your actual Replit deployment URL
  static const String replitDeploymentUrl = 'https://daoob.replit.app';
  
  // Deployment environments
  static const int ENV_LOCAL = 0;
  static const int ENV_REPLIT = 1;
  static const int ENV_PRODUCTION = 2;
  
  // Set the current environment (0=local, 1=replit, 2=production)
  // Change this value to connect to different environments
  static const int currentEnvironment = ENV_REPLIT; // Set to ENV_REPLIT by default
  
  // Determine if we're in production mode (for Flutter build)
  static const bool isProductionBuild = bool.fromEnvironment('dart.vm.product');
  
  // Base URL based on environment
  static String get baseUrl {
    // Override with environment setting
    if (currentEnvironment == ENV_PRODUCTION) {
      return productionApiUrl;
    } else if (currentEnvironment == ENV_REPLIT) {
      return replitDeploymentUrl;
    } else {
      // Local development
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:5000'; // Special IP for Android emulator
      } else if (Platform.isIOS) {
        return 'http://localhost:5000'; // Works for iOS simulator
      } else {
        return 'http://localhost:5000'; // Default for other platforms
      }
    }
  }

  // API endpoints
  static String get apiUrl => '$baseUrl/api';
  
  // WebSocket URL with proper protocol (ws or wss based on HTTP/HTTPS)
  static String get wsUrl {
    if (baseUrl.startsWith('https')) {
      return baseUrl.replaceFirst('https', 'wss') + '/ws';
    } else {
      return baseUrl.replaceFirst('http', 'ws') + '/ws';
    }
  }
  
  // Auth endpoints
  static String get loginEndpoint => '$apiUrl/login';
  static String get registerEndpoint => '$apiUrl/register';
  static String get userEndpoint => '$apiUrl/user';
  static String get logoutEndpoint => '$apiUrl/logout';
  
  // Event Management endpoints
  static String get eventTypesEndpoint => '$apiUrl/event-types';
  static String get eventRequestsEndpoint => '$apiUrl/event-requests';
  static String get quotationsEndpoint => '$apiUrl/quotations';
  
  // Booking endpoints
  static String get bookingsEndpoint => '$apiUrl/bookings';
  
  // Message endpoints
  static String get messagesEndpoint => '$apiUrl/messages';
  
  // Headers
  static Map<String, String> get jsonHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  // Standard auth headers for token-based authentication
  static Map<String, String> authHeaders(String token) => {
    ...jsonHeaders,
    'Authorization': 'Bearer $token',
  };
  
  // Cookie-based auth headers for session authentication
  static Map<String, String> get cookieAuthHeaders => {
    ...jsonHeaders,
    // Enable these headers to ensure cookies are sent with requests
    'withCredentials': 'true',
  };
}