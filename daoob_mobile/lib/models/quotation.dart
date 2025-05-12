class Quotation {
  final int id;
  final int eventRequestId;
  final double totalAmount;
  final String status; // pending, accepted, declined
  final DateTime createdAt;
  final List<Map<String, dynamic>> items;
  final String? notes;
  
  const Quotation({
    required this.id,
    required this.eventRequestId,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    required this.items,
    this.notes,
  });
  
  factory Quotation.fromJson(Map<String, dynamic> json) {
    return Quotation(
      id: json['id'],
      eventRequestId: json['eventRequestId'],
      totalAmount: (json['totalAmount'] as num).toDouble(),
      status: json['status'],
      createdAt: DateTime.parse(json['createdAt']),
      items: (json['items'] as List).map((item) => Map<String, dynamic>.from(item)).toList(),
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
      'items': items,
      'notes': notes,
    };
  }
}