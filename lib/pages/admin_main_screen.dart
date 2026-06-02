import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/colors.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Panel', style: GoogleFonts.lora(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryText,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.admin_panel_settings_rounded, size: 64, color: AppColors.primaryText.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              'Admin Settings',
              style: GoogleFonts.lora(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Configure users, roles, and global application settings.',
              style: GoogleFonts.lora(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
