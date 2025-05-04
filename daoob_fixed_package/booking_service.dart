import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:http/http.dart' as http;
import 'package:daoob_mobile/services/auth_service.dart';

// Define Booking class directly in this file
class Booking {
  final int id;
  final int clientId;
  final int vendorId;
  final String status; // 'pending', 'confirmed', 'canceled', 'completed'
  final DateTime bookingDate;
  final DateTime eventDate;
  final String packageType; // 'basic', 'standard', 'premium'
  final double totalPrice;
  final String notes;
  final DateTime createdAt;
  final String? vendorName;
  final String? clientName;

  Booking({
    required this.id,
    required this.clientId,
    required this.vendorId,
    required this.status,
    required this.bookingDate,
    required this.eventDate,
    required this.packageType,
    required this.totalPrice,
    required this.notes,
    required this.createdAt,
    this.vendorName,
    this.clientName,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'],
      clientId: json['clientId'],
      vendorId: json['vendorId'],
      status: json['status'],
      bookingDate: DateTime.parse(json['bookingDate']),
      eventDate: DateTime.parse(json['eventDate']),
      packageType: json['packageType'],
      totalPrice: json['totalPrice'].toDouble(),
      notes: json['notes'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      vendorName: json['vendorName'],
      clientName: json['clientName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clientId': clientId,
      'vendorId': vendorId,
      'status': status,
      'bookingDate': bookingDate.toIso8601String(),
      'eventDate': eventDate.toIso8601String(),
      'packageType': packageType,
      'totalPrice': totalPrice,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'vendorName': vendorName,
      'clientName': clientName,
    };
  }

  // Generator for mock bookings
  static List<Booking> getMockBookings({bool isVendor = false, int userId = 1}) {
    final now = DateTime.now();
    
    // Sample vendors and clients for mock data
    final vendors = [
      {'id': 101, 'name': 'Elegant Events'},
      {'id': 102, 'name': 'Premier Catering'},
      {'id': 103, 'name': 'Deluxe Photography'},
    ];
    
    final clients = [
      {'id': 1, 'name': 'John Smith'},
      {'id': 2, 'name': 'Sarah Johnson'},
      {'id': 3, 'name': 'Mohammed Ali'},
    ];
    
    // Generate different bookings based on user role
    List<Map<String, dynamic>> bookingsData = [];
    
    if (isVendor) {
      // Mock bookings for vendors - showing different clients
      bookingsData = [
        {
          'id': 1001,
          'clientId': 1,
          'vendorId': userId,
          'status': 'confirmed',
          'bookingDate': now.subtract(const Duration(days: 7)).toIso8601String(),
          'eventDate': now.add(const Duration(days: 30)).toIso8601String(),
          'packageType': 'premium',
          'totalPrice': 2500.0,
          'notes': 'Wedding reception for 200 guests',
          'createdAt': now.subtract(const Duration(days: 7)).toIso8601String(),
          'clientName': 'John Smith',
        },
        {
          'id': 1002,
          'clientId': 2,
          'vendorId': userId,
          'status': 'pending',
          'bookingDate': now.subtract(const Duration(days: 2)).toIso8601String(),
          'eventDate': now.add(const Duration(days: 45)).toIso8601String(),
          'packageType': 'standard',
          'totalPrice': 1800.0,
          'notes': 'Corporate event with 50 attendees',
          'createdAt': now.subtract(const Duration(days: 2)).toIso8601String(),
          'clientName': 'Sarah Johnson',
        },
        {
          'id': 1003,
          'clientId': 3,
          'vendorId': userId,
          'status': 'completed',
          'bookingDate': now.subtract(const Duration(days: 30)).toIso8601String(),
          'eventDate': now.subtract(const Duration(days: 5)).toIso8601String(),
          'packageType': 'basic',
          'totalPrice': 1200.0,
          'notes': 'Birthday party with 30 guests',
          'createdAt': now.subtract(const Duration(days: 30)).toIso8601String(),
          'clientName': 'Mohammed Ali',
        },
      ];
    } else {
      // Mock bookings for clients - showing different vendors
      bookingsData = [
        {
          'id': 1001,
          'clientId': userId,
          'vendorId': 101,
          'status': 'confirmed',
          'bookingDate': now.subtract(const Duration(days: 7)).toIso8601String(),
          'eventDate': now.add(const Duration(days: 30)).toIso8601String(),
          'packageType': 'premium',
          'totalPrice': 2500.0,
          'notes': 'Wedding reception for 200 guests',
          'createdAt': now.subtract(const Duration(days: 7)).toIso8601String(),
          'vendorName': 'Elegant Events',
        },
        {
          'id': 1002,
          'clientId': userId,
          'vendorId': 102,
          'status': 'pending',
          'bookingDate': now.subtract(const Duration(days: 2)).toIso8601String(),
          'eventDate': now.add(const Duration(days: 45)).toIso8601String(),
          'packageType': 'standard',
          'totalPrice': 1800.0,
          'notes': 'Corporate event with 50 attendees',
          'createdAt': now.subtract(const Duration(days: 2)).toIso8601String(),
          'vendorName': 'Premier Catering',
        },
        {
          'id': 1003,
          'clientId': userId,
          'vendorId': 103,
          'status': 'completed',
          'bookingDate': now.subtract(const Duration(days: 30)).toIso8601String(),
          'eventDate': now.subtract(const Duration(days: 5)).toIso8601String(),
          'packageType': 'basic',
          'totalPrice': 1200.0,
          'notes': 'Birthday party with 30 guests',
          'createdAt': now.subtract(const Duration(days: 30)).toIso8601String(),
          'vendorName': 'Deluxe Photography',
        },
      ];
    }
    
    // Convert the mock data to Booking objects
    return bookingsData.map((data) => Booking.fromJson(data)).toList();
  }
}

class BookingService extends ChangeNotifier {
  List<Booking> _bookings = [];
  bool _isLoading = false;
  String? _error;
  late Database _database;
  bool _isInitialized = false;
  bool _isOfflineMode = false;
  
  List<Booking> get bookings => _bookings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  BookingService() {
    _loadOfflineMode();
  }

  Future<void> _loadOfflineMode() async {
    final prefs = await SharedPreferences.getInstance();
    _isOfflineMode = prefs.getBool('offline_mode') ?? false;
    
    // Initialize database when constructing
    initialize();
  }

  // Initialize database
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      final databasePath = await getDatabasePath();
      _database = await openDatabase(
        databasePath,
        version: 1,
        onCreate: (db, version) async {
          await db.execute(
            '''
            CREATE TABLE bookings(
              id INTEGER PRIMARY KEY,
              clientId INTEGER,
              vendorId INTEGER,
              status TEXT,
              bookingDate TEXT,
              eventDate TEXT,
              packageType TEXT,
              totalPrice REAL,
              notes TEXT,
              createdAt TEXT,
              vendorName TEXT,
              clientName TEXT
            )
            ''',
          );
        },
      );
      _isInitialized = true;
    } catch (e) {
      _error = 'Failed to initialize database: $e';
      notifyListeners();
    }
  }

  Future<String> getDatabasePath() async {
    return join(await getDatabasesPath(), 'daoob_bookings.db');
  }

  // Check if we're in offline mode
  Future<bool> checkOfflineMode() async {
    final prefs = await SharedPreferences.getInstance();
    _isOfflineMode = prefs.getBool('offline_mode') ?? false;
    return _isOfflineMode;
  }

  // Load bookings from database or API
  Future<void> loadBookings(AuthService authService, {bool forceRefresh = false}) async {
    if (!_isInitialized) await initialize();
    await checkOfflineMode();
    
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // If user is null, check if we're in offline mode
      if (authService.user == null) {
        if (_isOfflineMode) {
          // Generate mock bookings for offline mode without user
          _generateMockBookings(1, 'client');
        } else {
          throw Exception('User not authenticated');
        }
        _isLoading = false;
        notifyListeners();
        return;
      }

      if (_isOfflineMode || !forceRefresh) {
        // Try to load from local database first
        await _loadBookingsFromDatabase(authService.user!.id, authService.user!.userType);
      }

      // If online and we need fresh data, fetch from API
      if (!_isOfflineMode && (forceRefresh || _bookings.isEmpty)) {
        await _fetchBookingsFromApi(authService.user!.id, authService.user!.userType);
      }

      // If still empty and offline, generate mock data
      if (_bookings.isEmpty && _isOfflineMode) {
        _generateMockBookings(authService.user!.id, authService.user!.userType);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Load bookings from the local database
  Future<void> _loadBookingsFromDatabase(int userId, String userType) async {
    final String fieldName = userType == 'vendor' ? 'vendorId' : 'clientId';
    final List<Map<String, dynamic>> maps = await _database.query(
      'bookings',
      where: '$fieldName = ?',
      whereArgs: [userId],
    );
    
    _bookings = List.generate(maps.length, (i) {
      return Booking.fromJson(maps[i]);
    });
  }

  // Fetch bookings from the API
  Future<void> _fetchBookingsFromApi(int userId, String userType) async {
    try {
      final endpoint = userType == 'vendor' 
        ? 'https://api.daoob.com/bookings/vendor/$userId'
        : 'https://api.daoob.com/bookings/client/$userId';
        
      final response = await http.get(Uri.parse(endpoint));
      
      if (response.statusCode == 200) {
        final List<dynamic> bookingsJson = json.decode(response.body);
        _bookings = bookingsJson.map((json) => Booking.fromJson(json)).toList();
        
        // Cache bookings in the database
        await _cacheBookingsInDatabase(_bookings);
      } else {
        throw Exception('Failed to load bookings');
      }
    } catch (e) {
      // If API fails in production, use cached data or mock data
      if (_bookings.isEmpty) {
        // Check if we have any local data
        await _loadBookingsFromDatabase(userId, userType);
        
        if (_bookings.isEmpty && _isOfflineMode) {
          _generateMockBookings(userId, userType);
        }
      }
      
      if (!_isOfflineMode) {
        throw Exception('Error fetching bookings: $e');
      }
    }
  }

  // Cache bookings in the local database
  Future<void> _cacheBookingsInDatabase(List<Booking> bookings) async {
    final batch = _database.batch();
    
    // Clear existing bookings
    batch.delete('bookings');
    
    // Insert new bookings
    for (var booking in bookings) {
      batch.insert('bookings', booking.toJson());
    }
    
    await batch.commit(noResult: true);
  }

  // Generate mock bookings for offline testing
  void _generateMockBookings(int userId, String userType) {
    _bookings = Booking.getMockBookings(
      isVendor: userType == 'vendor',
      userId: userId,
    );
    
    // Cache mock bookings
    _cacheBookingsInDatabase(_bookings);
  }

  // Create a new booking
  Future<Booking?> createBooking(AuthService authService, Booking booking) async {
    if (!_isInitialized) await initialize();
    await checkOfflineMode();
    
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // If user is null, check if we're in offline mode
      if (authService.user == null && !_isOfflineMode) {
        throw Exception('User not authenticated');
      }

      Booking createdBooking;
      
      if (!_isOfflineMode) {
        // Online mode - create booking through API
        try {
          final response = await http.post(
            Uri.parse('https://api.daoob.com/bookings'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(booking.toJson()),
          );
          
          if (response.statusCode == 201) {
            createdBooking = Booking.fromJson(json.decode(response.body));
          } else {
            throw Exception('Failed to create booking');
          }
        } catch (e) {
          // If API fails, create locally with current timestamp as ID
          final now = DateTime.now();
          createdBooking = Booking(
            id: now.millisecondsSinceEpoch,
            clientId: booking.clientId,
            vendorId: booking.vendorId,
            status: 'pending',
            bookingDate: now,
            eventDate: booking.eventDate,
            packageType: booking.packageType,
            totalPrice: booking.totalPrice,
            notes: booking.notes,
            createdAt: now,
            vendorName: booking.vendorName,
            clientName: booking.clientName,
          );
        }
      } else {
        // Offline mode - create booking locally with mock data
        final now = DateTime.now();
        createdBooking = Booking(
          id: now.millisecondsSinceEpoch, // Generate unique ID
          clientId: booking.clientId,
          vendorId: booking.vendorId,
          status: 'pending',
          bookingDate: now,
          eventDate: booking.eventDate,
          packageType: booking.packageType,
          totalPrice: booking.totalPrice,
          notes: booking.notes,
          createdAt: now,
          vendorName: booking.vendorName,
          clientName: booking.clientName,
        );
      }
      
      // Add to local list and cache
      _bookings.add(createdBooking);
      await _database.insert('bookings', createdBooking.toJson());
      
      _isLoading = false;
      notifyListeners();
      return createdBooking;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Update booking status
  Future<bool> updateBookingStatus(AuthService authService, int bookingId, String newStatus) async {
    if (!_isInitialized) await initialize();
    await checkOfflineMode();
    
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      if (!_isOfflineMode) {
        // Online mode - update through API
        try {
          final response = await http.patch(
            Uri.parse('https://api.daoob.com/bookings/$bookingId'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'status': newStatus}),
          );
          
          if (response.statusCode != 200) {
            throw Exception('Failed to update booking status');
          }
        } catch (e) {
          // If API fails but we're not in offline mode, propagate the error
          if (!_isOfflineMode) {
            throw e;
          }
          // Otherwise continue with local update
        }
      } 
      
      // Update in local list and database
      final index = _bookings.indexWhere((booking) => booking.id == bookingId);
      if (index != -1) {
        final updatedBooking = Booking(
          id: _bookings[index].id,
          clientId: _bookings[index].clientId,
          vendorId: _bookings[index].vendorId,
          status: newStatus,
          bookingDate: _bookings[index].bookingDate,
          eventDate: _bookings[index].eventDate,
          packageType: _bookings[index].packageType,
          totalPrice: _bookings[index].totalPrice,
          notes: _bookings[index].notes,
          createdAt: _bookings[index].createdAt,
          vendorName: _bookings[index].vendorName,
          clientName: _bookings[index].clientName,
        );
        
        _bookings[index] = updatedBooking;
        
        await _database.update(
          'bookings',
          {'status': newStatus},
          where: 'id = ?',
          whereArgs: [bookingId],
        );
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
