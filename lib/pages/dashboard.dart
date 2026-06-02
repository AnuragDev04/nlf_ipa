import 'package:flutter/material.dart';
import 'package:nlf/pages/attendance_main_screen.dart';
import 'package:nlf/pages/client_screen1.dart';
import 'package:nlf/pages/home_screen.dart';
import 'package:nlf/pages/more_screen.dart';
import 'package:nlf/pages/site_screen.dart';

import 'home_screen2.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    HomeScreen(),
    ClientScreen1(),
    SiteScreen(),
    MoreScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
    );
  }
}

