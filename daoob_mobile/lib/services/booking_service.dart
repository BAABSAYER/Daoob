import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:daoob_mobile/services/auth_service.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../config/api_config.dart';
import 'package:daoob_mobile/models/booking.dart';

// Using the Booking model from models/booking.dart instead of redefining it here
/* Commented out to avoid conflict
class BookingOld {
  final int id;
  final int clientId;
  final int vendorId;
  final String? vendorName;
  final String? clientName;
  final DateTime eventDate;
  final String eventType;
  final String packageType;
  final double totalPrice;
  final String status;
  final String? notes;
  final List<int> additionalVendorIds; // New: For multiple vendors
  final List<String>? additionalVendorNames; // New: Names of additional vendors
  
  Booking({
    required this.id,
    required this.clientId,
    required this.vendorId,
    this.vendorName,
    this.clientName,
    required this.eventDate,
    required this.eventType,
    required this.packageType,
    required this.totalPrice,
    required this.status,
    this.notes,
    this.additionalVendorIds = const [],
    this.additionalVendorNames,
  });
  
  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'],
      clientId: json['clientId'],
      vendorId: json['vendorId'],
      vendorName: json['vendorName'],
      clientName: json['clientName'],
      eventDate: DateTime.parse(json['eventDate']),
      eventType: json['eventType'],
      packageType: json['packageType'],
      totalPrice: json['totalPrice'].toDouble(),
      status: json['status'],
      notes: json['notes'],
      additionalVendorIds: json['additionalVendorIds'] != null
        ? (json['additionalVendorIds'] is List 
            ? List<int>.from(json['additionalVendorIds'])
            : List<int>.from(jsonDecode(json['additionalVendorIds'].toString())))
        : [],
      additionalVendorNames: json['additionalVendorNames'] != null
        ? (json['additionalVendorNames'] is List
            ? List<String>.from(json['additionalVendorNames'])
            : List<String>.from(jsonDecode(json['additionalVendorNames'].toString())))
        : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clientId': clientId,
      'vendorId': vendorId,
      'vendorName': vendorName,
      'clientName': clientName,
      'eventDate': eventDate.toIso8601String(),
      'eventType': eventType,
      'packageType': packageType,
      'totalPrice': totalPrice,
      'status': status,
      'notes': notes,
      'additionalVendorIds': jsonEncode(additionalVendorIds),
      'additionalVendorNames': additionalVendorNames != null ? jsonEncode(additionalVendorNames) : null,
    };
  }
}
*/

class BookingService extends ChangeNotifier {
  List<Booking> _bookings = [];
  bool _isLoading = false;
  String? _error;
  Database? _database;
  
  List<Booking> get bookings => _bookings;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  BookingService() {
    _initDatabase();
  }
  
  Future<void> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'bookings.db');
    
    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
        CREATE TABLE bookings(
          id INTEGER PRIMARY KEY,
          clientId INTEGER,
          vendorId INTEGER,
          vendorName TEXT,
          clientName TEXT,
          eventDate TEXT,
          eventType TEXT,
          packageType TEXT,
          totalPrice REAL,
          status TEXT,
          notes TEXT,
          additionalVendorIds TEXT,
          additionalVendorNames TEXT
        )
        ''');
      },
    );
  }
  
  Future<void> loadBookings(AuthService authService) async {
    if (_database == null) {
      await _initDatabase();
    }
    
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    // If offline mode is active, load from local DB
    if (authService.isOfflineMode) {
      await _loadOfflineBookings(authService.user?.id, authService.user?.userType);
      return;
    }
    
    // Otherwise, load from API
    final user = authService.user;
    final token = authService.token;
    
    if (user == null || token == null) {
      _error = 'User not authenticated';
      _isLoading = false;
      notifyListeners();
      return;
    }
    
    try {
      final endpoint = user.userType == 'vendor'
          ? '${ApiConfig.apiUrl}/vendor/bookings'
          : '${ApiConfig.apiUrl}/client/bookings';
      
      final response = await http.get(
        Uri.parse(endpoint),
        headers: ApiConfig.authHeaders(token),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _bookings = data.map((item) => Booking.fromJson(item)).toList();
        
        // Save to local database
        await _saveBookingsLocally(_bookings);
        
        _isLoading = false;
        notifyListeners();
      } else {
        // If API fails, try to load from local database as fallback
        await _loadOfflineBookings(user.id, user.userType);
      }
    } catch (e) {
      _error = 'Network error: ${e.toString()}';
      // If network request fails, try to load from local database as fallback
      await _loadOfflineBookings(authService.user?.id, authService.user?.userType);
    }
  }
  
  Future<void> _loadOfflineBookings(int? userId, String? userType) async {
    try {
      if (_database == null) {
        await _initDatabase();
      }
      
      List<Map<String, dynamic>> maps;
      
      if (userId != null) {
        if (userType == 'vendor') {
          // For vendors, get bookings where vendorId matches or they are in additionalVendorIds
          maps = await _database!.rawQuery(
            'SELECT * FROM bookings WHERE vendorId = ?',
            [userId]
          );
          
          // Also check for bookings where vendor is in additionalVendorIds
          final allBookings = await _database!.query('bookings');
          for (final booking in allBookings) {
            final additionalIdsStr = booking['additionalVendorIds'] as String?;
            if (additionalIdsStr != null && additionalIdsStr.isNotEmpty) {
              try {
                final additionalIds = jsonDecode(additionalIdsStr) as List;
                if (additionalIds.contains(userId)) {
                  maps.add(booking);
                }
              } catch (e) {
                print('Error parsing additionalVendorIds: $e');
              }
            }
          }
        } else {
          // For clients, get bookings where clientId matches
          maps = await _database!.query(
            'bookings',
            where: 'clientId = ?',
            whereArgs: [userId],
          );
        }
      } else {
        // If no user id, get all bookings
        maps = await _database!.query('bookings');
      }
      
      if (maps.isNotEmpty) {
        _bookings = maps.map((item) {
          return Booking.fromJson(item);
        }).toList();
      } else {
        // If no saved bookings, generate some sample data
        _bookings = _generateSampleBookings(userId, userType);
        await _saveBookingsLocally(_bookings);
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Database error: ${e.toString()}';
      _isLoading = false;
      _bookings = _generateSampleBookings(userId, userType); // Fallback to sample data
      notifyListeners();
    }
  }
  
  Future<void> _saveBookingsLocally(List<Booking> bookings) async {
    if (_database == null) {
      await _initDatabase();
    }
    
    // Clear existing bookings
    await _database!.delete('bookings');
    
    // Insert new bookings
    for (var booking in bookings) {
      await _database!.insert(
        'bookings',
        booking.toJson(),
      );
    }
  }
  
  List<Booking> _generateSampleBookings(int? userId, String? userType) {
    // Default values if user is not logged in
    final clientId = userId ?? 1;
    final isVendor = userType == 'vendor';
    
    // Primary vendor IDs
    const List<int> vendorIds = [101, 102, 103, 104];
    const List<String> vendorNames = [
      'Elegant Events', 
      'Corporate Solutions', 
      'Party Planners', 
      'Wedding Paradise'
    ];
    
    // List of booking examples for clients
    final List<Booking> clientBookings = [
      Booking(
        id: 1,
        clientId: clientId,
        vendorId: vendorIds[0],
        vendorName: vendorNames[0],
        eventDate: DateTime.now().add(const Duration(days: 30)),
        eventType: 'wedding',
        packageType: 'Premium',
        totalPrice: 3500.0,
        status: 'confirmed',
        notes: 'Beach wedding with 100 guests',
        additionalVendorIds: [vendorIds[2], vendorIds[3]],
        additionalVendorNames: [vendorNames[2], vendorNames[3]],
      ),
      Booking(
        id: 2,
        clientId: clientId,
        vendorId: vendorIds[1],
        vendorName: vendorNames[1],
        eventDate: DateTime.now().add(const Duration(days: 15)),
        eventType: 'corporate',
        packageType: 'Standard',
        totalPrice: 2000.0,
        status: 'pending',
        notes: 'Annual company meeting for 50 people',
      ),
      Booking(
        id: 3,
        clientId: clientId,
        vendorId: vendorIds[2],
        vendorName: vendorNames[2],
        eventDate: DateTime.now().subtract(const Duration(days: 10)),
        eventType: 'birthday',
        packageType: 'Basic',
        totalPrice: 800.0,
        status: 'completed',
        notes: 'Sweet sixteen birthday party',
      ),
      Booking(
        id: 4,
        clientId: clientId,
        vendorId: vendorIds[3],
        vendorName: vendorNames[3],
        eventDate: DateTime.now().subtract(const Duration(days: 60)),
        eventType: 'wedding',
        packageType: 'Premium',
        totalPrice: 4500.0,
        status: 'cancelled',
        notes: 'Canceled due to venue issues',
      ),
    ];
    
    // List of booking examples for vendors with different clients
    final List<Booking> vendorBookings = [
      Booking(
        id: 5,
        clientId: 1001,
        clientName: 'John Smith',
        vendorId: userId ?? vendorIds[0],
        vendorName: userId != null ? null : vendorNames[0],
        eventDate: DateTime.now().add(const Duration(days: 20)),
        eventType: 'wedding',
        packageType: 'Premium',
        totalPrice: 3800.0,
        status: 'pending',
        notes: 'Garden wedding for 80 guests',
      ),
      Booking(
        id: 6,
        clientId: 1002,
        clientName: 'Sarah Johnson',
        vendorId: userId ?? vendorIds[1],
        vendorName: userId != null ? null : vendorNames[1],
        eventDate: DateTime.now().add(const Duration(days: 7)),
        eventType: 'corporate',
        packageType: 'Standard',
        totalPrice: 2200.0,
        status: 'confirmed',
        notes: 'Product launch event',
      ),
      Booking(
        id: 7,
        clientId: 1003,
        clientName: 'Michael Brown',
        vendorId: userId ?? vendorIds[2],
        vendorName: userId != null ? null : vendorNames[2],
        eventDate: DateTime.now().add(const Duration(days: 45)),
        eventType: 'birthday',
        packageType: 'Premium',
        totalPrice: 1200.0,
        status: 'pending',
        notes: '40th birthday celebration',
      ),
    ];
    
    // Return appropriate bookings based on user type
    return isVendor ? vendorBookings : clientBookings;
  }
  
  Future<bool> createBooking(Booking booking, AuthService authService) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    // If offline mode is active, save locally
    if (authService.isOfflineMode) {
      await _createOfflineBooking(booking);
      return true;
    }
    
    final user = authService.user;
    final token = authService.token;
    
    if (user == null || token == null) {
      _error = 'User not authenticated';
      _isLoading = false;
      notifyListeners();
      return false;
    }
    
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.bookingsEndpoint),
        headers: ApiConfig.authHeaders(token),
        body: json.encode(booking.toJson()),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 201) {
        final createdBooking = Booking.fromJson(json.decode(response.body));
        _bookings.add(createdBooking);
        
        // Save to local database
        await _saveBookingLocally(createdBooking);
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = json.decode(response.body)['message'] ?? 'Failed to create booking';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Network error: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      
      // Try to save locally if network fails
      await _createOfflineBooking(booking);
      return true;
    }
  }
  
  Future<void> _createOfflineBooking(Booking booking) async {
    if (_database == null) {
      await _initDatabase();
    }
    
    // Generate a new ID (highest ID + 1)
    int newId = 1;
    if (_bookings.isNotEmpty) {
      newId = _bookings.map((b) => b.id).reduce((a, b) => a > b ? a : b) + 1;
    }
    
    final newBooking = Booking(
      id: newId,
      clientId: booking.clientId,
      vendorId: booking.vendorId,
      vendorName: booking.vendorName,
      clientName: booking.clientName,
      eventDate: booking.eventDate,
      eventType: booking.eventType,
      packageType: booking.packageType,
      totalPrice: booking.totalPrice,
      status: 'pending', // New bookings are pending by default in offline mode
      notes: booking.notes,
      additionalVendorIds: booking.additionalVendorIds,
      additionalVendorNames: booking.additionalVendorNames,
    );
    
    _bookings.add(newBooking);
    await _saveBookingLocally(newBooking);
    
    _isLoading = false;
    notifyListeners();
  }
  
  Future<void> _saveBookingLocally(Booking booking) async {
    if (_database == null) {
      await _initDatabase();
    }
    
    await _database!.insert(
      'bookings',
      booking.toJson(),
    );
  }
  
  Future<bool> updateBookingStatus(int bookingId, String status, AuthService authService) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    // If offline mode is active, update locally
    if (authService.isOfflineMode) {
      await _updateOfflineBookingStatus(bookingId, status);
      return true;
    }
    
    final user = authService.user;
    final token = authService.token;
    
    if (user == null || token == null) {
      _error = 'User not authenticated';
      _isLoading = false;
      notifyListeners();
      return false;
    }
    
    try {
      final response = await http.put(
        Uri.parse('${ApiConfig.bookingsEndpoint}/$bookingId/status'),
        headers: ApiConfig.authHeaders(token),
        body: json.encode({'status': status}),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        // Update the booking in the list
        final index = _bookings.indexWhere((b) => b.id == bookingId);
        if (index != -1) {
          final updatedBooking = Booking(
            id: _bookings[index].id,
            clientId: _bookings[index].clientId,
            vendorId: _bookings[index].vendorId,
            vendorName: _bookings[index].vendorName,
            clientName: _bookings[index].clientName,
            eventDate: _bookings[index].eventDate,
            eventType: _bookings[index].eventType,
            packageType: _bookings[index].packageType,
            totalPrice: _bookings[index].totalPrice,
            status: status,
            notes: _bookings[index].notes,
            additionalVendorIds: _bookings[index].additionalVendorIds,
            additionalVendorNames: _bookings[index].additionalVendorNames,
          );
          
          _bookings[index] = updatedBooking;
          
          // Update in local database
          await _updateBookingLocally(updatedBooking);
        }
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = json.decode(response.body)['message'] ?? 'Failed to update booking status';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Network error: ${e.toString()}';
      _isLoading = false;
      notifyListeners();
      
      // Try to update locally if network fails
      await _updateOfflineBookingStatus(bookingId, status);
      return true;
    }
  }
  
  Future<void> _updateOfflineBookingStatus(int bookingId, String status) async {
    // Update in memory
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index != -1) {
      final updatedBooking = Booking(
        id: _bookings[index].id,
        clientId: _bookings[index].clientId,
        vendorId: _bookings[index].vendorId,
        vendorName: _bookings[index].vendorName,
        clientName: _bookings[index].clientName,
        eventDate: _bookings[index].eventDate,
        eventType: _bookings[index].eventType,
        packageType: _bookings[index].packageType,
        totalPrice: _bookings[index].totalPrice,
        status: status,
        notes: _bookings[index].notes,
        additionalVendorIds: _bookings[index].additionalVendorIds,
        additionalVendorNames: _bookings[index].additionalVendorNames,
      );
      
      _bookings[index] = updatedBooking;
      
      // Update in local database
      await _updateBookingLocally(updatedBooking);
    }
    
    _isLoading = false;
    notifyListeners();
  }
  
  Future<void> _updateBookingLocally(Booking booking) async {
    if (_database == null) {
      await _initDatabase();
    }
    
    await _database!.update(
      'bookings',
      booking.toJson(),
      where: 'id = ?',
      whereArgs: [booking.id],
    );
  }
}
