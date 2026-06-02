import 'package:flutter/material.dart';
import '../utils/colors.dart';

class QuotationDetailsScreen extends StatelessWidget {
  const QuotationDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QuotationDetailsScreen'),
        backgroundColor: AppColors.primaryText,
      ),
      body: const Center(
        child: Text('QuotationDetailsScreen - Placeholder'),
      ),
    );
  }
}
