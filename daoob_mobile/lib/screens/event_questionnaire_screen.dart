import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:daoob_mobile/l10n/language_provider.dart';
import 'package:daoob_mobile/providers/event_provider.dart';
import 'package:daoob_mobile/services/auth_service.dart';
import 'package:daoob_mobile/models/event_category.dart';
import 'package:daoob_mobile/models/questionnaire_item.dart';
import 'package:daoob_mobile/screens/request_confirmation_screen.dart';
import 'package:daoob_mobile/config/api_config.dart';

class EventQuestionnaireScreen extends StatefulWidget {
  final String categoryId;
  
  const EventQuestionnaireScreen({super.key, required this.categoryId});

  @override
  State<EventQuestionnaireScreen> createState() => _EventQuestionnaireScreenState();
}

class _EventQuestionnaireScreenState extends State<EventQuestionnaireScreen> {
  bool _isLoading = true;
  final Map<String, dynamic> _answers = {};
  final _formKey = GlobalKey<FormState>();
  List<QuestionnaireItem> _questions = [];
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  int _estimatedGuests = 50;
  
  @override
  void initState() {
    super.initState();
    // First check if user is logged in before loading questions
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthAndLoadQuestions();
    });
  }
  
  Future<void> _checkAuthAndLoadQuestions() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    // Use the new helper method to check authentication
    bool isLoggedIn = await authService.checkLoginStatus(context);
    if (!isLoggedIn) {
      return;
    }
    
    // User is authenticated, proceed to load questions
    _loadQuestions();
  }
  
  Future<void> _loadQuestions() async {
    try {
      final eventProvider = Provider.of<EventProvider>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      
      // Set the current category
      eventProvider.selectCategory(widget.categoryId);
      
      // First fetch all event types to find the correct ID for this category
      final eventTypesUrl = '${ApiConfig.apiUrl}/event-types';
      final eventTypesResponse = await authService.apiService.get(eventTypesUrl);
      
      int? eventTypeId;
      if (eventTypesResponse.statusCode == 200) {
        final List<dynamic> eventTypesJson = jsonDecode(eventTypesResponse.body);
        // Find the event type that matches our category
        for (var eventType in eventTypesJson) {
          String eventTypeName = eventType['name'].toString().toLowerCase();
          if (eventTypeName.contains(widget.categoryId.toLowerCase()) || 
              widget.categoryId.toLowerCase().contains(eventTypeName)) {
            eventTypeId = eventType['id'];
            break;
          }
        }
        
        // If no exact match, use the first available event type
        if (eventTypeId == null && eventTypesJson.isNotEmpty) {
          eventTypeId = eventTypesJson.first['id'];
        }
      }
      
      // If we still don't have an event type ID, use fallback
      eventTypeId ??= _getEventTypeIdFromCategory(widget.categoryId);
      
      // Fetch questions from API for this event type using authService.apiService
      final url = '${ApiConfig.apiUrl}/event-types/$eventTypeId/questionnaire-items';
      
      // Use ApiService for consistent cookie handling
      final response = await authService.apiService.get(url);
      
      if (response.statusCode == 200) {
        final List<dynamic> questionsJson = jsonDecode(response.body);
        final List<QuestionnaireItem> questions = questionsJson
            .map((json) => QuestionnaireItem.fromJson(json))
            .toList();
        
        if (mounted) {
          setState(() {
            _questions = questions;
            _isLoading = false;
          });
        }
      } else {
        // API error, check if it's an auth error (401)
        if (response.statusCode == 401) {
          // Session expired - show login dialog
          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                final languageProvider = Provider.of<LanguageProvider>(context);
                final bool isArabic = languageProvider.locale.languageCode == 'ar';
                
                return AlertDialog(
                  title: Text(isArabic ? 'انتهت الجلسة' : 'Session Expired'),
                  content: Text(
                    isArabic 
                        ? 'انتهت جلستك. يرجى تسجيل الدخول مرة أخرى.'
                        : 'Your session has expired. Please login again.'
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).pushReplacementNamed('/login');
                      },
                      child: Text(isArabic ? 'تسجيل الدخول' : 'Login'),
                    ),
                  ],
                );
              },
            );
          }
          return;
        }
        
        // Other API error, fallback to empty question list
        print('Error loading questions: ${response.statusCode} - ${response.body}');
        if (mounted) {
          setState(() {
            _questions = [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      // Handle error
      print('Exception loading questions: $e');
      if (mounted) {
        setState(() {
          _questions = [];
          _isLoading = false;
        });
      }
    }
  }
  
  int _getEventTypeIdFromCategory(String categoryId) {
    // Map category IDs to event type IDs
    // This would typically come from API or configuration
    switch (categoryId) {
      case 'wedding':
        return 1;
      case 'corporate':
        return 2;
      case 'birthday':
        return 3;
      default:
        return 4; // Other event types
    }
  }

  // Removed sample data generation method as we now fetch questions from the API
  
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }
  
  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }
  
  Widget _buildQuestionWidget(QuestionnaireItem question, bool isArabic) {
    switch (question.answerType) {
      case 'text':
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: TextFormField(
            decoration: InputDecoration(
              labelText: question.questionText,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            maxLines: question.questionText.length > 50 ? 3 : 1,
            validator: question.isRequired 
                ? (value) => value!.isEmpty 
                    ? (isArabic ? 'هذا الحقل مطلوب' : 'This field is required') 
                    : null
                : null,
            onSaved: (value) {
              _answers[question.id.toString()] = value;
            },
          ),
        );
        
      case 'number':
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: TextFormField(
            decoration: InputDecoration(
              labelText: question.questionText,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            keyboardType: TextInputType.number,
            validator: question.isRequired 
                ? (value) => value!.isEmpty 
                    ? (isArabic ? 'هذا الحقل مطلوب' : 'This field is required') 
                    : null
                : null,
            onSaved: (value) {
              _answers[question.id.toString()] = int.tryParse(value ?? '0') ?? 0;
            },
          ),
        );
        
      case 'boolean':
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: FormField<bool>(
            initialValue: false,
            validator: question.isRequired ? null : null,
            builder: (field) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    question.questionText,
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<bool>(
                          title: Text(isArabic ? 'نعم' : 'Yes'),
                          value: true,
                          groupValue: field.value,
                          onChanged: (value) {
                            field.didChange(value);
                            _answers[question.id.toString()] = value;
                          },
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<bool>(
                          title: Text(isArabic ? 'لا' : 'No'),
                          value: false,
                          groupValue: field.value,
                          onChanged: (value) {
                            field.didChange(value);
                            _answers[question.id.toString()] = value;
                          },
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ),
                    ],
                  ),
                  if (field.hasError)
                    Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Text(
                        field.errorText!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              );
            },
            onSaved: (value) {
              _answers[question.id.toString()] = value ?? false;
            },
          ),
        );
        
      case 'select':
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: FormField<String>(
            validator: question.isRequired 
                ? (value) => value == null 
                    ? (isArabic ? 'الرجاء اختيار خيار' : 'Please select an option') 
                    : null
                : null,
            builder: (field) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    question.questionText,
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: field.value,
                        isExpanded: true,
                        hint: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            isArabic ? 'اختر خيارًا' : 'Select an option',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        borderRadius: BorderRadius.circular(8),
                        items: question.options?.map((option) {
                          return DropdownMenuItem(
                            value: option,
                            child: Text(option),
                          );
                        }).toList() ?? [],
                        onChanged: (newValue) {
                          field.didChange(newValue);
                          _answers[question.id.toString()] = newValue;
                        },
                      ),
                    ),
                  ),
                  if (field.hasError)
                    Padding(
                      padding: const EdgeInsets.only(left: 12, top: 8),
                      child: Text(
                        field.errorText!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              );
            },
            onSaved: (value) {
              _answers[question.id.toString()] = value;
            },
          ),
        );
        
      default:
        return Container();
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      // Check authentication first
      final authService = Provider.of<AuthService>(context, listen: false);
      if (authService.user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to submit a request')),
        );
        return;
      }
      
      if (_selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an event date')),
        );
        return;
      }
      
      // Process answers - ensure no null values are passed as strings
      final Map<String, dynamic> processedAnswers = {};
      _answers.forEach((key, value) {
        // Convert null to empty string to avoid type errors
        if (value == null) {
          processedAnswers[key] = '';
        } else {
          processedAnswers[key] = value;
        }
      });
      
      // Format event time properly or use empty string
      String formattedEventTime = '';
      if (_selectedTime != null) {
        // Ensure minutes are zero-padded (e.g., 9:5 becomes 9:05)
        String minutes = _selectedTime!.minute < 10 
            ? '0${_selectedTime!.minute}' 
            : '${_selectedTime!.minute}';
        formattedEventTime = '${_selectedTime!.hour}:$minutes';
      }
      
      // Create the request data with proper type handling
      final requestData = {
        'categoryId': widget.categoryId,
        'answers': processedAnswers,
        'eventDate': _selectedDate!.toIso8601String(),
        'eventTime': formattedEventTime != '' ? formattedEventTime : '', // Empty string instead of null
        'estimatedGuests': _estimatedGuests,
        'status': 'pending',
        // Add client info early to help with debugging
        'clientId': authService.user?.id ?? 0, // Default to 0 if null
        'clientName': authService.user?.name ?? '', // Default to empty string if null
        'clientEmail': authService.user?.email ?? '', // Default to empty string if null
        'clientPhone': authService.user?.phone ?? '', // Default to empty string if null
      };
      
      print('Debug - Request data: ${jsonEncode(requestData)}');
      
      // Navigate to confirmation screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RequestConfirmationScreen(requestData: requestData),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final eventProvider = Provider.of<EventProvider>(context);
    final category = eventProvider.getCategoryById(widget.categoryId);
    final bool isArabic = languageProvider.locale.languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          category != null 
              ? category.name
              : isArabic
                  ? 'استبيان الحدث'
                  : 'Event Questionnaire',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF6A3DE8),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isArabic
                          ? 'الرجاء إكمال التفاصيل التالية لحدثك'
                          : 'Please complete the following details for your event',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Event date picker
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isArabic ? 'تاريخ الحدث' : 'Event Date',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _selectDate(context),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _selectedDate != null
                                      ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                                      : isArabic
                                          ? 'اختر تاريخًا'
                                          : 'Select a date',
                                  style: TextStyle(
                                    color: _selectedDate != null
                                        ? Colors.black
                                        : Colors.grey.shade600,
                                  ),
                                ),
                                const Icon(Icons.calendar_today),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Event time picker
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isArabic ? 'وقت الحدث' : 'Event Time',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _selectTime(context),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _selectedTime != null
                                      ? '${_selectedTime!.hour}:${_selectedTime!.minute.toString().padLeft(2, '0')}'
                                      : isArabic
                                          ? 'اختر وقتًا'
                                          : 'Select a time',
                                  style: TextStyle(
                                    color: _selectedTime != null
                                        ? Colors.black
                                        : Colors.grey.shade600,
                                  ),
                                ),
                                const Icon(Icons.access_time),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Number of guests
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isArabic ? 'عدد الضيوف المتوقع' : 'Estimated Number of Guests',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Slider(
                          value: _estimatedGuests.toDouble(),
                          min: 10,
                          max: 500,
                          divisions: 49,
                          label: _estimatedGuests.toString(),
                          onChanged: (value) {
                            setState(() {
                              _estimatedGuests = value.round();
                            });
                          },
                        ),
                        Center(
                          child: Text(
                            '$_estimatedGuests ${isArabic ? 'ضيف' : 'guests'}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Questionnaire items
                    ..._questions.map((question) => _buildQuestionWidget(question, isArabic)).toList(),
                    
                    const SizedBox(height: 32),
                    
                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6A3DE8),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          isArabic ? 'تقديم الطلب' : 'Submit Request',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}