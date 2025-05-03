import 'package:eventora_app/models/user.dart';

class Vendor {
  final int id;
  final int userId;
  final String businessName;
  final String category;
  final String? description;
  final String? city;
  final String? priceRange;
  final String? address;
  final double? rating;
  final int? reviewCount;
  final List<String>? photos;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  // User info (may be included in some API responses)
  final User? user;
  
  Vendor({
    required this.id,
    required this.userId,
    required this.businessName,
    required this.category,
    this.description,
    this.city,
    this.priceRange,
    this.address,
    this.rating,
    this.reviewCount,
    this.photos,
    this.createdAt,
    this.updatedAt,
    this.user,
  });
  
  factory Vendor.fromJson(Map<String, dynamic> json) {
    return Vendor(
      id: json['id'],
      userId: json['userId'],
      businessName: json['businessName'],
      category: json['category'],
      description: json['description'],
      city: json['city'],
      priceRange: json['priceRange'],
      address: json['address'],
      rating: json['rating'] != null ? json['rating'].toDouble() : null,
      reviewCount: json['reviewCount'],
      photos: json['photos'] != null 
          ? List<String>.from(json['photos']) 
          : null,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      user: json['user'] != null ? User.fromJson(json['user']) : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'businessName': businessName,
      'category': category,
      'description': description,
      'city': city,
      'priceRange': priceRange,
      'address': address,
      'rating': rating,
      'reviewCount': reviewCount,
      'photos': photos,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'user': user?.toJson(),
    };
  }
}