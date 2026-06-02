import 'package:flutter/material.dart';
import '../utils/colors.dart';

class UnitScreen extends StatelessWidget {
  const UnitScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('UnitScreen'),
        backgroundColor: AppColors.primaryText,
      ),
      body: const Center(
        child: Text('UnitScreen - Placeholder'),
      ),
    );
  }
}
