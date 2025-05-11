import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:daoob_mobile/models/event_request.dart';
import 'package:daoob_mobile/models/quotation.dart';
import 'package:daoob_mobile/providers/event_provider.dart';
import 'package:daoob_mobile/services/auth_service.dart';
import 'package:daoob_mobile/l10n/language_provider.dart';

class RequestDetailsScreen extends StatefulWidget {
  final EventRequest? request;
  final int? quotationId;

  const RequestDetailsScreen({
    Key? key,
    this.request,
    this.quotationId,
  }) : super(key: key);

  @override
  _RequestDetailsScreenState createState() => _RequestDetailsScreenState();
}

class _RequestDetailsScreenState extends State<RequestDetailsScreen> {
  bool _isLoading = true;
  EventRequest? _request;
  Quotation? _quotation;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final eventProvider = Provider.of<EventProvider>(context, listen: false);

      if (widget.quotationId != null) {
        // Load quotation and its associated request
        final quotation = await eventProvider.getQuotationById(
          widget.quotationId!,
          authService,
        );
        
        if (quotation != null) {
          final request = await eventProvider.getEventRequestById(
            quotation.eventRequestId,
            authService,
          );
          
          setState(() {
            _quotation = quotation;
            _request = request;
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = 'Quotation not found';
            _isLoading = false;
          });
        }
      } else if (widget.request != null) {
        // Check if there's a quotation for this request
        final quotations = await eventProvider.getQuotationsByRequestId(
          widget.request!.id,
          authService,
        );
        
        setState(() {
          _request = widget.request;
          _quotation = quotations.isNotEmpty ? quotations.first : null;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'No request or quotation provided';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading data: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final bool isArabic = languageProvider.locale.languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isArabic ? 'تفاصيل الطلب' : 'Request Details',
          style: TextStyle(fontFamily: isArabic ? 'Almarai' : 'Roboto'),
        ),
      ),
      body: _buildBody(isArabic),
    );
  }

  Widget _buildBody(bool isArabic) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _error!,
              style: TextStyle(color: Colors.red[700]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: Text(isArabic ? 'إعادة المحاولة' : 'Try Again'),
            ),
          ],
        ),
      );
    }

    if (_request == null) {
      return Center(
        child: Text(
          isArabic ? 'لم يتم العثور على الطلب' : 'Request not found',
          style: const TextStyle(fontSize: 16),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRequestCard(isArabic),
          if (_quotation != null) ...[
            const SizedBox(height: 24),
            _buildQuotationCard(isArabic),
          ],
        ],
      ),
    );
  }

  Widget _buildRequestCard(bool isArabic) {
    final request = _request!;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isArabic ? 'تفاصيل الطلب' : 'Request Details',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            _buildInfoRow(
              isArabic ? 'نوع الحدث' : 'Event Type',
              request.eventTypeName,
              Icons.celebration,
              isArabic,
            ),
            _buildInfoRow(
              isArabic ? 'تاريخ الحدث' : 'Event Date',
              '${request.eventDate.day}/${request.eventDate.month}/${request.eventDate.year}',
              Icons.calendar_today,
              isArabic,
            ),
            _buildInfoRow(
              isArabic ? 'الموقع' : 'Location',
              request.location ?? (isArabic ? 'غير محدد' : 'Not specified'),
              Icons.location_on,
              isArabic,
            ),
            _buildInfoRow(
              isArabic ? 'عدد الضيوف' : 'Guest Count',
              request.guestCount.toString(),
              Icons.people,
              isArabic,
            ),
            if (request.budget != null)
              _buildInfoRow(
                isArabic ? 'الميزانية' : 'Budget',
                '\$${request.budget!.toStringAsFixed(2)}',
                Icons.attach_money,
                isArabic,
              ),
            const SizedBox(height: 16),
            Text(
              isArabic ? 'الوصف' : 'Description',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              request.description ?? (isArabic ? 'لا يوجد وصف' : 'No description provided'),
              style: TextStyle(
                color: request.description == null ? Colors.grey : null,
              ),
            ),
            
            if (request.responses != null && request.responses!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                isArabic ? 'الإجابات على الأسئلة' : 'Questionnaire Responses',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...request.responses!.entries.map((entry) => 
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.key,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        entry.value.toString(),
                        style: TextStyle(
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                )
              ).toList(),
            ],
            
            const Divider(),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Text(
                  '${isArabic ? 'تم الإرسال' : 'Submitted'}: ${_formatDate(request.createdAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuotationCard(bool isArabic) {
    final quotation = _quotation!;
    
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
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isArabic ? 'عرض السعر' : 'Quotation',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
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
            const Divider(),
            _buildInfoRow(
              isArabic ? 'السعر الإجمالي' : 'Total Price',
              '\$${quotation.totalPrice.toStringAsFixed(2)}',
              Icons.payments_outlined,
              isArabic,
              emphasize: true,
            ),
            const SizedBox(height: 16),
            Text(
              isArabic ? 'الوصف' : 'Description',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              quotation.description ?? (isArabic ? 'لا يوجد وصف' : 'No description provided'),
              style: TextStyle(
                color: quotation.description == null ? Colors.grey : null,
              ),
            ),
            
            if (quotation.includedServices != null && 
                quotation.includedServices!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                isArabic ? 'الخدمات المشمولة' : 'Included Services',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...quotation.includedServices!.map((service) => 
                Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, size: 16, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(service),
                    ],
                  ),
                )
              ).toList(),
            ],
            
            if (quotation.vendorDetails != null) ...[
              const SizedBox(height: 16),
              Text(
                isArabic ? 'تفاصيل مزود الخدمة' : 'Vendor Details',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...quotation.vendorDetails!.entries.map((entry) => 
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.key,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        entry.value.toString(),
                        style: TextStyle(
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                )
              ).toList(),
            ],
            
            if (quotation.status == 'pending') ...[
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                      onPressed: () => _respondToQuotation('declined'),
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
                      onPressed: () => _respondToQuotation('accepted'),
                      child: Text(isArabic ? 'قبول' : 'Accept'),
                    ),
                  ),
                ],
              ),
            ],
            
            const Divider(),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 8),
                Text(
                  '${isArabic ? 'تاريخ العرض' : 'Quoted on'}: ${_formatDate(quotation.createdAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
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
                    size: 16,
                    color: quotation.isExpired ? Colors.red : Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${isArabic ? 'ينتهي في' : 'Expires on'}: ${_formatDate(quotation.expiryDate!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: quotation.isExpired ? Colors.red : Colors.grey[600],
                      fontWeight: quotation.isExpired ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    IconData icon,
    bool isArabic, {
    bool emphasize = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: emphasize ? 16 : 14,
                    fontWeight: emphasize ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
  
  void _respondToQuotation(String response) async {
    if (_quotation == null) return;
    
    final eventProvider = Provider.of<EventProvider>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final bool isArabic = languageProvider.locale.languageCode == 'ar';
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      await eventProvider.updateQuotation(
        _quotation!.id, 
        {'status': response},
        authService,
      );
      
      await _loadData();
      
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
      setState(() {
        _isLoading = false;
      });
      
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
    }
  }
}