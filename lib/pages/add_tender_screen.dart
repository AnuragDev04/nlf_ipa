import 'package:flutter/material.dart';
import '../utils/colors.dart';

class AddTenderScreen extends StatelessWidget {
  const AddTenderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AddTenderScreen'),
        backgroundColor: AppColors.primaryText,
      ),
      body: const Center(
        child: Text('AddTenderScreen - Placeholder'),
      ),
    );
  }
}
