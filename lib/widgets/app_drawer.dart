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
             title: const Text('Create new tracker'),
             onTap: () {
              Navigator.pop(context); // Close the drawer
              Navigator.pushNamed(context, '/createEditTracker');
             },
           ),
           ListTile(
             title: const Text('Manage trackers'),
             onTap: () {
               // Close the drawer
               Navigator.pop(context);
              Navigator.pushNamed(context, '/manageTrackers');
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
             title: const Text('Extra options'),
             onTap: () {
               // Close the drawer
               Navigator.pop(context);
              Navigator.pushNamed(context, '/extraOptions');
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