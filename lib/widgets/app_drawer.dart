import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Text('Menu'),
          ),
           ListTile(
             title: const Text('Overview'),
             onTap: () {
              Navigator.pop(context); // Close the drawer
              Navigator.pushNamed(context, '/overview');
             },
           ),
           ListTile(
             title: const Text('Create new counter'),
             onTap: () {
              Navigator.pop(context); // Close the drawer
              Navigator.pushNamed(context, '/createEditCounter');
             },
           ),
           ListTile(
             title: const Text('Manage counters'),
             onTap: () {
               // Close the drawer
               Navigator.pop(context);
              Navigator.pushNamed(context, '/manageCounters');
             },
           ),
           ListTile(
             title: const Text('Manage overviews'),
             onTap: () {
               // Close the drawer
               Navigator.pop(context);
               // Navigate to manage overviews screen
             },
           ),
           ListTile(
             title: const Text('About'),
             onTap: () {
               // Close the drawer
               Navigator.pop(context);
               // Navigate to about screen
             },
           ),
        ],
      ),
    );
  }
}