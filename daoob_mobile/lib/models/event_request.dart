class EventRequest {
  final int id;
  final int clientId;
  final int eventTypeId;
  final String status;
  final DateTime eventDate;
  final DateTime createdAt;
  final Map<String, dynamic> details;
  
  const EventRequest({
    required this.id,
    required this.clientId,
    required this.eventTypeId,
    required this.status,
    required this.eventDate,
    required this.createdAt,
    required this.details,
  });
  
  factory EventRequest.fromJson(Map<String, dynamic> json) {
    return EventRequest(
      id: json['id'],
      clientId: json['clientId'],
      eventTypeId: json['eventTypeId'],
      status: json['status'],
      eventDate: DateTime.parse(json['eventDate']),
      createdAt: DateTime.parse(json['createdAt']),
      details: json['details'] is String 
          ? {} // Handle empty or invalid details
          : Map<String, dynamic>.from(json['details']),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clientId': clientId,
      'eventTypeId': eventTypeId,
      'status': status,
      'eventDate': eventDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'details': details,
    };
  }
}