import 'package:flutter/material.dart';
import '../utils/colors.dart';

class PoDirectAddScreen extends StatelessWidget {
  const PoDirectAddScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PoDirectAddScreen'),
        backgroundColor: AppColors.primaryText,
      ),
      body: const Center(
        child: Text('PoDirectAddScreen - Placeholder'),
      ),
    );
  }
}
