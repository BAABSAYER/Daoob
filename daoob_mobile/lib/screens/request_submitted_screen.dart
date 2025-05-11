import 'package:flutter/material.dart';
import 'event_selection_screen.dart';
import 'package:intl/intl.dart';

class RequestSubmittedScreen extends StatelessWidget {
  final Map<String, dynamic> eventRequest;
  final String eventTypeName;
  
  const RequestSubmittedScreen({
    Key? key, 
    required this.eventRequest,
    required this.eventTypeName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final createdAt = eventRequest['createdAt'] != null 
        ? DateFormat('MMM d, yyyy').format(DateTime.parse(eventRequest['createdAt']))
        : 'N/A';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Submitted'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Spacer(),
              Icon(
                Icons.check_circle_outline,
                size: 120,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 32),
              Text(
                'Event Request Submitted!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Thank you for submitting your $eventTypeName event request.',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Request ID:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text('#${eventRequest['id']}'),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Submitted on:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(createdAt),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Status:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Chip(
                            label: const Text('Pending'),
                            backgroundColor: Colors.amber[100],
                            labelStyle: TextStyle(color: Colors.amber[800]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Our team will review your request and provide a quotation soon. You can check the status of your request in the "My Requests" section.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => const EventSelectionScreen(),
                    ),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Return to Home'),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}