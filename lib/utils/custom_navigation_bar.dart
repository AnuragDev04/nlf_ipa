// custom_navigation_bar.dart
import 'package:flutter/material.dart';
import 'package:nlf/utils/colors.dart';

class CustomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      onTap: onTap,
      selectedItemColor: AppColors.primaryText,
      unselectedItemColor: AppColors.greyText,
      selectedLabelStyle: const TextStyle(
        fontWeight: FontWeight.bold,
        color: AppColors.primaryText,
        fontFamily: 'serif'
      ),
      unselectedLabelStyle: const TextStyle(
        color: AppColors.greyText,
        fontFamily: 'serif'
      ),
      backgroundColor: Colors.white,
      elevation: 10,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.group),
          label: 'Client',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.location_on),
          label: 'Site',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.more_horiz),
          label: 'More',
        ),
      ],
    );
  }
}