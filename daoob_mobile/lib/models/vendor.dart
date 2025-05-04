class Vendor {
  final int id;
  final int userId;
  final String name;
  final String description;
  final String category;
  final double rating;
  final String? logo;
  final String? coverImage;
  final double basePrice;
  final String? location;
  final String? contactPhone;
  final String? contactEmail;
  final String? website;
  final bool isVerified;

  Vendor({
    required this.id,
    required this.userId,
    required this.name,
    required this.description,
    required this.category,
    required this.rating,
    this.logo,
    this.coverImage,
    required this.basePrice,
    this.location,
    this.contactPhone,
    this.contactEmail,
    this.website,
    required this.isVerified,
  });

  factory Vendor.fromJson(Map<String, dynamic> json) {
    return Vendor(
      id: json['id'],
      userId: json['userId'],
      name: json['name'],
      description: json['description'],
      category: json['category'],
      rating: json['rating'].toDouble(),
      logo: json['logo'],
      coverImage: json['coverImage'],
      basePrice: json['basePrice'].toDouble(),
      location: json['location'],
      contactPhone: json['contactPhone'],
      contactEmail: json['contactEmail'],
      website: json['website'],
      isVerified: json['isVerified'] ?? false,
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
      'logo': logo,
      'coverImage': coverImage,
      'basePrice': basePrice,
      'location': location,
      'contactPhone': contactPhone,
      'contactEmail': contactEmail,
      'website': website,
      'isVerified': isVerified,
    };
  }
}
