import 'package:flutter/material.dart';

class AdminNavigationDrawer extends StatelessWidget {
  const AdminNavigationDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Text(
              'Admin Menu',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          ListTile(
            title: Text('Dashboard'),
            onTap: () {
              // Navigate to Admin Dashboard
              Navigator.pop(context);
              Navigator.pushNamed(context, '/admin-dashboard');
            },
          ),
          ListTile(
            title: Text('User Management'),
            onTap: () {
              // Navigate to User Management
              Navigator.pop(context);
              Navigator.pushNamed(context, '/admin-users');
            },
          ),
          ListTile(
            title: Text('Enhanced Product Management'),
            onTap: () {
              // Navigate to Enhanced Product Management
              Navigator.pop(context);
              Navigator.pushNamed(context, '/enhanced-product-management');
            },
          ),
          ListTile(
            title: Text('Data Export/Import'),
            onTap: () {
              // Navigate to Data Export/Import
              Navigator.pop(context);
              Navigator.pushNamed(context, '/data-export-import');
            },
          ),
          ListTile(
            title: Text('Order Management'),
            onTap: () {
              // Navigate to Order Management
              Navigator.pop(context);
              Navigator.pushNamed(context, '/admin-orders');
            },
          ),
          ListTile(
            title: Text('Reports'),
            onTap: () {
              // Navigate to Reports
              Navigator.pop(context);
              Navigator.pushNamed(context, '/reports');
            },
          ),
        ],
      ),
    );
  }
}
