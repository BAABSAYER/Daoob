import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/event_request.dart';
import '../models/quotation.dart';
import '../services/auth_service.dart';
import '../config/api_config.dart';
import '../l10n/language_provider.dart';
import 'quotation_detail_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RequestDetailScreen extends StatefulWidget {
  final EventRequest eventRequest;

  const RequestDetailScreen({Key? key, required this.eventRequest}) : super(key: key);

  @override
  _RequestDetailScreenState createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  List<Quotation> _quotations = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadQuotations();
  }

  Future<void> _loadQuotations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      final response = await authService.apiService.get(
        '${ApiConfig.apiUrl}/quotations/request/${widget.eventRequest.id}',
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _quotations = data.map((item) => Quotation.fromJson(item)).toList();
          _isLoading = false;
        });
      } else if (response.statusCode == 401) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      } else {
        setState(() {
          _error = 'Failed to load quotations';
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status, bool isArabic) {
    switch (status.toLowerCase()) {
      case 'pending':
        return isArabic ? 'في الانتظار' : 'Pending';
      case 'approved':
        return isArabic ? 'موافق عليه' : 'Approved';
      case 'rejected':
        return isArabic ? 'مرفوض' : 'Rejected';
      case 'completed':
        return isArabic ? 'مكتمل' : 'Completed';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final bool isArabic = languageProvider.locale.languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'تفاصيل الطلب' : 'Request Details'),
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Request Info Card
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isArabic ? 'معلومات الطلب' : 'Request Information',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getStatusColor(widget.eventRequest.status),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _getStatusText(widget.eventRequest.status, isArabic),
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    
                    _buildInfoRow(
                      isArabic ? 'رقم الطلب:' : 'Request ID:',
                      '#${widget.eventRequest.id}',
                      isArabic,
                    ),
                    
                    _buildInfoRow(
                      isArabic ? 'تاريخ الحدث:' : 'Event Date:',
                      DateFormat('yyyy-MM-dd').format(widget.eventRequest.eventDate),
                      isArabic,
                    ),
                    
                    _buildInfoRow(
                      isArabic ? 'تاريخ الإنشاء:' : 'Created Date:',
                      DateFormat('yyyy-MM-dd HH:mm').format(widget.eventRequest.createdAt),
                      isArabic,
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 16),
            
            // Event Details Card
            if (widget.eventRequest.details.isNotEmpty)
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isArabic ? 'تفاصيل الحدث' : 'Event Details',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      
                      ...widget.eventRequest.details.entries.map((entry) {
                        return _buildInfoRow(
                          '${entry.key}:',
                          entry.value.toString(),
                          isArabic,
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
            
            SizedBox(height: 16),
            
            // Quotations Section
            Text(
              isArabic ? 'العروض المالية' : 'Quotations',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            
            if (_isLoading)
              Center(child: CircularProgressIndicator())
            else if (_error != null)
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        _error!,
                        style: TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _loadQuotations,
                        child: Text(isArabic ? 'إعادة المحاولة' : 'Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else if (_quotations.isEmpty)
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(
                        Icons.receipt_long,
                        size: 48,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 8),
                      Text(
                        isArabic ? 'لا توجد عروض مالية بعد' : 'No quotations yet',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        isArabic 
                            ? 'سيتم إرسال العرض المالي قريباً'
                            : 'A quotation will be sent soon',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...(_quotations.map((quotation) => Card(
                margin: EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(
                    Icons.receipt_long,
                    color: Colors.orange,
                  ),
                  title: Text(
                    isArabic ? 'عرض مالي' : 'Quotation',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${isArabic ? 'السعر:' : 'Price:'} \$${quotation.totalPrice.toStringAsFixed(2)}',
                      ),
                      Text(
                        '${isArabic ? 'التاريخ:' : 'Date:'} ${DateFormat('yyyy-MM-dd').format(quotation.createdAt)}',
                      ),
                    ],
                  ),
                  trailing: Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => QuotationDetailScreen(
                          quotation: quotation,
                        ),
                      ),
                    );
                  },
                ),
              )).toList()),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isArabic) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}