import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/colors.dart';

class SiteScreen extends StatelessWidget {
  const SiteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sites', style: GoogleFonts.lora(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryText,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction_rounded, size: 64, color: AppColors.primaryText.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              'Site Management',
              style: GoogleFonts.lora(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Manage your active sites and construction progress here.',
              style: GoogleFonts.lora(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
