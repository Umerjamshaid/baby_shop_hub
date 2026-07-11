import 'package:flutter/material.dart';

class ReviewsAnalyticsScreen extends StatefulWidget {
  const ReviewsAnalyticsScreen({super.key});

  @override
  State<ReviewsAnalyticsScreen> createState() => _ReviewsAnalyticsScreenState();
}

class _ReviewsAnalyticsScreenState extends State<ReviewsAnalyticsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reviews Analytics')),
      body: const Center(child: Text('Reviews analytics coming soon...')),
    );
  }
}
