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
  
  // Initialize with some default categories
  EventProvider() {
    _categories = [
      EventCategory(
        id: 'wedding',
        name: 'Wedding',
        icon: '💍',
        description: 'Wedding planning and coordination services',
      ),
      EventCategory(
        id: 'corporate',
        name: 'Corporate',
        icon: '🏢',
        description: 'Business meetings, conferences, and corporate events',
      ),
      EventCategory(
        id: 'birthday',
        name: 'Birthday',
        icon: '🎂',
        description: 'Birthday parties and celebrations',
      ),
      EventCategory(
        id: 'graduation',
        name: 'Graduation',
        icon: '🎓',
        description: 'Graduation ceremonies and celebrations',
      ),
      EventCategory(
        id: 'baby-shower',
        name: 'Baby Shower',
        icon: '👶',
        description: 'Baby shower events and celebrations',
      ),
      EventCategory(
        id: 'cultural',
        name: 'Cultural',
        icon: '🎭',
        description: 'Cultural events and traditional celebrations',
      ),
    ];
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
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/event-types/$eventTypeId/questions'),
        headers: authService.token != null 
            ? ApiConfig.authHeaders(authService.token!)
            : <String, String>{},
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
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/event-requests'),
        headers: authService.token != null 
            ? ApiConfig.authHeaders(authService.token!)
            : <String, String>{},
        body: json.encode(requestData),
      );

      if (response.statusCode == 201) {
        final dynamic data = json.decode(response.body);
        final eventRequest = EventRequest.fromJson(data);
        _eventRequests.add(eventRequest);
        notifyListeners();
        return eventRequest;
      } else {
        throw Exception('Failed to create event request: ${response.statusCode}');
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

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/event-requests/client/${authService.user!.id}'),
        headers: authService.token != null 
            ? ApiConfig.authHeaders(authService.token!)
            : <String, String>{},
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