import 'package:flutter/material.dart';
import '../utils/colors.dart';

class LeadGenerationScreen extends StatelessWidget {
  const LeadGenerationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LeadGenerationScreen'),
        backgroundColor: AppColors.primaryText,
      ),
      body: const Center(
        child: Text('LeadGenerationScreen - Placeholder'),
      ),
    );
  }
}
