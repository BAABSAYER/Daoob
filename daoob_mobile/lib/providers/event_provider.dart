import 'package:flutter/material.dart';

class EventCategory {
  final String id;
  final String name;
  final String nameAr;
  final String description;
  final String descriptionAr;
  final IconData icon;
  
  EventCategory({
    required this.id,
    required this.name,
    required this.nameAr,
    required this.description,
    required this.descriptionAr,
    required this.icon,
  });
}

class EventProvider extends ChangeNotifier {
  String? _selectedCategory;
  final List<EventCategory> _categories = [
    EventCategory(
      id: 'wedding',
      name: 'Wedding',
      nameAr: 'زفاف',
      description: 'Plan your perfect wedding day',
      descriptionAr: 'خطط ليوم زفافك المثالي',
      icon: Icons.favorite,
    ),
    EventCategory(
      id: 'corporate',
      name: 'Corporate',
      nameAr: 'شركات',
      description: 'Professional events for business',
      descriptionAr: 'فعاليات احترافية للأعمال',
      icon: Icons.business,
    ),
    EventCategory(
      id: 'birthday',
      name: 'Birthday',
      nameAr: 'أعياد ميلاد',
      description: 'Celebrate your special day',
      descriptionAr: 'احتفل بيومك المميز',
      icon: Icons.cake,
    ),
    EventCategory(
      id: 'conference',
      name: 'Conference',
      nameAr: 'مؤتمر',
      description: 'Organize professional conferences',
      descriptionAr: 'نظم مؤتمرات احترافية',
      icon: Icons.people,
    ),
    EventCategory(
      id: 'party',
      name: 'Party',
      nameAr: 'حفلة',
      description: 'Host unforgettable parties',
      descriptionAr: 'استضف حفلات لا تُنسى',
      icon: Icons.celebration,
    ),
    EventCategory(
      id: 'custom',
      name: 'Custom Event',
      nameAr: 'مناسبة مخصصة',
      description: 'Create your unique event',
      descriptionAr: 'أنشئ مناسبتك الفريدة',
      icon: Icons.edit,
    ),
  ];
  
  String? get selectedCategory => _selectedCategory;
  List<EventCategory> get categories => _categories;
  
  void selectCategory(String categoryId) {
    _selectedCategory = categoryId;
    notifyListeners();
  }
  
  EventCategory? getCategoryById(String id) {
    try {
      return _categories.firstWhere((category) => category.id == id);
    } catch (e) {
      return null;
    }
  }
}
