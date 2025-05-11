import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:daoob_mobile/services/auth_service.dart';
import 'package:daoob_mobile/l10n/language_provider.dart';
import 'package:daoob_mobile/providers/event_provider.dart';
import 'package:daoob_mobile/models/event_request.dart';
import 'package:daoob_mobile/models/quotation.dart';
import 'package:daoob_mobile/screens/event_selection_screen.dart';
import 'package:daoob_mobile/screens/request_details_screen.dart';

class EventRequestsScreen extends StatefulWidget {
  const EventRequestsScreen({super.key});

  @override
  State<EventRequestsScreen> createState() => _EventRequestsScreenState();
}

class _EventRequestsScreenState extends State<EventRequestsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadEventRequests();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadEventRequests() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final eventProvider = Provider.of<EventProvider>(context, listen: false);
    
    await eventProvider.loadEventRequests(authService);
    await eventProvider.loadQuotations(authService);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final eventProvider = Provider.of<EventProvider>(context);
    final authService = Provider.of<AuthService>(context);
    final bool isArabic = languageProvider.locale.languageCode == 'ar';
    
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    final hasEvents = eventProvider.eventRequests.isNotEmpty || eventProvider.quotations.isNotEmpty;
    
    if (!hasEvents) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_note,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              isArabic ? 'لا توجد طلبات أحداث' : 'No event requests yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isArabic 
                  ? 'ابدأ بإنشاء طلب لحدث جديد'
                  : 'Start by creating a new event request',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6A3DE8),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EventSelectionScreen(),
                  ),
                ).then((_) => _loadEventRequests());
              },
              child: Text(
                isArabic ? 'إنشاء طلب حدث' : 'Create Event Request'
              ),
            ),
          ],
        ),
      );
    }

    // Group requests by status
    final Map<String, List<dynamic>> requestsByStatus = {
      'pending': [],      // Pending admin review
      'quoted': [],       // Admin provided quotation
      'accepted': [],     // Client accepted quotation
      'declined': [],     // Client declined quotation
    };

    // Add event requests to the appropriate category
    for (final request in eventProvider.eventRequests) {
      // Events without quotations are pending
      final hasQuotation = eventProvider.quotations.any((q) => q.eventRequestId == request.id);
      if (!hasQuotation) {
        requestsByStatus['pending']!.add(request);
      }
    }
    
    // Add quotations to the appropriate category
    for (final quotation in eventProvider.quotations) {
      if (quotation.status == 'pending') {
        requestsByStatus['quoted']!.add(quotation);
      } else if (quotation.status == 'accepted') {
        requestsByStatus['accepted']!.add(quotation);
      } else if (quotation.status == 'declined') {
        requestsByStatus['declined']!.add(quotation);
      }
    }

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(text: isArabic ? 'قيد الانتظار' : 'Pending'),
            Tab(text: isArabic ? 'عروض أسعار' : 'Quoted'),
            Tab(text: isArabic ? 'مقبول' : 'Accepted'),
            Tab(text: isArabic ? 'مرفوض' : 'Declined'),
          ],
          labelColor: const Color(0xFF6A3DE8),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF6A3DE8),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildRequestsList(requestsByStatus['pending']!, isArabic, 'pending'),
              _buildRequestsList(requestsByStatus['quoted']!, isArabic, 'quoted'),
              _buildRequestsList(requestsByStatus['accepted']!, isArabic, 'accepted'),
              _buildRequestsList(requestsByStatus['declined']!, isArabic, 'declined'),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildRequestsList(List<dynamic> items, bool isArabic, String statusType) {
    if (items.isEmpty) {
      return Center(
        child: Text(
          isArabic ? 'لا توجد طلبات في هذه الفئة' : 'No requests in this category',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadEventRequests,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          if (statusType == 'pending') {
            return _buildEventRequestCard(context, item as EventRequest, isArabic);
          } else {
            return _buildQuotationCard(context, item as Quotation, isArabic);
          }
        },
      ),
    );
  }
  
  Widget _buildEventRequestCard(BuildContext context, EventRequest request, bool isArabic) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RequestDetailsScreen(request: request),
            ),
          ).then((_) => _loadEventRequests());
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
                  Expanded(
                    child: Text(
                      request.eventTypeName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isArabic ? 'قيد الانتظار' : 'Pending',
                      style: const TextStyle(
                        color: Colors.orange,
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
                  Expanded(
                    child: Text(
                      request.location ?? 'No location specified',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.people,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${request.guestCount} ${isArabic ? 'ضيف' : 'guests'}',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                request.description ?? (isArabic ? 'لا يوجد وصف' : 'No description'),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade800,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${isArabic ? 'تم الإرسال' : 'Submitted'}: ${_formatDate(request.createdAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
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
  
  Widget _buildQuotationCard(BuildContext context, Quotation quotation, bool isArabic) {
    // Determine status color
    Color statusColor;
    String statusText;
    
    switch (quotation.status) {
      case 'pending':
        statusColor = Colors.blue;
        statusText = isArabic ? 'عرض سعر جديد' : 'New Quote';
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

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RequestDetailsScreen(quotationId: quotation.id),
            ),
          ).then((_) => _loadEventRequests());
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
                  Expanded(
                    child: Text(
                      quotation.eventType,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
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
                    '${quotation.eventDate.day}/${quotation.eventDate.month}/${quotation.eventDate.year}',
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
                    Icons.payments_outlined,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '\$${quotation.totalPrice.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                quotation.description ?? (isArabic ? 'لا يوجد وصف' : 'No description'),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade800,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              if (quotation.status == 'pending') ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                        onPressed: () => _respondToQuotation(quotation, 'declined'),
                        child: Text(isArabic ? 'رفض' : 'Decline'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => _respondToQuotation(quotation, 'accepted'),
                        child: Text(isArabic ? 'قبول' : 'Accept'),
                      ),
                    ),
                  ],
                ),
              ],
              
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${isArabic ? 'تاريخ العرض' : 'Quoted on'}: ${_formatDate(quotation.createdAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
              if (quotation.expiryDate != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.timer,
                      size: 14,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${isArabic ? 'ينتهي في' : 'Expires on'}: ${_formatDate(quotation.expiryDate!)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: quotation.isExpired ? Colors.red : Colors.grey.shade500,
                        fontWeight: quotation.isExpired ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
  
  void _respondToQuotation(Quotation quotation, String response) async {
    final eventProvider = Provider.of<EventProvider>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final bool isArabic = languageProvider.locale.languageCode == 'ar';
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      await eventProvider.updateQuotation(
        quotation.id, 
        {'status': response},
        authService,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response == 'accepted' 
                ? (isArabic ? 'تم قبول عرض السعر' : 'Quotation accepted')
                : (isArabic ? 'تم رفض عرض السعر' : 'Quotation declined'),
            ),
            backgroundColor: response == 'accepted' ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isArabic 
                ? 'خطأ: فشل تحديث عرض السعر' 
                : 'Error: Failed to update quotation',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        _loadEventRequests();
      }
    }
  }
}