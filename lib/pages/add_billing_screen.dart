import 'package:flutter/material.dart';
import '../utils/colors.dart';

class AddBillingScreen extends StatelessWidget {
  const AddBillingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AddBillingScreen'),
        backgroundColor: AppColors.primaryText,
      ),
      body: const Center(
        child: Text('AddBillingScreen - Placeholder'),
      ),
    );
  }
}
