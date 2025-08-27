import 'package:flutter/material.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('Analytics Dashboard', style: TextStyle(fontSize: 24)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // View total sales
              },
              child: const Text('Total Sales'),
            ),
            ElevatedButton(
              onPressed: () {
                // View popular products
              },
              child: const Text('Popular Products'),
            ),
            ElevatedButton(
              onPressed: () {
                // View revenue trends
              },
              child: const Text('Revenue Trends'),
            ),
          ],
        ),
      ),
    );
  }
}
