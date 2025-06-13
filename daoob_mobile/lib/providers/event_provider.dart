import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:daoob_mobile/models/event_type.dart';
import 'package:daoob_mobile/models/event_request.dart';
import 'package:daoob_mobile/models/quotation.dart';
import 'package:daoob_mobile/models/questionnaire_item.dart';
import 'package:daoob_mobile/models/event_category.dart';
import 'package:daoob_mobile/config/api_config.dart';
import 'package:daoob_mobile/services/auth_service.dart';

class EventProvider with ChangeNotifier {
  List<EventType> _eventTypes = [];
  List<EventRequest> _eventRequests = [];
  List<Quotation> _quotations = [];
  List<EventCategory> _categories = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<EventType> get eventTypes => _eventTypes;
  List<EventRequest> get eventRequests => _eventRequests;
  List<Quotation> get quotations => _quotations;
  List<EventCategory> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Currently selected category ID
  String? _selectedCategoryId;
  
  // Get a category by ID
  EventCategory? getCategoryById(String id) {
    return _categories.firstWhere(
      (category) => category.id == id,
      orElse: () => EventCategory(
        id: id,
        name: id.substring(0, 1).toUpperCase() + id.substring(1).replaceAll('-', ' '),
        icon: '📅',
      ),
    );
  }
  
  // Get the selected category
  EventCategory? get selectedCategory {
    if (_selectedCategoryId == null) return null;
    return getCategoryById(_selectedCategoryId!);
  }
  
  // Select a category
  void selectCategory(String id) {
    _selectedCategoryId = id;
    notifyListeners();
  }
  
  // Initialize with empty categories
  EventProvider() {
    _categories = [];
  }
  
  // Load categories from event types
  Future<void> loadCategories() async {
    try {
      // Categories are derived from event types in this application
      // Group event types by their category property
      Map<String, EventCategory> categoryMap = {};
      
      for (var eventType in _eventTypes) {
        if (eventType.categoryId != null && eventType.categoryId!.isNotEmpty) {
          // Use the event type's icon for the category if available
          final categoryId = eventType.categoryId!;
          
          if (!categoryMap.containsKey(categoryId)) {
            // Use name as the display name for the category
            final categoryName = eventType.name;
            
            categoryMap[categoryId] = EventCategory(
              id: categoryId,
              name: categoryName,
              icon: eventType.icon ?? _getCategoryIcon(categoryId),
              description: eventType.description ?? 'Events related to ${eventType.name}',
            );
          }
        }
      }
      
      _categories = categoryMap.values.toList();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load categories: $e';
      notifyListeners();
    }
  }
  
  // Get appropriate icon for category
  String _getCategoryIcon(String categoryId) {
    final iconMap = {
      'wedding': '💍',
      'corporate': '🏢',
      'birthday': '🎂',
      'graduation': '🎓',
      'baby-shower': '👶',
      'cultural': '🎭',
    };
    
    return iconMap[categoryId] ?? '📅'; // Default icon
  }

  // Load event types from the server
  Future<void> loadEventTypes(AuthService authService) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Use the ApiService to handle cookie management consistently
      final response = await authService.apiService.get(ApiConfig.eventTypesEndpoint);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _eventTypes = data.map((item) => EventType.fromJson(item)).toList();
        _isLoading = false;
        
        // Now load categories based on event types
        await loadCategories();
        
        notifyListeners();
      } else if (response.statusCode == 401) {
        // Authentication error - let the user know they need to log in
        _error = 'Please log in to view event types';
        _isLoading = false;
        notifyListeners();
        
        // If this is an auth error, attempt to clear session and redirect to login
        if (authService.isLoggedIn) {
          print('Authentication error - clearing session');
          await authService.logout();
        }
      } else {
        _error = 'Failed to load event types: ${response.statusCode}';
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to load event types: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get questions for a specific event type
  Future<List<QuestionnaireItem>> getQuestionsForEventType(
    int eventTypeId,
    AuthService authService,
  ) async {
    try {
      final response = await authService.apiService.get(
        '${ApiConfig.baseUrl}/api/event-types/$eventTypeId/questions'
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => QuestionnaireItem.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load questions: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load questions: $e');
    }
  }

  // Submit a new booking (updated to use bookings-centric workflow)
  Future<Map<String, dynamic>> submitEventRequest(
    Map<String, dynamic> requestData,
    AuthService authService,
  ) async {
    try {
      // First verify that the user is logged in
      if (!authService.isLoggedIn || authService.user == null) {
        throw Exception('You must be logged in to submit a request. Please log in and try again.');
      }
      
      // Make sure clientId is included
      if (requestData['clientId'] == null) {
        requestData['clientId'] = authService.user!.id;
      }
      
      // Transform the request data to match the new booking structure
      final bookingData = {
        'clientId': requestData['clientId'],
        'eventDate': requestData['eventDate'],
        'eventTime': requestData['eventTime'] ?? '',
        'estimatedGuests': requestData['estimatedGuests'] ?? 50,
        'status': 'pending',
        'eventTypeId': null, // Will be determined by the backend based on category
        'questionnaireResponses': requestData['answers'] ?? {},
        'notes': 'Submitted from mobile app for category: ${requestData['categoryId']}',
      };
      
      // For debugging, log what we're sending
      print('Submitting booking: ${json.encode(bookingData)}');
      
      // Use the ApiService to ensure cookies are properly handled
      final response = await authService.apiService.post(
        '${ApiConfig.baseUrl}/api/bookings',
        bookingData,
      );

      if (response.statusCode == 201) {
        final dynamic data = json.decode(response.body);
        notifyListeners();
        return data;
      } else if (response.statusCode == 401) {
        // Authentication error
        throw Exception('Your session has expired. Please log in again.');
      } else {
        final errorMessage = response.body.isNotEmpty 
            ? 'Failed to create booking: ${response.body}'
            : 'Failed to create booking: ${response.statusCode}';
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Failed to create booking: $e');
    }
  }

  // Load event requests for the current user
  Future<void> loadEventRequests(AuthService authService) async {
    if (authService.user == null) return;
    
    try {
      _isLoading = true;
      notifyListeners();

      final response = await authService.apiService.get(
        '${ApiConfig.baseUrl}/api/event-requests/client/${authService.user!.id}'
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _eventRequests = data.map((item) => EventRequest.fromJson(item)).toList();
        _isLoading = false;
        notifyListeners();
      } else {
        _error = 'Failed to load event requests: ${response.statusCode}';
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to load event requests: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load quotations for the current user
  Future<void> loadQuotations(AuthService authService) async {
    if (authService.user == null) return;
    
    try {
      _isLoading = true;
      notifyListeners();
      
      final response = await authService.apiService.get(
        '${ApiConfig.baseUrl}/api/quotations/client/${authService.user!.id}'
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _quotations = data.map((item) => Quotation.fromJson(item)).toList();
        _isLoading = false;
        notifyListeners();
      } else if (response.statusCode == 401) {
        // Authentication error
        _error = 'Your session has expired. Please log in again.';
        _isLoading = false;
        notifyListeners();
        
        // If this is an auth error, attempt to clear session
        if (authService.isLoggedIn) {
          print('Authentication error while loading quotations - clearing session');
          await authService.logout();
        }
      } else {
        _error = 'Failed to load quotations: ${response.statusCode}';
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to load quotations: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get a specific event request by ID
  Future<EventRequest?> getEventRequestById(
    int requestId,
    AuthService authService,
  ) async {
    try {
      // Check authentication first
      if (!authService.isLoggedIn) {
        print('User not logged in, cannot get event request');
        return null;
      }
      
      final response = await authService.apiService.get(
        '${ApiConfig.baseUrl}/api/event-requests/$requestId'
      );

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        return EventRequest.fromJson(data);
      } else if (response.statusCode == 401) {
        // Authentication error
        _error = 'Your session has expired. Please log in again.';
        notifyListeners();
        
        // If this is an auth error, attempt to clear session
        print('Authentication error while getting event request - clearing session');
        await authService.logout();
        return null;
      } else {
        _error = 'Failed to load event request: ${response.statusCode}';
        notifyListeners();
        return null;
      }
    } catch (e) {
      _error = 'Failed to load event request: $e';
      notifyListeners();
      return null;
    }
  }

  // Get a specific quotation by ID
  Future<Quotation?> getQuotationById(
    int quotationId,
    AuthService authService,
  ) async {
    try {
      // Check authentication first
      if (!authService.isLoggedIn) {
        print('User not logged in, cannot get quotation');
        return null;
      }
      
      final response = await authService.apiService.get(
        '${ApiConfig.baseUrl}/api/quotations/$quotationId'
      );

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        return Quotation.fromJson(data);
      } else if (response.statusCode == 401) {
        // Authentication error
        _error = 'Your session has expired. Please log in again.';
        notifyListeners();
        
        // If this is an auth error, attempt to clear session
        print('Authentication error while getting quotation - clearing session');
        await authService.logout();
        return null;
      } else {
        _error = 'Failed to load quotation: ${response.statusCode}';
        notifyListeners();
        return null;
      }
    } catch (e) {
      _error = 'Failed to load quotation: $e';
      notifyListeners();
      return null;
    }
  }

  // Get quotations for a specific event request
  Future<List<Quotation>> getQuotationsByRequestId(
    int requestId,
    AuthService authService,
  ) async {
    try {
      // Check authentication first
      if (!authService.isLoggedIn) {
        print('User not logged in, cannot get quotations for request');
        return [];
      }
      
      final response = await authService.apiService.get(
        '${ApiConfig.baseUrl}/api/quotations/request/$requestId'
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => Quotation.fromJson(item)).toList();
      } else if (response.statusCode == 401) {
        // Authentication error
        _error = 'Your session has expired. Please log in again.';
        notifyListeners();
        
        // If this is an auth error, attempt to clear session
        print('Authentication error while getting quotations for request - clearing session');
        await authService.logout();
        return [];
      } else {
        _error = 'Failed to load quotations for request: ${response.statusCode}';
        notifyListeners();
        return [];
      }
    } catch (e) {
      _error = 'Failed to load quotations for request: $e';
      notifyListeners();
      return [];
    }
  }

  // Update a quotation (e.g., accept or decline)
  Future<Quotation?> updateQuotation(
    int quotationId,
    Map<String, dynamic> updateData,
    AuthService authService,
  ) async {
    try {
      // Check authentication first
      if (!authService.isLoggedIn) {
        print('User not logged in, cannot update quotation');
        return null;
      }
      
      final response = await authService.apiService.patch(
        '${ApiConfig.baseUrl}/api/quotations/$quotationId',
        updateData,
      );

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        final updatedQuotation = Quotation.fromJson(data);
        
        // Update the local list
        final index = _quotations.indexWhere((q) => q.id == quotationId);
        if (index >= 0) {
          _quotations[index] = updatedQuotation;
        }
        
        notifyListeners();
        return updatedQuotation;
      } else if (response.statusCode == 401) {
        // Authentication error
        _error = 'Your session has expired. Please log in again.';
        notifyListeners();
        
        // If this is an auth error, attempt to clear session
        print('Authentication error while updating quotation - clearing session');
        await authService.logout();
        return null;
      } else {
        _error = 'Failed to update quotation: ${response.statusCode}';
        notifyListeners();
        return null;
      }
    } catch (e) {
      _error = 'Failed to update quotation: $e';
      notifyListeners();
      return null;
    }
  }
}