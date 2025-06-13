import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/event_type.dart';
import '../models/questionnaire_item.dart';
import '../config/api_config.dart';
import '../services/auth_service.dart';
import 'request_submitted_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EventQuestionnaireScreen extends StatefulWidget {
  final EventType eventType;

  const EventQuestionnaireScreen({Key? key, required this.eventType}) : super(key: key);

  @override
  _EventQuestionnaireScreenState createState() => _EventQuestionnaireScreenState();
}

class _EventQuestionnaireScreenState extends State<EventQuestionnaireScreen> {
  List<QuestionnaireItem> _questions = [];
  bool _isLoading = true;
  String? _error;
  
  // Store responses
  final Map<int, dynamic> _responses = {};
  DateTime? _eventDate;
  double? _budget;
  final TextEditingController _specialRequestsController = TextEditingController();
  
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  @override
  void initState() {
    super.initState();
    _fetchQuestionnaireItems();
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    _specialRequestsController.dispose();
    super.dispose();
  }
  
  Future<void> _fetchQuestionnaireItems() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      final response = await http.get(
        Uri.parse('${ApiConfig.apiUrl}/questionnaire-items/${widget.eventType.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Cookie': authService.sessionCookie ?? '',
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _questions = data.map((item) => QuestionnaireItem.fromJson(item)).toList();
          _isLoading = false;
        });
      } else if (response.statusCode == 401) {
        // Session expired, redirect to login
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        }
      } else {
        setState(() {
          _error = 'Failed to load questionnaire: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Network error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }
  
  Future<void> _submitEventRequest() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    // Prepare the request data
    final requestData = {
      'event_type_id': widget.eventType.id,
      'event_date': _eventDate?.toIso8601String(),
      'budget': _budget,
      'special_requests': _specialRequestsController.text,
      'questionnaire_responses': _responses,
      'status': 'pending',
    };
    
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.apiUrl}/bookings'),
        headers: {
          'Content-Type': 'application/json',
          'Cookie': authService.sessionCookie ?? '',
        },
        body: json.encode(requestData),
      );
      
      if (response.statusCode == 201) {
        // Success - navigate to confirmation screen
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => RequestSubmittedScreen(
                eventType: widget.eventType,
                submittedData: requestData,
              ),
            ),
          );
        }
      } else if (response.statusCode == 401) {
        // Session expired
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        }
      } else {
        // Handle error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to submit request: ${response.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Network error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Widget _buildQuestionWidget(QuestionnaireItem question) {
    switch (question.type) {
      case 'text':
        return TextFormField(
          decoration: InputDecoration(
            labelText: question.question,
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            _responses[question.id] = value;
          },
          validator: question.required ? (value) {
            if (value == null || value.isEmpty) {
              return 'This field is required';
            }
            return null;
          } : null,
        );
        
      case 'number':
        return TextFormField(
          decoration: InputDecoration(
            labelText: question.question,
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            _responses[question.id] = double.tryParse(value) ?? 0;
          },
          validator: question.required ? (value) {
            if (value == null || value.isEmpty) {
              return 'This field is required';
            }
            return null;
          } : null,
        );
        
      case 'select':
        return DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: question.question,
            border: OutlineInputBorder(),
          ),
          items: question.options?.map((option) {
            return DropdownMenuItem<String>(
              value: option,
              child: Text(option),
            );
          }).toList() ?? [],
          onChanged: (value) {
            _responses[question.id] = value;
          },
          validator: question.required ? (value) {
            if (value == null || value.isEmpty) {
              return 'Please select an option';
            }
            return null;
          } : null,
        );
        
      default:
        return TextFormField(
          decoration: InputDecoration(
            labelText: question.question,
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            _responses[question.id] = value;
          },
        );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.eventType.name} - Questionnaire'),
        backgroundColor: Colors.orange,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _error!,
                        style: TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchQuestionnaireItems,
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Event Information',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      SizedBox(height: 16),
                      
                      // Event Date
                      ListTile(
                        title: Text('Event Date'),
                        subtitle: Text(_eventDate != null 
                            ? DateFormat('yyyy-MM-dd').format(_eventDate!)
                            : 'Select date'),
                        trailing: Icon(Icons.calendar_today),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(Duration(days: 365)),
                          );
                          if (date != null) {
                            setState(() {
                              _eventDate = date;
                            });
                          }
                        },
                      ),
                      
                      SizedBox(height: 16),
                      
                      // Budget
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Budget (optional)',
                          border: OutlineInputBorder(),
                          prefixText: '\$',
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          _budget = double.tryParse(value);
                        },
                      ),
                      
                      SizedBox(height: 24),
                      
                      // Questions
                      if (_questions.isNotEmpty) ...[
                        Text(
                          'Event Details',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        SizedBox(height: 16),
                        
                        ..._questions.map((question) => Padding(
                          padding: EdgeInsets.only(bottom: 16),
                          child: _buildQuestionWidget(question),
                        )).toList(),
                      ],
                      
                      SizedBox(height: 16),
                      
                      // Special Requests
                      TextFormField(
                        controller: _specialRequestsController,
                        decoration: InputDecoration(
                          labelText: 'Special Requests (optional)',
                          border: OutlineInputBorder(),
                          hintText: 'Any special requirements or notes...',
                        ),
                        maxLines: 3,
                      ),
                      
                      SizedBox(height: 32),
                      
                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _eventDate != null ? _submitEventRequest : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            padding: EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            'Submit Event Request',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}