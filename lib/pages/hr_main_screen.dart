import 'package:flutter/material.dart';
import 'package:nlf/pages/recruitment_process.dart';
import 'package:nlf/utils/colors.dart';
import 'attendance_screen.dart';
import 'claim.dart';
import 'employee.dart';
import 'leave_approvals.dart';
import 'onboarding.dart' hide AppColors;

// hr_screen.dart
class HrMainScreen extends StatelessWidget {
  const HrMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          "HR MANAGEMENT",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontFamily: 'serif',
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 40,
        titleSpacing: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dashboard Section - Welcome and Overview
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    //colors: [Colors.indigo[600]!, Colors.indigo[800]!],
                    colors: [AppColors.primaryText, AppColors.error],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome to HR Dashboard',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'serif',
                      ),
                    ),
                    SizedBox(height: 15),
                    // Quick Stats - Key Metrics
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Total Employees',
                            '248',
                            Colors.white,
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: _buildStatCard(
                            'New Hires This Month',
                            '12',
                            Colors.green[300]!,
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: _buildStatCard(
                            'Pending Leave Requests',
                            '8',
                            Colors.orange[300]!,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(height: 25),

              // Notifications & Pending Actions
              Text(
                'Notifications & Pending Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontFamily: 'serif',
                ),
              ),
              SizedBox(height: 15),

              // ✅ Updated: Added onTap to navigate to LeaveApprovalsScreen
              _buildNotificationCard(
                'Pending Leave Approvals (for managers)',
                '5 requests waiting for your approval',
                Icons.pending_actions,
                Colors.orange,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LeaveApprovalsScreen(),
                    ),
                  );
                },
              ),
              SizedBox(height: 10),

              _buildNotificationCard(
                'Upcoming Birthdays',
                '3 employee birthdays this week',
                Icons.cake,
                Colors.pink,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Upcoming Birthdays clicked")),
                  );
                },
              ),
              SizedBox(height: 10),

              _buildNotificationCard(
                'Time to Submit Timesheet',
                '12 employees need to submit timesheets',
                Icons.schedule,
                Colors.blue,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Timesheet reminder clicked")),
                  );
                },
              ),

              SizedBox(height: 25),

              // Quick Access Shortcuts
              Row(
                children: [
                  Text(
                    'Quick Access',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      fontFamily: 'serif',
                    ),
                  ),
                  SizedBox(width: 10),
                ],
              ),

              SizedBox(height: 20),

              // Quick Action Buttons
              Row(
                children: [
                  Expanded(
                    child: _buildQuickActionButton(
                      'Request Leave',
                      Icons.event_available,
                      Colors.green,
                      () {
                        // Handle Request Leave
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Request Leave clicked")),
                        );
                      },
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: _buildQuickActionButton(
                      'Log a Claim',
                      Icons.receipt_long,
                      Colors.blue,
                      () {
                        // Handle Log a Claim
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Log a Claim clicked")),
                        );
                      },
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: _buildQuickActionButton(
                      'Add New Candidate',
                      Icons.person_add,
                      Colors.purple,
                      () {
                        // Handle Add New Candidate
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Add New Candidate clicked")),
                        );
                      },
                    ),
                  ),
                ],
              ),

              SizedBox(height: 30),

              // HR Modules Section
              Text(
                'Others',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontFamily: 'serif',
                ),
              ),

              SizedBox(height: 20),

              // HR Module Cards (6 Cards)
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 1.1,
                children: [
                  HRModuleCard(
                    title: 'Recruitment\nProcess',
                    icon: Icons.group_add,
                    color: Colors.blue[600]!,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RecruitmentProcessScreen(),
                        ),
                      );
                    },
                  ),
                  HRModuleCard(
                    title: 'Add Onboard\nEmployee',
                    icon: Icons.person_add_alt_1,
                    color: Colors.green[600]!,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OnboardingScreen(),
                        ),
                      );
                    },
                  ),
                  HRModuleCard(
                    title: 'Employee',
                    icon: Icons.badge,
                    color: Colors.orange[600]!,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EmployeeScreen(),
                        ),
                      );
                    },
                  ),
                  // ✅ Employee Claim Card - Now navigates to ClaimsScreen
                  HRModuleCard(
                    title: 'Employee\nClaim',
                    icon: Icons.receipt,
                    color: Colors.purple[600]!,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ClaimsScreen()),
                      );
                    },
                  ),
                  HRModuleCard(
                    title: 'Employee Attendance\n& Working Hours',
                    icon: Icons.access_time,
                    color: Colors.teal[600]!,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AttendanceScreen(),
                        ),
                      );
                    },
                  ),
                  HRModuleCard(
                    title: 'Leave',
                    icon: Icons.event_available,
                    color: Colors.red[600]!,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LeaveApprovalsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),

              SizedBox(height: 0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color valueColor) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: valueColor,
              fontFamily: 'serif',
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ✅ Updated: Added optional onTap parameter to make notification cards clickable
  Widget _buildNotificationCard(
    String title,
    String subtitle,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey[300]!,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      fontFamily: 'serif',
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          SizedBox(height: 5),
          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: 'serif',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// HR Module Card Widget
class HRModuleCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const HRModuleCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey[300]!,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            SizedBox(height: 15),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                height: 1.2,
                fontFamily: 'serif',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
