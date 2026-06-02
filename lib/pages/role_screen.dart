import 'package:flutter/material.dart';
import '../utils/colors.dart';

class RoleScreen extends StatelessWidget {
  const RoleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RoleScreen'),
        backgroundColor: AppColors.primaryText,
      ),
      body: const Center(
        child: Text('RoleScreen - Placeholder'),
      ),
    );
  }
}
