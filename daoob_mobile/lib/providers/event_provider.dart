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

      final response = await http.get(
        Uri.parse(ApiConfig.eventTypesEndpoint),
        headers: authService.token != null 
            ? ApiConfig.authHeaders(authService.token!)
            : <String, String>{},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _eventTypes = data.map((item) => EventType.fromJson(item)).toList();
        _isLoading = false;
        
        // Now load categories based on event types
        await loadCategories();
        
        notifyListeners();
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

  // Submit a new event request
  Future<EventRequest> submitEventRequest(
    Map<String, dynamic> requestData,
    AuthService authService,
  ) async {
    try {
      // Use the ApiService to ensure cookies are properly handled
      final response = await authService.apiService.post(
        '${ApiConfig.baseUrl}/api/event-requests',
        requestData,
      );

      if (response.statusCode == 201) {
        final dynamic data = json.decode(response.body);
        final eventRequest = EventRequest.fromJson(data);
        _eventRequests.add(eventRequest);
        notifyListeners();
        return eventRequest;
      } else {
        final errorMessage = response.body.isNotEmpty 
            ? 'Failed to create event request: ${response.body}'
            : 'Failed to create event request: ${response.statusCode}';
        throw Exception(errorMessage);
      }
    } catch (e) {
      throw Exception('Failed to create event request: $e');
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
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/quotations/client/${authService.user!.id}'),
        headers: authService.token != null 
            ? ApiConfig.authHeaders(authService.token!)
            : <String, String>{},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _quotations = data.map((item) => Quotation.fromJson(item)).toList();
        notifyListeners();
      } else {
        _error = 'Failed to load quotations: ${response.statusCode}';
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to load quotations: $e';
      notifyListeners();
    }
  }

  // Get a specific event request by ID
  Future<EventRequest?> getEventRequestById(
    int requestId,
    AuthService authService,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/event-requests/$requestId'),
        headers: authService.token != null 
            ? ApiConfig.authHeaders(authService.token!)
            : <String, String>{},
      );

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        return EventRequest.fromJson(data);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // Get a specific quotation by ID
  Future<Quotation?> getQuotationById(
    int quotationId,
    AuthService authService,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/quotations/$quotationId'),
        headers: authService.token != null 
            ? ApiConfig.authHeaders(authService.token!)
            : <String, String>{},
      );

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);
        return Quotation.fromJson(data);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // Get quotations for a specific event request
  Future<List<Quotation>> getQuotationsByRequestId(
    int requestId,
    AuthService authService,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/quotations/request/$requestId'),
        headers: authService.token != null 
            ? ApiConfig.authHeaders(authService.token!)
            : <String, String>{},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => Quotation.fromJson(item)).toList();
      } else {
        return [];
      }
    } catch (e) {
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
      final response = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/api/quotations/$quotationId'),
        headers: authService.token != null 
            ? ApiConfig.authHeaders(authService.token!)
            : <String, String>{},
        body: json.encode(updateData),
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
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
}