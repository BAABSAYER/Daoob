import 'package:eventora_app/models/service.dart';
import 'package:eventora_app/models/user.dart';
import 'package:eventora_app/models/vendor.dart';

class Booking {
  final int id;
  final int clientId;
  final int vendorId;
  final int? serviceId;
  final String status;
  final String eventType;
  final DateTime eventDate;
  final int? guestCount;
  final double? totalPrice;
  final String? specialRequests;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  
  // Additional information that might be included from API responses
  final Service? service;
  final Vendor? vendor;
  final User? client;
  final String? packageType; // Basic, Standard, Premium
  
  Booking({
    required this.id,
    required this.clientId,
    required this.vendorId,
    this.serviceId,
    required this.status,
    required this.eventType,
    required this.eventDate,
    this.guestCount,
    this.totalPrice,
    this.specialRequests,
    this.createdAt,
    this.updatedAt,
    this.service,
    this.vendor,
    this.client,
    this.packageType,
  });
  
  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'],
      clientId: json['clientId'],
      vendorId: json['vendorId'],
      serviceId: json['serviceId'],
      status: json['status'],
      eventType: json['eventType'],
      eventDate: json['eventDate'] != null ? DateTime.parse(json['eventDate']) : DateTime.now(),
      guestCount: json['guestCount'],
      totalPrice: json['totalPrice'] != null ? json['totalPrice'].toDouble() : null,
      specialRequests: json['specialRequests'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      service: json['service'] != null ? Service.fromJson(json['service']) : null,
      vendor: json['vendor'] != null ? Vendor.fromJson(json['vendor']) : null,
      client: json['client'] != null ? User.fromJson(json['client']) : null,
      packageType: json['packageType'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clientId': clientId,
      'vendorId': vendorId,
      'serviceId': serviceId,
      'status': status,
      'eventType': eventType,
      'eventDate': eventDate.toIso8601String(),
      'guestCount': guestCount,
      'totalPrice': totalPrice,
      'specialRequests': specialRequests,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'packageType': packageType,
    };
  }
  
  // Format price in currency format
  String get formattedPrice => totalPrice != null ? '\$${totalPrice!.toStringAsFixed(2)}' : 'TBD';
  
  // Format the date
  String get formattedDate => '${eventDate.month}/${eventDate.day}/${eventDate.year}';
  
  // Format status with color
  String getStatusColor() {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return '#4CAF50'; // Green
      case 'pending':
        return '#FFC107'; // Amber
      case 'cancelled':
        return '#F44336'; // Red
      case 'completed':
        return '#2196F3'; // Blue
      default:
        return '#9E9E9E'; // Grey
    }
  }
}