import 'package:flutter/material.dart';
import '../utils/colors.dart';

class UserRegistrationScreen extends StatelessWidget {
  const UserRegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('UserRegistrationScreen'),
        backgroundColor: AppColors.primaryText,
      ),
      body: const Center(
        child: Text('UserRegistrationScreen - Placeholder'),
      ),
    );
  }
}
