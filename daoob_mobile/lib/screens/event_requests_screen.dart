import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:daoob_mobile/l10n/language_provider.dart';
import 'package:daoob_mobile/providers/event_provider.dart';
import 'package:daoob_mobile/services/auth_service.dart';
import 'package:daoob_mobile/models/event_request.dart';
import 'package:daoob_mobile/models/quotation.dart';
import 'package:daoob_mobile/screens/request_detail_screen.dart';

class EventRequestsScreen extends StatefulWidget {
  const EventRequestsScreen({super.key});

  @override
  State<EventRequestsScreen> createState() => _EventRequestsScreenState();
}

class _EventRequestsScreenState extends State<EventRequestsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  List<EventRequest> _eventRequests = [];
  List<Quotation> _quotations = [];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final eventProvider = Provider.of<EventProvider>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      
      if (authService.user == null) {
        print('User not authenticated');
        setState(() {
          _isLoading = false;
          _eventRequests = [];
          _quotations = [];
        });
        return;
      }
      
      // Get API configuration
      final apiConfig = await authService.getApiConfig();
      final token = await authService.getToken();
      final userId = authService.user!.id;
      
      // Fetch event requests from API
      final requestsUrl = '${apiConfig.baseUrl}/api/event-requests/client/$userId';
      
      final requestsResponse = await http.get(
        Uri.parse(requestsUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      List<EventRequest> loadedRequests = [];
      
      if (requestsResponse.statusCode == 200) {
        final List<dynamic> requestsJson = jsonDecode(requestsResponse.body);
        loadedRequests = requestsJson
            .map((json) => EventRequest.fromJson(json))
            .toList();
      } else {
        print('Error loading event requests: ${requestsResponse.statusCode}');
      }
      
      // Fetch quotations from API
      final quotationsUrl = '${apiConfig.baseUrl}/api/quotations/client/$userId';
      
      final quotationsResponse = await http.get(
        Uri.parse(quotationsUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      List<Quotation> loadedQuotations = [];
      
      if (quotationsResponse.statusCode == 200) {
        final List<dynamic> quotationsJson = jsonDecode(quotationsResponse.body);
        loadedQuotations = quotationsJson
            .map((json) => Quotation.fromJson(json))
            .toList();
      } else {
        print('Error loading quotations: ${quotationsResponse.statusCode}');
      }
      
      setState(() {
        _eventRequests = loadedRequests;
        _quotations = loadedQuotations;
        _isLoading = false;
      });
    } catch (e) {
      print('Exception while loading data: $e');
      setState(() {
        _isLoading = false;
        _eventRequests = [];
        _quotations = [];
      });
    }
  }
  
  // Removed _getSampleEventRequests method as we now fetch data from the API
  
  // Removed _getSampleQuotations method as we now fetch data from the API
  
  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final bool isArabic = languageProvider.locale.languageCode == 'ar';
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isArabic ? 'طلبات الحدث' : 'Event Requests',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF6A3DE8),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          tabs: [
            Tab(text: isArabic ? 'الطلبات' : 'Requests'),
            Tab(text: isArabic ? 'عروض الأسعار' : 'Quotations'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Event Requests Tab
                _eventRequests.isEmpty
                    ? _buildEmptyState(
                        isArabic ? 'لا توجد طلبات حتى الآن' : 'No requests yet',
                        isArabic ? 'قم بإنشاء طلب حدث جديد من الشاشة الرئيسية' : 'Create a new event request from the home screen',
                        Icons.event_note,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _eventRequests.length,
                        itemBuilder: (context, index) {
                          return _buildEventRequestCard(_eventRequests[index], isArabic);
                        },
                      ),
                
                // Quotations Tab
                _quotations.isEmpty
                    ? _buildEmptyState(
                        isArabic ? 'لا توجد عروض أسعار حتى الآن' : 'No quotations yet',
                        isArabic ? 'سيقوم المسؤول بإرسال عروض الأسعار بعد مراجعة طلباتك' : 'Admin will send quotations after reviewing your requests',
                        Icons.request_quote,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _quotations.length,
                        itemBuilder: (context, index) {
                          return _buildQuotationCard(_quotations[index], isArabic);
                        },
                      ),
              ],
            ),
    );
  }
  
  Widget _buildEmptyState(String title, String message, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEventRequestCard(EventRequest request, bool isArabic) {
    Color statusColor;
    String statusText;
    
    // Set status color and text
    switch (request.status) {
      case 'pending':
        statusColor = Colors.orange;
        statusText = isArabic ? 'قيد الانتظار' : 'Pending';
        break;
      case 'quoted':
        statusColor = Colors.blue;
        statusText = isArabic ? 'تم التسعير' : 'Quoted';
        break;
      case 'accepted':
        statusColor = Colors.green;
        statusText = isArabic ? 'مقبول' : 'Accepted';
        break;
      case 'canceled':
        statusColor = Colors.red;
        statusText = isArabic ? 'ملغى' : 'Canceled';
        break;
      default:
        statusColor = Colors.grey;
        statusText = request.status;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          // Navigate to request detail
          // Navigator.push(
          //   context,
          //   MaterialPageRoute(
          //     builder: (context) => RequestDetailScreen(requestId: request.id),
          //   ),
          // );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    request.details['eventType'] as String? ?? 'Event',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.event,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${request.eventDate.day}/${request.eventDate.month}/${request.eventDate.year}',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.people,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    (request.details['estimatedGuests'] as int?)?.toString() ?? '0',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    (request.details['location'] as String?) ?? 'Unknown location',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isArabic
                        ? 'تم إنشاؤه ${_getTimeAgo(request.createdAt, isArabic)}'
                        : 'Created ${_getTimeAgo(request.createdAt, isArabic)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  Text(
                    isArabic ? 'عرض التفاصيل' : 'View Details',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6A3DE8),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildQuotationCard(Quotation quotation, bool isArabic) {
    Color statusColor;
    String statusText;
    
    // Set status color and text
    switch (quotation.status) {
      case 'pending':
        statusColor = Colors.blue;
        statusText = isArabic ? 'قيد المراجعة' : 'Pending';
        break;
      case 'accepted':
        statusColor = Colors.green;
        statusText = isArabic ? 'مقبول' : 'Accepted';
        break;
      case 'declined':
        statusColor = Colors.red;
        statusText = isArabic ? 'مرفوض' : 'Declined';
        break;
      default:
        statusColor = Colors.grey;
        statusText = quotation.status;
    }
    
    // Find corresponding event request
    final eventRequest = _eventRequests.firstWhere(
      (request) => request.id == quotation.eventRequestId,
      orElse: () => EventRequest(
        id: 0,
        clientId: 0,
        eventTypeId: 0,
        status: 'unknown',
        eventDate: DateTime.now(),
        createdAt: DateTime.now(),
        details: {'eventType': 'Unknown Event'},
      ),
    );
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: InkWell(
        onTap: () {
          // Navigate to quotation detail (not implemented yet)
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    eventRequest.details['eventType'] as String? ?? 'Event',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isArabic ? 'المبلغ الإجمالي' : 'Total Amount',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '\$${quotation.totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Color(0xFF6A3DE8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${quotation.items.length} ${isArabic ? 'عناصر' : 'items'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${eventRequest.eventDate.day}/${eventRequest.eventDate.month}/${eventRequest.eventDate.year}',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isArabic
                        ? 'تم إنشاؤه ${_getTimeAgo(quotation.createdAt, isArabic)}'
                        : 'Created ${_getTimeAgo(quotation.createdAt, isArabic)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  if (quotation.status == 'pending')
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            // Accept quotation
                          },
                          icon: const Icon(Icons.check, size: 16),
                          label: Text(isArabic ? 'قبول' : 'Accept'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                            minimumSize: const Size(60, 28),
                            textStyle: const TextStyle(fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () {
                            // Decline quotation
                          },
                          icon: const Icon(Icons.close, size: 16),
                          label: Text(isArabic ? 'رفض' : 'Decline'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                            minimumSize: const Size(60, 28),
                            textStyle: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  String _getTimeAgo(DateTime dateTime, bool isArabic) {
    final difference = DateTime.now().difference(dateTime);
    
    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inDays > 0) {
      return isArabic
          ? '${difference.inDays} يوم مضى'
          : '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return isArabic
          ? '${difference.inHours} ساعة مضت'
          : '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return isArabic
          ? '${difference.inMinutes} دقيقة مضت'
          : '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return isArabic ? 'الآن' : 'just now';
    }
  }
}