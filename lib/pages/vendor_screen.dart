import 'package:flutter/material.dart';
import '../utils/colors.dart';

class VendorScreen extends StatelessWidget {
  const VendorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VendorScreen'),
        backgroundColor: AppColors.primaryText,
      ),
      body: const Center(
        child: Text('VendorScreen - Placeholder'),
      ),
    );
  }
}
