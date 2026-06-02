import 'package:flutter/material.dart';
import '../utils/colors.dart';

class DeliveryMemoDirectAddScreen extends StatelessWidget {
  const DeliveryMemoDirectAddScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DeliveryMemoDirectAddScreen'),
        backgroundColor: AppColors.primaryText,
      ),
      body: const Center(
        child: Text('DeliveryMemoDirectAddScreen - Placeholder'),
      ),
    );
  }
}
