import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:http/http.dart' as http;
import 'package:daoob_mobile/services/auth_service.dart';
import 'package:daoob_mobile/models/vendor.dart';

// Use the Vendor model from models/vendor.dart instead of redefining it here
/* Commented out to avoid conflict
class VendorOld {
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
  final bool isSelected; // For multi-selection
  
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
    required this.services,
    this.isSelected = false,
  });
  
  Vendor copyWith({
    int? id,
    int? userId,
    String? name,
    String? description,
    String? category,
    double? rating,
    double? basePrice,
    bool? isVerified,
    String? imageUrl,
    List<String>? services,
    bool? isSelected,
  }) {
    return Vendor(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      rating: rating ?? this.rating,
      basePrice: basePrice ?? this.basePrice,
      isVerified: isVerified ?? this.isVerified,
      imageUrl: imageUrl ?? this.imageUrl,
      services: services ?? this.services,
      isSelected: isSelected ?? this.isSelected,
    );
  }
  
  factory Vendor.fromJson(Map<String, dynamic> json) {
    return Vendor(
      id: json['id'],
      userId: json['userId'],
      name: json['name'],
      description: json['description'],
      category: json['category'],
      rating: json['rating'].toDouble(),
      basePrice: json['basePrice'].toDouble(),
      isVerified: json['isVerified'] == 1 || json['isVerified'] == true,
      imageUrl: json['imageUrl'],
      services: json['services'] != null 
        ? (json['services'] is List 
            ? List<String>.from(json['services']) 
            : List<String>.from(jsonDecode(json['services'])))
        : [],
      isSelected: json['isSelected'] == 1 || json['isSelected'] == true,
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
      'isVerified': isVerified ? 1 : 0,
      'imageUrl': imageUrl,
      'services': jsonEncode(services),
      'isSelected': isSelected ? 1 : 0,
    };
  }
}
*/

class VendorService extends ChangeNotifier {
  List<Vendor> _vendors = [];
  bool _isLoading = false;
  String? _error;
  Database? _database;
  List<Vendor> _selectedVendors = [];
  String _searchQuery = '';
  String _categoryFilter = '';
  
  List<Vendor> get vendors => _filterVendors();
  List<Vendor> get selectedVendors => _selectedVendors;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String get categoryFilter => _categoryFilter;
  
  List<Vendor> _filterVendors() {
    return _vendors.where((vendor) {
      // Apply category filter
      if (_categoryFilter.isNotEmpty && vendor.category != _categoryFilter) {
        return false;
      }
      
      // Apply search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return vendor.name.toLowerCase().contains(query) || 
               vendor.description.toLowerCase().contains(query);
      }
      
      return true;
    }).toList();
  }
  
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }
  
  void setCategoryFilter(String category) {
    _categoryFilter = category;
    notifyListeners();
  }
  
  void clearFilters() {
    _searchQuery = '';
    _categoryFilter = '';
    notifyListeners();
  }
  
  VendorService() {
    _initDatabase();
  }
  
  Future<void> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'vendors.db');
    
    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
        CREATE TABLE vendors(
          id INTEGER PRIMARY KEY,
          userId INTEGER,
          name TEXT,
          description TEXT,
          category TEXT,
          rating REAL,
          basePrice REAL,
          isVerified INTEGER,
          imageUrl TEXT,
          services TEXT,
          isSelected INTEGER
        )
        ''');
      },
    );
  }
  
  Future<void> loadVendors(AuthService authService, {String? category}) async {
    if (_database == null) {
      await _initDatabase();
    }
    
    _isLoading = true;
    _error = null;
    
    if (category != null) {
      _categoryFilter = category;
    }
    
    notifyListeners();
    
    try {
      // Get the API base URL
      final apiConfig = await authService.getApiConfig();
      final token = await authService.getToken();
      
      // Fetch vendors from API
      final url = '${apiConfig.baseUrl}/api/vendors';
      final categoryParam = category != null ? '?category=${Uri.encodeComponent(category)}' : '';
      
      final response = await http.get(
        Uri.parse('$url$categoryParam'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> vendorsJson = jsonDecode(response.body);
        _vendors = vendorsJson.map((json) => Vendor.fromJson(json)).toList();
        
        // Save to local database for caching
        await _saveVendorsLocally(_vendors);
        
        // Restore selected vendors
        _selectedVendors = _vendors.where((v) => v.isSelected).toList();
      } else {
        // If API request fails, try to load from local cache
        final List<Map<String, dynamic>> maps = await _database!.query('vendors');
        
        if (maps.isNotEmpty) {
          _vendors = maps.map((item) => Vendor.fromJson(item)).toList();
          _selectedVendors = _vendors.where((v) => v.isSelected).toList();
        } else {
          throw Exception('Failed to load vendors: ${response.statusCode}');
        }
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Error loading vendors: ${e.toString()}';
      _isLoading = false;
      
      // Try to load from local cache as last resort
      try {
        final List<Map<String, dynamic>> maps = await _database!.query('vendors');
        if (maps.isNotEmpty) {
          _vendors = maps.map((item) => Vendor.fromJson(item)).toList();
          _selectedVendors = _vendors.where((v) => v.isSelected).toList();
        }
      } catch (cacheError) {
        // If all attempts fail, initialize with empty list
        _vendors = [];
        _selectedVendors = [];
      }
      
      notifyListeners();
    }
  }
  
  Future<void> toggleVendorSelection(int vendorId) async {
    if (_database == null) {
      await _initDatabase();
    }
    
    final index = _vendors.indexWhere((v) => v.id == vendorId);
    if (index == -1) return;
    
    final vendor = _vendors[index];
    final isSelected = !vendor.isSelected;
    
    // Update in memory
    _vendors[index] = vendor.copyWith(isSelected: isSelected);
    
    // Update selected vendors list
    if (isSelected) {
      _selectedVendors.add(_vendors[index]);
    } else {
      _selectedVendors.removeWhere((v) => v.id == vendorId);
    }
    
    // Update in database
    await _database!.update(
      'vendors',
      {'isSelected': isSelected ? 1 : 0},
      where: 'id = ?',
      whereArgs: [vendorId],
    );
    
    notifyListeners();
  }
  
  void clearSelectedVendors() async {
    if (_database == null) {
      await _initDatabase();
    }
    
    // Update in memory
    _vendors = _vendors.map((v) => v.copyWith(isSelected: false)).toList();
    _selectedVendors = [];
    
    // Update in database
    await _database!.update(
      'vendors',
      {'isSelected': 0},
    );
    
    notifyListeners();
  }
  
  Future<void> _saveVendorsLocally(List<Vendor> vendors) async {
    if (_database == null) {
      await _initDatabase();
    }
    
    // Clear existing vendors
    await _database!.delete('vendors');
    
    // Insert new vendors
    for (var vendor in vendors) {
      await _database!.insert(
        'vendors',
        vendor.toJson(),
      );
    }
  }
  
  List<Vendor> _generateSampleVendors() {
    final List<Map<String, dynamic>> vendorData = [
      {
        'id': 101,
        'userId': 201,
        'name': 'Elegant Events',
        'description': 'Premium event planning for all occasions with over 10 years of experience.',
        'category': 'wedding',
        'rating': 4.8,
        'basePrice': 1500.0,
        'isVerified': true,
        'services': ['Venue booking', 'Decoration', 'Catering', 'Photography'],
      },
      {
        'id': 102,
        'userId': 202,
        'name': 'Corporate Solutions',
        'description': 'Specialized in corporate events, conferences, and business meetings.',
        'category': 'corporate',
        'rating': 4.7,
        'basePrice': 2000.0,
        'isVerified': true,
        'services': ['Venue setup', 'Technical equipment', 'Catering', 'Transportation'],
      },
      {
        'id': 103,
        'userId': 203,
        'name': 'Party Planners',
        'description': 'Making your birthday celebrations memorable with creative themes and ideas.',
        'category': 'birthday',
        'rating': 4.9,
        'basePrice': 800.0,
        'isVerified': true,
        'services': ['Theme design', 'Decoration', 'Entertainment', 'Cake & catering'],
      },
      {
        'id': 104,
        'userId': 204,
        'name': 'Wedding Paradise',
        'description': 'Creating dream weddings with attention to every detail.',
        'category': 'wedding',
        'rating': 4.9,
        'basePrice': 3000.0,
        'isVerified': true,
        'services': ['Full wedding planning', 'Decoration', 'Photography', 'Honeymoon planning'],
      },
      {
        'id': 105,
        'userId': 205,
        'name': 'Business Events Co.',
        'description': 'Professional corporate event management for companies of all sizes.',
        'category': 'corporate',
        'rating': 4.6,
        'basePrice': 2500.0,
        'isVerified': true,
        'services': ['Conference planning', 'Seminars', 'Team building', 'Corporate retreats'],
      },
      {
        'id': 106,
        'userId': 206,
        'name': 'Kids Party Experts',
        'description': 'Specializing in children\'s birthday parties with fun activities and entertainment.',
        'category': 'birthday',
        'rating': 4.8,
        'basePrice': 600.0,
        'isVerified': true,
        'services': ['Character themes', 'Games & activities', 'Party favors', 'Cake & decorations'],
      },
      {
        'id': 107,
        'userId': 207,
        'name': 'Deluxe Catering',
        'description': 'Gourmet catering services for all types of events with custom menus.',
        'category': 'wedding',
        'rating': 4.7,
        'basePrice': 1200.0,
        'isVerified': true,
        'services': ['Custom menus', 'Staff service', 'Bar service', 'Equipment rental'],
      },
      {
        'id': 108,
        'userId': 208,
        'name': 'Tech Conference Pros',
        'description': 'Specialized in technology conferences and product launches.',
        'category': 'corporate',
        'rating': 4.5,
        'basePrice': 3500.0,
        'isVerified': true,
        'services': ['Venue tech setup', 'Live streaming', 'Demo stations', 'Registration systems'],
      },
    ];
    
    return vendorData.map((data) => Vendor.fromJson(data)).toList();
  }
}
