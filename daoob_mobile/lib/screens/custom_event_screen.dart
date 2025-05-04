import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:daoob_mobile/l10n/language_provider.dart';

class CustomEventScreen extends StatefulWidget {
  const CustomEventScreen({super.key});

  @override
  State<CustomEventScreen> createState() => _CustomEventScreenState();
}

class _CustomEventScreenState extends State<CustomEventScreen> {
  final _eventNameController = TextEditingController();
  final _eventDescriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 30));
  int _guestCount = 50;
  String _selectedBudget = 'Medium';
  final List<String> _budgetOptions = ['Low', 'Medium', 'High', 'Very High'];

  @override
  void dispose() {
    _eventNameController.dispose();
    _eventDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);
    final bool isArabic = languageProvider.locale.languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isArabic ? 'حدث مخصص' : 'Custom Event',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF6A3DE8),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isArabic
                  ? 'أخبرنا عن حدثك المخصص'
                  : 'Tell us about your custom event',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _eventNameController,
              decoration: InputDecoration(
                labelText: isArabic ? 'اسم الحدث' : 'Event Name',
                hintText: isArabic ? 'أدخل اسم الحدث' : 'Enter event name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _eventDescriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: isArabic ? 'وصف الحدث' : 'Event Description',
                hintText: isArabic
                    ? 'أدخل تفاصيل عن الحدث الخاص بك'
                    : 'Enter details about your event',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(isArabic ? 'تاريخ الحدث' : 'Event Date'),
              subtitle: Text(
                '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
              ),
              trailing: IconButton(
                icon: const Icon(Icons.calendar_today),
                onPressed: () => _selectDate(context),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isArabic ? 'عدد الضيوف' : 'Number of Guests',
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Slider(
              value: _guestCount.toDouble(),
              min: 10,
              max: 500,
              divisions: 49,
              label: _guestCount.toString(),
              onChanged: (value) {
                setState(() {
                  _guestCount = value.toInt();
                });
              },
            ),
            Center(
              child: Text(
                '$_guestCount ${isArabic ? 'ضيف' : 'guests'}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isArabic ? 'الميزانية' : 'Budget',
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedBudget,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              items: _budgetOptions.map((String budget) {
                return DropdownMenuItem<String>(
                  value: budget,
                  child: Text(budget),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedBudget = value!;
                });
              },
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6A3DE8),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  // Submit custom event
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isArabic
                            ? 'تم إنشاء الحدث المخصص بنجاح!'
                            : 'Custom event created successfully!',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pop(context);
                },
                child: Text(
                  isArabic ? 'إنشاء حدث' : 'Create Event',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
