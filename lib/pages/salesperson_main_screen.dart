import 'package:flutter/material.dart';
import '../utils/colors.dart';

class SalespersonMainScreen extends StatelessWidget {
  const SalespersonMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SalespersonMainScreen'),
        backgroundColor: AppColors.primaryText,
      ),
      body: const Center(
        child: Text('SalespersonMainScreen - Placeholder'),
      ),
    );
  }
}
