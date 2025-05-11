class EventRequest {
  final int id;
  final int clientId;
  final int eventTypeId;
  final String eventTypeName;
  final DateTime eventDate;
  final String? location;
  final int guestCount;
  final double? budget;
  final Map<String, dynamic>? responses;
  final String? description;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  EventRequest({
    required this.id,
    required this.clientId,
    required this.eventTypeId,
    required this.eventTypeName,
    required this.eventDate,
    this.location,
    required this.guestCount,
    this.budget,
    this.responses,
    this.description,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  factory EventRequest.fromJson(Map<String, dynamic> json) {
    return EventRequest(
      id: json['id'],
      clientId: json['clientId'],
      eventTypeId: json['eventTypeId'],
      eventTypeName: json['eventTypeName'] ?? 'Unknown Event Type',
      eventDate: json['eventDate'] != null 
        ? DateTime.parse(json['eventDate']) 
        : DateTime.now(),
      location: json['location'],
      guestCount: json['guestCount'] ?? 0,
      budget: json['budget'] != null ? double.parse(json['budget'].toString()) : null,
      responses: json['responses'] is String 
        ? {} // Handle string (should be parsed JSON)
        : json['responses'],
      description: json['description'],
      status: json['status'] ?? 'pending',
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
      'clientId': clientId,
      'eventTypeId': eventTypeId,
      'eventTypeName': eventTypeName,
      'eventDate': eventDate.toIso8601String(),
      'location': location,
      'guestCount': guestCount,
      'budget': budget,
      'responses': responses,
      'description': description,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}