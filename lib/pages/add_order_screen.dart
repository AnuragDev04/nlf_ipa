import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/colors.dart';

class AddOrderScreen extends StatelessWidget {
  const AddOrderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('New Order', style: GoogleFonts.lora(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryText,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_shopping_cart_rounded, size: 64, color: AppColors.primaryText.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              'Create New Order',
              style: GoogleFonts.lora(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Fill in the details to generate a new order.',
              style: GoogleFonts.lora(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
