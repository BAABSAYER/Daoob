class Quotation {
  final int id;
  final int eventRequestId;
  final String eventType;
  final DateTime eventDate;
  final double totalPrice;
  final String? description;
  final List<String>? includedServices;
  final Map<String, dynamic>? vendorDetails;
  final String status;
  final DateTime? expiryDate;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Quotation({
    required this.id,
    required this.eventRequestId,
    required this.eventType,
    required this.eventDate,
    required this.totalPrice,
    this.description,
    this.includedServices,
    this.vendorDetails,
    required this.status,
    this.expiryDate,
    required this.createdAt,
    this.updatedAt,
  });

  factory Quotation.fromJson(Map<String, dynamic> json) {
    return Quotation(
      id: json['id'],
      eventRequestId: json['eventRequestId'],
      eventType: json['eventType'] ?? 'Event',
      eventDate: json['eventDate'] != null 
        ? DateTime.parse(json['eventDate']) 
        : DateTime.now(),
      totalPrice: json['totalPrice'] != null 
        ? double.parse(json['totalPrice'].toString()) 
        : 0.0,
      description: json['description'],
      includedServices: json['includedServices'] != null 
        ? List<String>.from(json['includedServices']) 
        : null,
      vendorDetails: json['vendorDetails'],
      status: json['status'] ?? 'pending',
      expiryDate: json['expiryDate'] != null 
        ? DateTime.parse(json['expiryDate']) 
        : null,
      createdAt: json['createdAt'] != null 
        ? DateTime.parse(json['createdAt']) 
        : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
        ? DateTime.parse(json['updatedAt']) 
        : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventRequestId': eventRequestId,
      'eventType': eventType,
      'eventDate': eventDate.toIso8601String(),
      'totalPrice': totalPrice,
      'description': description,
      'includedServices': includedServices,
      'vendorDetails': vendorDetails,
      'status': status,
      'expiryDate': expiryDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
  
  // Helper to check if quote has expired
  bool get isExpired {
    if (expiryDate == null) return false;
    return DateTime.now().isAfter(expiryDate!);
  }
}