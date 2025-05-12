class EventType {
  final int id;
  final String name;
  final String? description;
  final bool isActive;
  final String? categoryId;
  
  const EventType({
    required this.id,
    required this.name,
    this.description,
    required this.isActive,
    this.categoryId,
  });
  
  factory EventType.fromJson(Map<String, dynamic> json) {
    return EventType(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      isActive: json['isActive'] ?? true,
      categoryId: json['categoryId'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'isActive': isActive,
      'categoryId': categoryId,
    };
  }
}