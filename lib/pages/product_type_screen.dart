import 'package:flutter/material.dart';
import '../utils/colors.dart';

class ProductTypeScreen extends StatelessWidget {
  const ProductTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ProductTypeScreen'),
        backgroundColor: AppColors.primaryText,
      ),
      body: const Center(
        child: Text('ProductTypeScreen - Placeholder'),
      ),
    );
  }
}
