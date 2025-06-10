import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/quotation.dart';
import '../models/event_request.dart';
import '../config/api_config.dart';
import '../services/auth_service.dart';
import '../l10n/language_provider.dart';

class QuotationDetailScreen extends StatefulWidget {
  final Quotation quotation;
  final EventRequest? eventRequest;

  const QuotationDetailScreen({
    Key? key,
    required this.quotation,
    this.eventRequest,
  }) : super(key: key);

  @override
  _QuotationDetailScreenState createState() => _QuotationDetailScreenState();
}

class _QuotationDetailScreenState extends State<QuotationDetailScreen> {
  bool _isLoading = false;
  String? _error;

  Future<void> _updateQuotationStatus(String status) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      final response = await authService.apiService.patch(
        '${ApiConfig.quotationsEndpoint}/${widget.quotation.id}',
        {'status': status},
      );

      if (response.statusCode == 200) {
        // Show success message and navigate back
        if (mounted) {
          final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
          final bool isArabic = languageProvider.locale.languageCode == 'ar';
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                status == 'accepted'
                    ? (isArabic ? 'تم قبول العرض بنجاح!' : 'Quotation accepted successfully!')
                    : (isArabic ? 'تم رفض العرض' : 'Quotation declined'),
              ),
              backgroundColor: status == 'accepted' ? Colors.green : Colors.orange,
            ),
          );
          
          Navigator.of(context).pop(true); // Return true to indicate status changed
        }
      } else {
        setState(() {
          _error = 'Failed to update quotation status. Please try again.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Network error: $e';
        _isLoading = false;
      });
    }
  }

  void _showConfirmationDialog(String action) {
    final languageProvider = Provider.of<LanguageProvider>(context, listen: false);
    final bool isArabic = languageProvider.locale.languageCode == 'ar';
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            action == 'accept'
                ? (isArabic ? 'تأكيد قبول العرض' : 'Confirm Accept')
                : (isArabic ? 'تأكيد رفض العرض' : 'Confirm Decline'),
          ),
          content: Text(
            action == 'accept'
                ? (isArabic 
                    ? 'هل أنت متأكد من قبول هذا العرض؟ لا يمكن التراجع عن هذا الإجراء.'
                    : 'Are you sure you want to accept this quotation? This action cannot be undone.')
                : (isArabic 
                    ? 'هل أنت متأكد من رفض هذا العرض؟'
                    : 'Are you sure you want to decline this quotation?'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(isArabic ? 'إلغاء' : 'Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _updateQuotationStatus(action == 'accept' ? 'accepted' : 'declined');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: action == 'accept' ? Colors.green : Colors.red,
              ),
              child: Text(
                action == 'accept'
                    ? (isArabic ? 'قبول' : 'Accept')
                    : (isArabic ? 'رفض' : 'Decline'),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(symbol: '\$', decimalDigits: 0).format(amount);
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Not specified';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return 'Invalid date';
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final bool isArabic = languageProvider.locale.languageCode == 'ar';
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isArabic ? 'تفاصيل العرض' : 'Quotation Details',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF6A3DE8),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Error message
                  if (_error != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        border: Border.all(color: Colors.red.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error, color: Colors.red.shade600),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: TextStyle(color: Colors.red.shade800),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Main quotation card
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header with total amount
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isArabic ? 'المبلغ الإجمالي' : 'Total Amount',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                _formatCurrency(widget.quotation.totalAmount),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF6A3DE8),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // Status
                          Row(
                            children: [
                              Text(
                                isArabic ? 'الحالة: ' : 'Status: ',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor().withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: _getStatusColor().withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  _getStatusText(isArabic),
                                  style: TextStyle(
                                    color: _getStatusColor(),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Expiry date
                          if (widget.quotation.expiryDate != null)
                            Row(
                              children: [
                                Icon(
                                  Icons.schedule,
                                  size: 18,
                                  color: Colors.grey.shade600,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isArabic ? 'صالح حتى: ' : 'Valid until: ',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                Text(
                                  _formatDate(widget.quotation.expiryDate),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Description
                  if (widget.quotation.description != null && 
                      widget.quotation.description!.isNotEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isArabic ? 'الوصف' : 'Description',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.quotation.description!,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 16),
                  
                  // Breakdown if available
                  if (widget.quotation.breakdown != null &&
                      widget.quotation.breakdown!.isNotEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isArabic ? 'تفصيل الأسعار' : 'Price Breakdown',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...widget.quotation.breakdown!.entries.map(
                              (entry) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      entry.key,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    Text(
                                      _formatCurrency(entry.value.toDouble()),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 24),
                  
                  // Action buttons (only show if status is pending)
                  if (widget.quotation.status == 'quotation_sent' || 
                      widget.quotation.status == 'pending')
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _showConfirmationDialog('decline'),
                            icon: const Icon(Icons.close, color: Colors.white),
                            label: Text(
                              isArabic ? 'رفض' : 'Decline',
                              style: const TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _showConfirmationDialog('accept'),
                            icon: const Icon(Icons.check, color: Colors.white),
                            label: Text(
                              isArabic ? 'قبول' : 'Accept',
                              style: const TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
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

  Color _getStatusColor() {
    switch (widget.quotation.status) {
      case 'accepted':
        return Colors.green;
      case 'declined':
        return Colors.red;
      case 'quotation_sent':
      case 'pending':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(bool isArabic) {
    switch (widget.quotation.status) {
      case 'accepted':
        return isArabic ? 'مقبول' : 'Accepted';
      case 'declined':
        return isArabic ? 'مرفوض' : 'Declined';
      case 'quotation_sent':
        return isArabic ? 'في انتظار الرد' : 'Awaiting Response';
      case 'pending':
        return isArabic ? 'قيد المراجعة' : 'Pending';
      default:
        return widget.quotation.status;
    }
  }
}