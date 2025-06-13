class Quotation {
  final int id;
  final int eventRequestId;
  final double totalAmount;
  final String status; // quotation_sent, accepted, declined
  final DateTime createdAt;
  final String? description;
  final String? expiryDate;
  final Map<String, dynamic>? breakdown;
  final String? notes;
  
  // Getter for backward compatibility
  double get totalPrice => totalAmount;
  
  const Quotation({
    required this.id,
    required this.eventRequestId,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    this.description,
    this.expiryDate,
    this.breakdown,
    this.notes,
  });
  
  factory Quotation.fromJson(Map<String, dynamic> json) {
    // Handle different field name mappings from API
    double amount = 0.0;
    if (json['totalPrice'] != null) {
      amount = (json['totalPrice'] as num).toDouble();
    } else if (json['totalAmount'] != null) {
      amount = (json['totalAmount'] as num).toDouble();
    }
    
    // Extract description and breakdown from details field
    String? description;
    Map<String, dynamic>? breakdown;
    
    if (json['details'] != null) {
      final details = json['details'] as Map<String, dynamic>;
      description = details['description'] as String?;
      breakdown = details['breakdown'] as Map<String, dynamic>?;
    }
    
    return Quotation(
      id: json['id'],
      eventRequestId: json['eventRequestId'],
      totalAmount: amount,
      status: json['status'],
      createdAt: DateTime.parse(json['createdAt']),
      description: description,
      expiryDate: json['expiryDate'],
      breakdown: breakdown,
      notes: json['notes'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventRequestId': eventRequestId,
      'totalAmount': totalAmount,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'description': description,
      'expiryDate': expiryDate,
      'breakdown': breakdown,
      'notes': notes,
    };
  }
}