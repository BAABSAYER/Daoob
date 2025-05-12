import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:daoob_mobile/l10n/language_provider.dart';
import 'package:daoob_mobile/providers/event_provider.dart';
import 'package:daoob_mobile/services/auth_service.dart';
import 'package:daoob_mobile/models/event_category.dart';
import 'package:daoob_mobile/models/questionnaire_item.dart';
import 'package:daoob_mobile/screens/request_confirmation_screen.dart';

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
    _loadQuestions();
  }
  
  Future<void> _loadQuestions() async {
    try {
      final eventProvider = Provider.of<EventProvider>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      
      // Set the current category
      eventProvider.selectCategory(widget.categoryId);
      
      // In a real app, we would load event types from API
      // and get questionnaire items for this specific category
      // For demo purposes, we'll create sample questions
      setState(() {
        _questions = _generateSampleQuestions(widget.categoryId);
        _isLoading = false;
      });
    } catch (e) {
      // Handle error
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<QuestionnaireItem> _generateSampleQuestions(String categoryId) {
    // Generate different questions based on event category
    if (categoryId == 'wedding') {
      return [
        QuestionnaireItem(
          id: 1,
          eventTypeId: 1,
          questionText: 'What style of wedding are you planning?',
          answerType: 'select',
          options: ['Traditional', 'Modern', 'Beach', 'Garden', 'Destination'],
          isRequired: true,
          orderIndex: 1,
        ),
        QuestionnaireItem(
          id: 2,
          eventTypeId: 1,
          questionText: 'Do you need catering services?',
          answerType: 'boolean',
          isRequired: true,
          orderIndex: 2,
        ),
        QuestionnaireItem(
          id: 3,
          eventTypeId: 1,
          questionText: 'Any special requirements or details?',
          answerType: 'text',
          isRequired: false,
          orderIndex: 3,
        ),
      ];
    } else if (categoryId == 'corporate') {
      return [
        QuestionnaireItem(
          id: 4,
          eventTypeId: 2,
          questionText: 'What type of corporate event?',
          answerType: 'select',
          options: ['Conference', 'Team Building', 'Product Launch', 'Seminar', 'Executive Retreat'],
          isRequired: true,
          orderIndex: 1,
        ),
        QuestionnaireItem(
          id: 5,
          eventTypeId: 2,
          questionText: 'Will you need presentation equipment?',
          answerType: 'boolean',
          isRequired: true,
          orderIndex: 2,
        ),
        QuestionnaireItem(
          id: 6,
          eventTypeId: 2,
          questionText: 'Any specific industry or theme?',
          answerType: 'text',
          isRequired: false,
          orderIndex: 3,
        ),
      ];
    } else if (categoryId == 'birthday') {
      return [
        QuestionnaireItem(
          id: 7,
          eventTypeId: 3,
          questionText: 'Age of the birthday person?',
          answerType: 'number',
          isRequired: true,
          orderIndex: 1,
        ),
        QuestionnaireItem(
          id: 8,
          eventTypeId: 3,
          questionText: 'Theme preference?',
          answerType: 'select',
          options: ['Classic', 'Cartoon/Character', 'Sports', 'Hobby', 'Surprise'],
          isRequired: false,
          orderIndex: 2,
        ),
        QuestionnaireItem(
          id: 9,
          eventTypeId: 3,
          questionText: 'Will you need entertainment?',
          answerType: 'boolean',
          isRequired: true,
          orderIndex: 3,
        ),
      ];
    } else {
      // Default questions for other categories
      return [
        QuestionnaireItem(
          id: 10,
          eventTypeId: 4,
          questionText: 'Please describe your event',
          answerType: 'text',
          isRequired: true,
          orderIndex: 1,
        ),
        QuestionnaireItem(
          id: 11,
          eventTypeId: 4,
          questionText: 'Do you have a specific venue in mind?',
          answerType: 'text',
          isRequired: false,
          orderIndex: 2,
        ),
        QuestionnaireItem(
          id: 12,
          eventTypeId: 4,
          questionText: 'Will you need catering services?',
          answerType: 'boolean',
          isRequired: true,
          orderIndex: 3,
        ),
      ];
    }
  }
  
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
      
      if (_selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an event date')),
        );
        return;
      }
      
      // Create the request data
      final requestData = {
        'categoryId': widget.categoryId,
        'answers': _answers,
        'eventDate': '${_selectedDate!.toIso8601String()}',
        'eventTime': _selectedTime != null 
            ? '${_selectedTime!.hour}:${_selectedTime!.minute}' 
            : null,
        'estimatedGuests': _estimatedGuests,
        'status': 'pending',
      };
      
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