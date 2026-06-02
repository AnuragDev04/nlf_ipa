import 'package:flutter/material.dart';
import '../utils/colors.dart';

class StageScreen extends StatelessWidget {
  const StageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('StageScreen'),
        backgroundColor: AppColors.primaryText,
      ),
      body: const Center(
        child: Text('StageScreen - Placeholder'),
      ),
    );
  }
}
