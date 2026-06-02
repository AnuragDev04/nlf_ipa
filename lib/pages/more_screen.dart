// home_screen.dart
import 'package:flutter/material.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MORE OPTIONS',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 30),

              // Menu Items
              Expanded(
                child: ListView(
                  children: [
                    _buildMenuItem(
                      icon: Icons.person,
                      title: 'Profile Settings',
                      subtitle: 'Manage your account',
                      onTap: () {},
                    ),
                    _buildMenuItem(
                      icon: Icons.notifications,
                      title: 'Notifications',
                      subtitle: 'Notification preferences',
                      onTap: () {},
                    ),
                    _buildMenuItem(
                      icon: Icons.security,
                      title: 'Security',
                      subtitle: 'Password & security settings',
                      onTap: () {},
                    ),
                    _buildMenuItem(
                      icon: Icons.help,
                      title: 'Help & Support',
                      subtitle: 'Get help and contact support',
                      onTap: () {},
                    ),
                    _buildMenuItem(
                      icon: Icons.info,
                      title: 'About',
                      subtitle: 'App version and info',
                      onTap: () {},
                    ),
                    _buildMenuItem(
                      icon: Icons.logout,
                      title: 'Logout',
                      subtitle: 'Sign out of your account',
                      onTap: () {},
                      isDestructive: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 15),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDestructive ? Colors.red[100] : Colors.blue[100],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: isDestructive ? Colors.red[600] : Colors.blue[600],
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDestructive ? Colors.red[600] : Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.grey[600]),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey[400],
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        tileColor: Colors.white,
      ),
    );
  }
}