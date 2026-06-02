import 'package:flutter/material.dart';
import '../utils/colors.dart';

class PoApprovalScreen extends StatelessWidget {
  const PoApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PoApprovalScreen'),
        backgroundColor: AppColors.primaryText,
      ),
      body: const Center(
        child: Text('PoApprovalScreen - Placeholder'),
      ),
    );
  }
}
