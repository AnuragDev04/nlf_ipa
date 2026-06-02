import 'package:flutter/material.dart';
import '../utils/colors.dart';

class SignatureScreen extends StatelessWidget {
  const SignatureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SignatureScreen'),
        backgroundColor: AppColors.primaryText,
      ),
      body: const Center(
        child: Text('SignatureScreen - Placeholder'),
      ),
    );
  }
}
