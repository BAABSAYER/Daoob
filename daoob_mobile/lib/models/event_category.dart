class EventCategory {
  final String id;
  final String name;
  final String? description;
  final String? icon;
  final String? imageUrl;

  EventCategory({
    required this.id,
    required this.name,
    this.description,
    this.icon,
    this.imageUrl,
  });

  factory EventCategory.fromJson(Map<String, dynamic> json) {
    return EventCategory(
      id: json['id'].toString(),
      name: json['name'] as String,
      description: json['description'] as String?,
      icon: json['icon'] as String?,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'imageUrl': imageUrl,
    };
  }
}