import 'package:flutter/material.dart';

class EventCategory {
  final String id;
  final String name;
  final String nameAr;
  final String description;
  final String descriptionAr;
  final IconData icon;
  final String imagePath;

  EventCategory({
    required this.id,
    required this.name,
    required this.nameAr,
    required this.description,
    required this.descriptionAr,
    required this.icon,
    required this.imagePath,
  });
}

class EventProvider extends ChangeNotifier {
  String _selectedCategory = '';
  
  String get selectedCategory => _selectedCategory;

  final List<EventCategory> _categories = [
    EventCategory(
      id: 'wedding',
      name: 'Wedding',
      nameAr: 'زفاف',
      description: 'Plan your perfect wedding day with our premium vendors',
      descriptionAr: 'خطط ليوم زفافك المثالي مع مزودي خدماتنا المميزين',
      icon: Icons.favorite,
      imagePath: 'assets/images/wedding.jpg',
    ),
    EventCategory(
      id: 'corporate',
      name: 'Corporate',
      nameAr: 'شركات',
      description: 'Professional event management for business functions',
      descriptionAr: 'إدارة احترافية للمناسبات التجارية',
      icon: Icons.business,
      imagePath: 'assets/images/corporate.jpg',
    ),
    EventCategory(
      id: 'birthday',
      name: 'Birthday',
      nameAr: 'أعياد ميلاد',
      description: 'Make your birthday celebration special',
      descriptionAr: 'اجعل احتفال عيد ميلادك مميزًا',
      icon: Icons.cake,
      imagePath: 'assets/images/birthday.jpg',
    ),
    EventCategory(
      id: 'conference',
      name: 'Conference',
      nameAr: 'مؤتمرات',
      description: 'Organize successful conferences and seminars',
      descriptionAr: 'نظم مؤتمرات وندوات ناجحة',
      icon: Icons.people,
      imagePath: 'assets/images/conference.jpg',
    ),
    EventCategory(
      id: 'party',
      name: 'Party',
      nameAr: 'حفلات',
      description: 'Host amazing parties for any occasion',
      descriptionAr: 'استضف حفلات مذهلة لأي مناسبة',
      icon: Icons.celebration,
      imagePath: 'assets/images/party.jpg',
    ),
    EventCategory(
      id: 'custom',
      name: 'Custom Event',
      nameAr: 'مناسبة مخصصة',
      description: 'Create a personalized event just for you',
      descriptionAr: 'أنشئ مناسبة مخصصة خاصة بك',
      icon: Icons.edit,
      imagePath: 'assets/images/custom.jpg',
    ),
  ];

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
