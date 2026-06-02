import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nlf/pages/admin_main_screen.dart';
import 'package:nlf/pages/quotation.dart';
import 'package:nlf/pages/tender_screen.dart';
import '../utils/colors.dart';
import 'attendance_screen.dart';
import 'leave_approvals.dart';
import 'new_claim_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === HEADER WITH OVERLAY ===
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Purple Gradient Header
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primaryText, AppColors.primaryText],
                      //colors: [Colors.red, Colors.red[100]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Welcome Admin",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'serif',
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _showChangeLocationDialog(context),
                            child: Icon(
                              Icons.account_circle,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 80), // space for overlap card
                    ],
                  ),
                ),

                // Stats Card Overlay - FIXED VERSION
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: -150, // pushes half outside
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    // FIXED: Manual Row approach for perfect spacing
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                              child: _buildStat(
                                "24",
                                "Pending PO Approval",
                                AppColors.primaryLight,
                                Colors.black,
                                Icons.pending_actions,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: _buildStat(
                                "6",
                                "Working Sites",
                                AppColors.primaryLight,
                                Color(0xFF1B5E20),
                                Icons.construction,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                              child: _buildStat(
                                "3400",
                                "Stock Available",
                                AppColors.primaryLight,
                                Color(0xFFE65100),
                                Icons.inventory_2,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: _buildStat(
                                "8000000",
                                "Balance Payment",
                                AppColors.primaryLight,
                                Color(0xFF4A148C),
                                Icons.account_balance_wallet,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 150),
            _buildSectionHeader("Lead Generation"),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      // Navigate to TenderList page
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => TenderScreen()),
                        //MaterialPageRoute(builder: (context) => AddTenderScreen()),
                      );
                    },
                    child: _buildRoom(
                      "Tenders",
                      "All Tender Details",
                      "",
                      Icons.note_alt_outlined,
                    ),
                  ),
                ),
                Expanded(
                  child: _buildRoom(
                    "Clients",
                    "All Client Details",
                    "",
                    Icons.people_alt_outlined,
                  ),
                ),
              ],
            ),
            SizedBox(height: 0), // spacing after overlay card
            // === QUICK ACTION (NO HORIZONTAL SCROLL) - FIXED OVERFLOW ===
            _buildSectionHeader("Quick Action"),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                height: 300, // Increased height to prevent overflow for 3 rows
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Row 1
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                // Your click event logic here
                                print('Create Quotation Clicked');
                                // Example: Navigate to a new screen
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => QuotationsScreen(),
                                  ),
                                );
                              },
                              child: _buildRoutine(
                                "Create\nQuotation",
                                Icons.add_circle_outline_rounded,
                                true,
                              ),
                            ),
                          ),
                          SizedBox(width: 15),
                          Expanded(
                            child: _buildRoutine(
                              "Back Office",
                              Icons.note_add_sharp,
                              false,
                            ),
                          ),
                          SizedBox(width: 15),
                          Expanded(
                            child: _buildRoutine(
                              "Accounts",
                              Icons.warehouse_sharp,
                              false,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 15),
                    // Row 2
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildRoutine(
                              "Material Management",
                              Icons.bar_chart,
                              false,
                            ),
                          ),
                          SizedBox(width: 15),
                          Expanded(
                            child: _buildRoutine(
                              "Dispatch",
                              Icons.people,
                              false,
                            ),
                          ),
                          SizedBox(width: 15),
                          Expanded(
                            child: _buildRoutine("HR", Icons.settings, false),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 15),
                    // Row 3
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const AttendanceScreen(),
                                  ),
                                );
                              },
                              child: _buildRoutine(
                                "Attendance",
                                Icons.fingerprint_rounded,
                                false,
                              ),
                            ),
                          ),
                          SizedBox(width: 15),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const LeaveApprovalsScreen(),
                                  ),
                                );
                              },
                              child: _buildRoutine(
                                "Leaves",
                                Icons.calendar_today_rounded,
                                false,
                              ),
                            ),
                          ),
                          SizedBox(width: 15),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const NewClaimScreen(),
                                  ),
                                );
                              },
                              child: _buildRoutine(
                                "Claims",
                                Icons.payments_rounded,
                                false,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 5),
            _buildSectionHeader("Master"),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AdminScreen()),
                      );
                    },
                    child: _buildRoom(
                      "Admin",
                      "All Approvals Details",
                      "",
                      Icons.people_alt_outlined,
                    ),
                  ),
                ),
                Expanded(
                  child: _buildRoom(
                    "Extra",
                    "All Extra Details",
                    "",
                    Icons.new_releases_outlined,
                  ),
                ),
              ],
            ),

            // === ROOMS ===
            _buildSectionHeader("Reports & Notifications"),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              // Add horizontal padding
              child: Column(
                children: [
                  _buildNotificationCard(
                    'Reports',
                    'All Reports Details',
                    Icons.pending_actions,
                    Colors.orange,
                  ),
                  SizedBox(height: 10),
                  _buildNotificationCard(
                    'Notifications',
                    'All Notifications Details',
                    Icons.notification_add_outlined,
                    Colors.blue,
                  ),
                ],
              ),
            ),
            // === RECENT DEVICES ===
            _buildSectionHeader("Recently Used"),
            SizedBox(
              height: 110,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildDevice("Dummy 1", Icons.ac_unit),
                  _buildDevice("Dummy 2", Icons.lightbulb),
                  _buildDevice("Dummy 3", Icons.tv),
                ],
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ===== POPUP DIALOG =====
  void _showChangeLocationDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isDismissible: true,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              blurRadius: 10,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Close Button
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              // Title
              Text(
                'Change Credentials Details?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontFamily: 'serif',
                ),
              ),
              SizedBox(height: 12),

              // Description
              Text(
                'Entered are your login credentials. Do you want to change it?',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontFamily: 'serif',
                ),
              ),
              SizedBox(height: 20),

              // Mobile
              Text(
                'Mobile',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                  fontFamily: 'serif',
                ),
              ),
              SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Mobile', style: TextStyle(fontSize: 16)),
              ),
              SizedBox(height: 20),

              // Password
              Text(
                'Password',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                  fontFamily: 'serif',
                ),
              ),
              SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Password', style: TextStyle(fontSize: 16)),
              ),
              SizedBox(height: 30),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.primaryText),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        'Stay here',
                        style: TextStyle(
                          color: AppColors.primaryText,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'serif',
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // 🔴 Add your update logic here
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryText,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        'Change',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'serif',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ====== Widgets ======
  Widget _buildStat(
    String value,
    String label,
    Color backgroundColor,
    Color textColor,
    IconData icon,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Red icon on the left
          Icon(icon, color: AppColors.primaryText, size: 24),
          SizedBox(width: 8), // Space between icon and text
          // Original content
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    fontFamily: 'serif',
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 12,
                    fontFamily: 'serif',
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title, // You need to add the text content
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          /* Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),*/
          //Text("View all", style: TextStyle(color: Colors.purple)),
        ],
      ),
    );
  }

  Widget _buildRoutine(String label, IconData icon, bool selected) {
    return Container(
      decoration: BoxDecoration(
        color: selected ? AppColors.primaryText : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: selected
                  ? Colors.white.withOpacity(0.2)
                  : Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: selected ? Colors.white : AppColors.primaryText,
              size: 24,
            ),
          ),
          SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : Colors.black87,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: 'serif',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoom(String name, String temp, String humidity, IconData icon) {
    return Container(
      margin: EdgeInsets.all(10),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primaryText, size: 30),
          SizedBox(height: 12),
          Text(
            name,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'serif',
            ),
          ),
          SizedBox(height: 6),
          Text(
            "$temp   $humidity",
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildDevice(String name, IconData icon) {
    return Container(
      width: 140,
      margin: EdgeInsets.only(left: 20),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primaryText, size: 26),
          SizedBox(height: 14),
          Text(
            name,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
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
          Icon(Icons.arrow_forward_ios, color: AppColors.primaryText, size: 16),
        ],
      ),
    );
  }
}
