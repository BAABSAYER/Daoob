import 'package:flutter/material.dart';

// Placeholder for future implementation
class RequestDetailScreen extends StatelessWidget {
  final int requestId;
  
  const RequestDetailScreen({super.key, required this.requestId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Details'),
      ),
      body: Center(
        child: Text('Request Details for ID: $requestId'),
      ),
    );
  }
}