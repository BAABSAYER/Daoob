class EventType {
  final int id;
  final String name;
  final String? description;
  final String? icon;
  final bool isActive;
  final DateTime createdAt;

  EventType({
    required this.id,
    required this.name,
    this.description,
    this.icon,
    this.isActive = true,
    required this.createdAt,
  });

  factory EventType.fromJson(Map<String, dynamic> json) {
    return EventType(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      icon: json['icon'],
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}