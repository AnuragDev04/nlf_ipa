import 'package:flutter/material.dart';
import '../utils/colors.dart';

class SegmentScreen extends StatelessWidget {
  const SegmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SegmentScreen'),
        backgroundColor: AppColors.primaryText,
      ),
      body: const Center(
        child: Text('SegmentScreen - Placeholder'),
      ),
    );
  }
}
