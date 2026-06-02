import 'package:flutter/material.dart';
import '../utils/colors.dart';

class TenderScreen extends StatelessWidget {
  const TenderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TenderScreen'),
        backgroundColor: AppColors.primaryText,
      ),
      body: const Center(
        child: Text('TenderScreen - Placeholder'),
      ),
    );
  }
}
