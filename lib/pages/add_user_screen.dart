import 'package:flutter/material.dart';
import '../utils/colors.dart';

class AddUserScreen extends StatelessWidget {
  const AddUserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AddUserScreen'),
        backgroundColor: AppColors.primaryText,
      ),
      body: const Center(
        child: Text('AddUserScreen - Placeholder'),
      ),
    );
  }
}
