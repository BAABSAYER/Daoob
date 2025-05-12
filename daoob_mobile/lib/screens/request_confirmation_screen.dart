import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:daoob_mobile/l10n/language_provider.dart';
import 'package:daoob_mobile/providers/event_provider.dart';
import 'package:daoob_mobile/services/auth_service.dart';

class RequestConfirmationScreen extends StatefulWidget {
  final Map<String, dynamic> requestData;
  
  const RequestConfirmationScreen({super.key, required this.requestData});

  @override
  State<RequestConfirmationScreen> createState() => _RequestConfirmationScreenState();
}

class _RequestConfirmationScreenState extends State<RequestConfirmationScreen> {
  bool _isSubmitting = false;
  String? _error;
  bool _isSuccess = false;
  
  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final eventProvider = Provider.of<EventProvider>(context);
    final authService = Provider.of<AuthService>(context);
    final bool isArabic = languageProvider.locale.languageCode == 'ar';
    final category = eventProvider.getCategoryById(widget.requestData['categoryId']);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isArabic ? 'تأكيد الطلب' : 'Confirm Request',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF6A3DE8),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isSuccess
          ? _buildSuccessView(isArabic)
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isArabic
                        ? 'مراجعة تفاصيل طلبك'
                        : 'Review Your Request Details',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Event category
                  _buildInfoRow(
                    isArabic ? 'نوع الحدث' : 'Event Type',
                    category?.name ?? widget.requestData['categoryId'],
                    Icons.category,
                  ),
                  const Divider(),
                  
                  // Event date
                  _buildInfoRow(
                    isArabic ? 'تاريخ الحدث' : 'Event Date',
                    DateTime.parse(widget.requestData['eventDate']).toString().substring(0, 10),
                    Icons.calendar_today,
                  ),
                  const Divider(),
                  
                  // Event time (if provided)
                  if (widget.requestData['eventTime'] != null) ...[
                    _buildInfoRow(
                      isArabic ? 'وقت الحدث' : 'Event Time',
                      widget.requestData['eventTime'],
                      Icons.access_time,
                    ),
                    const Divider(),
                  ],
                  
                  // Estimated guests
                  _buildInfoRow(
                    isArabic ? 'عدد الضيوف المتوقع' : 'Estimated Guests',
                    widget.requestData['estimatedGuests'].toString(),
                    Icons.people,
                  ),
                  const Divider(),
                  
                  // Answers summary (simplified for demo)
                  const SizedBox(height: 16),
                  Text(
                    isArabic ? 'إجاباتك' : 'Your Answers',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'You have provided ${(widget.requestData['answers'] as Map).length} answers to the questionnaire.',
                      style: const TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ),
                  
                  if (_error != null) ...[
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error,
                            color: Colors.red.shade700,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: TextStyle(
                                color: Colors.red.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 32),
                  
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSubmitting
                              ? null
                              : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: Colors.grey.shade400),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            isArabic ? 'رجوع وتعديل' : 'Go Back & Edit',
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isSubmitting
                              ? null
                              : _submitRequest,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6A3DE8),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 3,
                                  ),
                                )
                              : Text(
                                  isArabic ? 'تقديم الطلب' : 'Submit Request',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
  
  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Colors.grey.shade700,
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildSuccessView(bool isArabic) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle,
              color: Color(0xFF6A3DE8),
              size: 80,
            ),
            const SizedBox(height: 24),
            Text(
              isArabic
                  ? 'تم تقديم طلبك بنجاح!'
                  : 'Your request has been submitted successfully!',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              isArabic
                  ? 'سيقوم فريقنا بمراجعة طلبك وسنتواصل معك قريبًا بخصوص عرض الأسعار.'
                  : 'Our team will review your request and we will contact you soon with a quotation.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6A3DE8),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                isArabic ? 'العودة إلى الرئيسية' : 'Return to Home',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _submitRequest() async {
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    
    try {
      final eventProvider = Provider.of<EventProvider>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      
      // Add client info to request
      final completeRequestData = {
        ...widget.requestData,
        'clientId': authService.user?.id,
        'clientName': authService.user?.name,
        'clientEmail': authService.user?.email,
        'clientPhone': authService.user?.phone,
      };
      
      // Simulate API call with a delay
      await Future.delayed(const Duration(seconds: 2));
      
      // In a real app, we would call the API
      // await eventProvider.submitEventRequest(completeRequestData, authService);
      
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _isSuccess = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _error = e.toString();
        });
      }
    }
  }
}