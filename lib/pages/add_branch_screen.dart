import 'package:flutter/material.dart';
import '../utils/colors.dart';

class AddBranchScreen extends StatelessWidget {
  const AddBranchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AddBranchScreen'),
        backgroundColor: AppColors.primaryText,
      ),
      body: const Center(
        child: Text('AddBranchScreen - Placeholder'),
      ),
    );
  }
}
