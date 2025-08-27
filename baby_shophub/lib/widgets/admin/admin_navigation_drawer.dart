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
            title: Text('Manage Products'),
            onTap: () {
              // Navigate to Product Management
              Navigator.pop(context);
              Navigator.pushNamed(context, '/manage-products');
            },
          ),
          ListTile(
            title: Text('Manage Orders'),
            onTap: () {
              // Navigate to Order Management
              Navigator.pop(context);
              Navigator.pushNamed(context, '/manage-orders');
            },
          ),
          ListTile(
            title: Text('Manage Users'),
            onTap: () {
              // Navigate to User Management
              Navigator.pop(context);
              Navigator.pushNamed(context, '/manage-users');
            },
          ),
          ListTile(
            title: Text('View Analytics'),
            onTap: () {
              // Navigate to Analytics
              Navigator.pop(context);
              Navigator.pushNamed(context, '/analytics');
            },
          ),
        ],
      ),
    );
  }
}
