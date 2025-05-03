import 'package:flutter/foundation.dart';
import 'package:eventora_app/models/vendor.dart';
import 'package:eventora_app/models/service.dart';
import 'package:eventora_app/models/review.dart';
import 'package:eventora_app/services/api_service.dart';

class VendorService extends ChangeNotifier {
  List<Vendor> _vendors = [];
  Vendor? _selectedVendor;
  bool _isLoading = false;
  String? _error;
  
  List<Vendor> get vendors => _vendors;
  Vendor? get selectedVendor => _selectedVendor;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Fetch all vendors
  Future<void> fetchVendors({String? category, String? searchQuery}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      String endpoint = '/api/vendors';
      
      // Add query parameters if they exist
      if (category != null || searchQuery != null) {
        List<String> params = [];
        if (category != null) params.add('category=$category');
        if (searchQuery != null) params.add('query=$searchQuery');
        endpoint += '?${params.join('&')}';
      }
      
      final data = await ApiService.get(endpoint);
      
      // Parse the JSON data into a list of Vendor objects
      final List<dynamic> vendorsJson = data is List ? data : [data];
      _vendors = vendorsJson.map((json) => Vendor.fromJson(json)).toList();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      debugPrint('Error fetching vendors: $e');
    }
  }
  
  // Fetch a single vendor by ID
  Future<void> fetchVendorById(int vendorId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final data = await ApiService.get('/api/vendors/$vendorId');
      _selectedVendor = Vendor.fromJson(data);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      debugPrint('Error fetching vendor: $e');
    }
  }
  
  // Fetch vendor services
  Future<List<Service>> fetchVendorServices(int vendorId) async {
    try {
      final data = await ApiService.get('/api/vendors/$vendorId/services');
      
      final List<dynamic> servicesJson = data is List ? data : [data];
      return servicesJson.map((json) => Service.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching vendor services: $e');
      rethrow;
    }
  }
  
  // Fetch vendor reviews
  Future<List<Review>> fetchVendorReviews(int vendorId) async {
    try {
      final data = await ApiService.get('/api/vendors/$vendorId/reviews');
      
      final List<dynamic> reviewsJson = data is List ? data : [data];
      return reviewsJson.map((json) => Review.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching vendor reviews: $e');
      rethrow;
    }
  }
  
  // Get featured vendors
  Future<List<Vendor>> fetchFeaturedVendors() async {
    try {
      final data = await ApiService.get('/api/vendors/featured');
      
      final List<dynamic> vendorsJson = data is List ? data : [data];
      return vendorsJson.map((json) => Vendor.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching featured vendors: $e');
      rethrow;
    }
  }
  
  // Clear selected vendor
  void clearSelectedVendor() {
    _selectedVendor = null;
    notifyListeners();
  }
  
  // Set selected vendor (useful when navigating from a list)
  void setSelectedVendor(Vendor vendor) {
    _selectedVendor = vendor;
    notifyListeners();
  }
}