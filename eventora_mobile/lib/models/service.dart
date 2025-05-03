class Service {
  final int id;
  final int vendorId;
  final String name;
  final String? description;
  final double price;
  final int? duration; // in minutes
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<String>? images;
  
  Service({
    required this.id,
    required this.vendorId,
    required this.name,
    this.description,
    required this.price,
    this.duration,
    this.createdAt,
    this.updatedAt,
    this.images,
  });
  
  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'],
      vendorId: json['vendorId'],
      name: json['name'],
      description: json['description'],
      price: json['price'] != null ? json['price'].toDouble() : 0.0,
      duration: json['duration'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      images: json['images'] != null ? List<String>.from(json['images']) : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vendorId': vendorId,
      'name': name,
      'description': description,
      'price': price,
      'duration': duration,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'images': images,
    };
  }
  
  // Format price in currency format
  String get formattedPrice => '\$${price.toStringAsFixed(2)}';
  
  // Format duration in hours and minutes
  String get formattedDuration {
    if (duration == null) return 'Not specified';
    
    final hours = duration! ~/ 60;
    final minutes = duration! % 60;
    
    if (hours > 0 && minutes > 0) {
      return '$hours hr ${minutes.toString().padLeft(2, '0')} min';
    } else if (hours > 0) {
      return '$hours ${hours == 1 ? 'hour' : 'hours'}';
    } else {
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'}';
    }
  }
}