import 'package:flutter/foundation.dart';
import 'package:eventora_app/models/booking.dart';
import 'package:eventora_app/services/api_service.dart';

class BookingService extends ChangeNotifier {
  List<Booking> _bookings = [];
  Booking? _selectedBooking;
  bool _isLoading = false;
  String? _error;
  
  List<Booking> get bookings => _bookings;
  Booking? get selectedBooking => _selectedBooking;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // Fetch user's bookings
  Future<void> fetchUserBookings() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final data = await ApiService.get('/api/bookings');
      
      final List<dynamic> bookingsJson = data is List ? data : [data];
      _bookings = bookingsJson.map((json) => Booking.fromJson(json)).toList();
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      debugPrint('Error fetching bookings: $e');
    }
  }
  
  // Fetch a single booking
  Future<void> fetchBookingById(int bookingId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final data = await ApiService.get('/api/bookings/$bookingId');
      _selectedBooking = Booking.fromJson(data);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
      debugPrint('Error fetching booking: $e');
    }
  }
  
  // Create a new booking
  Future<Booking> createBooking({
    required int vendorId,
    int? serviceId,
    required String eventType,
    required DateTime eventDate,
    int? guestCount,
    String? specialRequests,
    String? packageType,
  }) async {
    try {
      final bookingData = {
        'vendorId': vendorId,
        'serviceId': serviceId,
        'eventType': eventType,
        'eventDate': eventDate.toIso8601String(),
        'guestCount': guestCount,
        'specialRequests': specialRequests,
        'packageType': packageType,
      };
      
      final data = await ApiService.post('/api/bookings', bookingData);
      final booking = Booking.fromJson(data);
      
      // Update the local bookings list
      _bookings.add(booking);
      notifyListeners();
      
      return booking;
    } catch (e) {
      debugPrint('Error creating booking: $e');
      rethrow;
    }
  }
  
  // Update a booking
  Future<Booking> updateBooking({
    required int bookingId,
    String? status,
    String? specialRequests,
    DateTime? eventDate,
    int? guestCount,
  }) async {
    try {
      final updateData = {
        if (status != null) 'status': status,
        if (specialRequests != null) 'specialRequests': specialRequests,
        if (eventDate != null) 'eventDate': eventDate.toIso8601String(),
        if (guestCount != null) 'guestCount': guestCount,
      };
      
      final data = await ApiService.put('/api/bookings/$bookingId', updateData);
      final updatedBooking = Booking.fromJson(data);
      
      // Update the local booking lists
      final index = _bookings.indexWhere((b) => b.id == bookingId);
      if (index != -1) {
        _bookings[index] = updatedBooking;
      }
      
      if (_selectedBooking?.id == bookingId) {
        _selectedBooking = updatedBooking;
      }
      
      notifyListeners();
      
      return updatedBooking;
    } catch (e) {
      debugPrint('Error updating booking: $e');
      rethrow;
    }
  }
  
  // Cancel a booking
  Future<void> cancelBooking(int bookingId) async {
    try {
      await updateBooking(
        bookingId: bookingId, 
        status: 'cancelled',
      );
    } catch (e) {
      debugPrint('Error cancelling booking: $e');
      rethrow;
    }
  }
  
  // Filter bookings by status
  List<Booking> getBookingsByStatus(String status) {
    return _bookings.where((booking) => 
      booking.status.toLowerCase() == status.toLowerCase()
    ).toList();
  }
  
  // Get upcoming bookings (event date is in the future)
  List<Booking> getUpcomingBookings() {
    final now = DateTime.now();
    return _bookings.where((booking) => 
      booking.eventDate.isAfter(now) && booking.status.toLowerCase() != 'cancelled'
    ).toList();
  }
  
  // Get past bookings (event date is in the past)
  List<Booking> getPastBookings() {
    final now = DateTime.now();
    return _bookings.where((booking) => 
      booking.eventDate.isBefore(now) || booking.status.toLowerCase() == 'completed'
    ).toList();
  }
  
  // Clear selected booking
  void clearSelectedBooking() {
    _selectedBooking = null;
    notifyListeners();
  }
  
  // Set selected booking (useful when navigating from a list)
  void setSelectedBooking(Booking booking) {
    _selectedBooking = booking;
    notifyListeners();
  }
}