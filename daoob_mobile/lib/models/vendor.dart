class Vendor {
  final int id;
  final int userId;
  final String name;
  final String description;
  final String category;
  final double rating;
  final double basePrice;
  final bool isVerified;
  final String? imageUrl;
  final List<String> services;
  
  Vendor({
    required this.id,
    required this.userId,
    required this.name,
    required this.description,
    required this.category,
    required this.rating,
    required this.basePrice,
    required this.isVerified,
    this.imageUrl,
    this.services = const [],
  });
  
  factory Vendor.fromJson(Map<String, dynamic> json) {
    List<String> servicesList = [];
    if (json['services'] != null) {
      if (json['services'] is List) {
        servicesList = List<String>.from(json['services'].map((s) => s.toString()));
      } else if (json['services'] is String) {
        servicesList = [json['services']];
      }
    }
    
    return Vendor(
      id: json['id'],
      userId: json['userId'],
      name: json['name'],
      description: json['description'],
      category: json['category'],
      rating: json['rating'].toDouble(),
      basePrice: json['basePrice'].toDouble(),
      isVerified: json['isVerified'],
      imageUrl: json['imageUrl'],
      services: servicesList,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'description': description,
      'category': category,
      'rating': rating,
      'basePrice': basePrice,
      'isVerified': isVerified,
      'imageUrl': imageUrl,
      'services': services,
    };
  }
}
