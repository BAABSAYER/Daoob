import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:daoob_mobile/services/auth_service.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class Booking {
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
    };
  }
}

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
          notes TEXT
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
      await _loadOfflineBookings();
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
      // Determine base URL based on platform
      String baseUrl = Platform.isIOS 
          ? 'http://localhost:5000' 
          : 'http://10.0.2.2:5000';
      
      final endpoint = user.userType == 'vendor'
          ? '$baseUrl/api/vendor/bookings'
          : '$baseUrl/api/client/bookings';
      
      final response = await http.get(
        Uri.parse(endpoint),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
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
        await _loadOfflineBookings();
      }
    } catch (e) {
      _error = 'Network error: ${e.toString()}';
      // If network request fails, try to load from local database as fallback
      await _loadOfflineBookings();
    }
  }
  
  Future<void> _loadOfflineBookings() async {
    try {
      if (_database == null) {
        await _initDatabase();
      }
      
      // First check if we have saved bookings
      final List<Map<String, dynamic>> maps = await _database!.query('bookings');
      
      if (maps.isNotEmpty) {
        _bookings = maps.map((item) {
          return Booking(
            id: item['id'],
            clientId: item['clientId'],
            vendorId: item['vendorId'],
            vendorName: item['vendorName'],
            clientName: item['clientName'],
            eventDate: DateTime.parse(item['eventDate']),
            eventType: item['eventType'],
            packageType: item['packageType'],
            totalPrice: item['totalPrice'],
            status: item['status'],
            notes: item['notes'],
          );
        }).toList();
      } else {
        // If no saved bookings, generate some sample data
        _bookings = _generateSampleBookings();
        await _saveBookingsLocally(_bookings);
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Database error: ${e.toString()}';
      _isLoading = false;
      _bookings = _generateSampleBookings(); // Fallback to sample data
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
        {
          'id': booking.id,
          'clientId': booking.clientId,
          'vendorId': booking.vendorId,
          'vendorName': booking.vendorName,
          'clientName': booking.clientName,
          'eventDate': booking.eventDate.toIso8601String(),
          'eventType': booking.eventType,
          'packageType': booking.packageType,
          'totalPrice': booking.totalPrice,
          'status': booking.status,
          'notes': booking.notes,
        },
      );
    }
  }
  
  List<Booking> _generateSampleBookings() {
    return [
      Booking(
        id: 1,
        clientId: 1,
        vendorId: 101,
        vendorName: 'Elegant Events',
        eventDate: DateTime.now().add(const Duration(days: 30)),
        eventType: 'wedding',
        packageType: 'Premium',
        totalPrice: 2500.0,
        status: 'confirmed',
        notes: 'Beach wedding with 100 guests',
      ),
      Booking(
        id: 2,
        clientId: 1,
        vendorId: 102,
        vendorName: 'Corporate Solutions',
        eventDate: DateTime.now().add(const Duration(days: 15)),
        eventType: 'corporate',
        packageType: 'Standard',
        totalPrice: 1200.0,
        status: 'pending',
        notes: 'Annual company meeting',
      ),
      Booking(
        id: 3,
        clientId: 1,
        vendorId: 103,
        vendorName: 'Party Planners',
        eventDate: DateTime.now().subtract(const Duration(days: 10)),
        eventType: 'birthday',
        packageType: 'Basic',
        totalPrice: 500.0,
        status: 'completed',
        notes: 'Sweet sixteen birthday party',
      ),
      Booking(
        id: 4,
        clientId: 1,
        vendorId: 104,
        vendorName: 'Wedding Paradise',
        eventDate: DateTime.now().subtract(const Duration(days: 90)),
        eventType: 'wedding',
        packageType: 'Premium',
        totalPrice: 3000.0,
        status: 'cancelled',
        notes: 'Canceled due to venue issues',
      ),
    ];
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
      // Determine base URL based on platform
      String baseUrl = Platform.isIOS 
          ? 'http://localhost:5000' 
          : 'http://10.0.2.2:5000';
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/bookings'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
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
      {
        'id': booking.id,
        'clientId': booking.clientId,
        'vendorId': booking.vendorId,
        'vendorName': booking.vendorName,
        'clientName': booking.clientName,
        'eventDate': booking.eventDate.toIso8601String(),
        'eventType': booking.eventType,
        'packageType': booking.packageType,
        'totalPrice': booking.totalPrice,
        'status': booking.status,
        'notes': booking.notes,
      },
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
      // Determine base URL based on platform
      String baseUrl = Platform.isIOS 
          ? 'http://localhost:5000' 
          : 'http://10.0.2.2:5000';
      
      final response = await http.put(
        Uri.parse('$baseUrl/api/bookings/$bookingId/status'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
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
      {
        'id': booking.id,
        'clientId': booking.clientId,
        'vendorId': booking.vendorId,
        'vendorName': booking.vendorName,
        'clientName': booking.clientName,
        'eventDate': booking.eventDate.toIso8601String(),
        'eventType': booking.eventType,
        'packageType': booking.packageType,
        'totalPrice': booking.totalPrice,
        'status': booking.status,
        'notes': booking.notes,
      },
      where: 'id = ?',
      whereArgs: [booking.id],
    );
  }
}
