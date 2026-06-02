import 'package:flutter/material.dart';
import '../utils/colors.dart';

class QuoteApprovalScreen extends StatelessWidget {
  const QuoteApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QuoteApprovalScreen'),
        backgroundColor: AppColors.primaryText,
      ),
      body: const Center(
        child: Text('QuoteApprovalScreen - Placeholder'),
      ),
    );
  }
}
