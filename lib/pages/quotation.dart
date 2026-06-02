import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/colors.dart';

class QuotationsScreen extends StatelessWidget {
  const QuotationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quotations', style: GoogleFonts.lora(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryText,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description_rounded, size: 64, color: AppColors.primaryText.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              'Quotations List',
              style: GoogleFonts.lora(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'View and manage all your quotes and proposals here.',
              style: GoogleFonts.lora(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
