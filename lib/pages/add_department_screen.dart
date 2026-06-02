import 'package:flutter/material.dart';
import '../utils/colors.dart';

class AddDepartmentScreen extends StatelessWidget {
  const AddDepartmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AddDepartmentScreen'),
        backgroundColor: AppColors.primaryText,
      ),
      body: const Center(
        child: Text('AddDepartmentScreen - Placeholder'),
      ),
    );
  }
}
