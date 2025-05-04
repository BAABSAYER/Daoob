import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:daoob_mobile/l10n/language_provider.dart';
import 'package:daoob_mobile/providers/event_provider.dart';
import 'package:daoob_mobile/models/vendor.dart';

class VendorsScreen extends StatelessWidget {
  final String categoryId;
  
  const VendorsScreen({super.key, required this.categoryId});

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final eventProvider = Provider.of<EventProvider>(context);
    final category = eventProvider.getCategoryById(categoryId);
    final bool isArabic = languageProvider.locale.languageCode == 'ar';

    // Mock vendors list
    final vendors = [
      Vendor(
        id: 1,
        userId: 101,
        name: 'Elegant Events',
        description: 'Premium event planning service for all occasions',
        category: categoryId,
        rating: 4.8,
        basePrice: 1200,
        isVerified: true,
      ),
      Vendor(
        id: 2,
        userId: 102,
        name: 'Delicious Catering',
        description: 'Gourmet food catering services for events of all sizes',
        category: categoryId,
        rating: 4.6,
        basePrice: 800,
        isVerified: true,
      ),
      Vendor(
        id: 3,
        userId: 103,
        name: 'Photography Masters',
        description: 'Capturing your special moments with artistic photography',
        category: categoryId,
        rating: 4.9,
        basePrice: 600,
        isVerified: true,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          category != null
              ? isArabic
                  ? category.nameAr
                  : category.name
              : isArabic
                  ? 'مزودي الخدمات'
                  : 'Vendors',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF6A3DE8),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isArabic
                  ? 'اختر مزود الخدمة المناسب'
                  : 'Choose the right vendor',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isArabic
                  ? 'استعرض قائمة مزودي الخدمات المميزين'
                  : 'Browse our list of premium vendors',
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: vendors.length,
                itemBuilder: (context, index) {
                  final vendor = vendors[index];
                  return _buildVendorCard(context, vendor, isArabic);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVendorCard(BuildContext context, Vendor vendor, bool isArabic) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 3,
      child: InkWell(
        onTap: () {
          // Navigate to vendor detail page
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF6A3DE8).withOpacity(0.2),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.business,
                  size: 60,
                  color: const Color(0xFF6A3DE8).withOpacity(0.7),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          vendor.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            vendor.rating.toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    vendor.description,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${isArabic ? 'يبدأ من' : 'Starting at'} \$${vendor.basePrice}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6A3DE8),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          // Book now
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6A3DE8),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          isArabic ? 'احجز الآن' : 'Book Now',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
