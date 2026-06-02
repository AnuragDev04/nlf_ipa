import 'package:flutter/material.dart';
import 'package:nlf/pages/lead_generation_screen.dart';

import 'package:nlf/pages/order_approval_screen.dart';
import 'package:nlf/pages/po_approval_screen.dart';
import 'package:nlf/pages/quote_approval_screen.dart';
import 'package:nlf/pages/rate_approval_screen.dart';
import 'package:nlf/pages/salesperson_main_screen.dart';

import '../utils/colors.dart';

class LeadMainScreen extends StatelessWidget {
  const LeadMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          "Lead Dashboard",
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
      /*  actions: [
          IconButton(
            icon: Icon(Icons.settings, color: AppColors.primaryText),
            onPressed: () {
              _showChangeLocationDialog(context);
            },
            tooltip: 'Settings',
          ),
          SizedBox(width: 10),
        ],*/
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Stats
            _buildHeaderStats(context),

            SizedBox(height: 0),

            // Quick Actions
            _buildSectionHeader('Quick Actions'),
            _buildLeadGenerationCard(context), // Added new card
            _buildQuickActions(context), // Existing cards

            SizedBox(height: 0),

            // Recent Quotations
            SizedBox(height: 0),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderStats(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFD32F2F), Color(0xFFF44336)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1), // Lighter shadow
            blurRadius: 2, // Reduced from 8 or 10 to 2
            offset: Offset(0, 1),
          ),
        ],
      ),
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
                    "Pending Rate Approval",
                    AppColors.primaryLight,
                    Colors.black,
                    Icons.pending_actions,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildStat(
                    "6",
                    "Pending Order Confirmation Approval",
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
                    "Pending Quotation Approval",
                    AppColors.primaryLight,
                    Color(0xFFE65100),
                    Icons.inventory_2,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildStat(
                    "8000000",
                    "Pending Vendors PO Approval",
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
    );
  }

  Widget _buildStatCard(
      String value,
      String label,
      Color valueColor,
      Color labelColor,
      ) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
        SizedBox(height: 5),
        Text(label, style: TextStyle(fontSize: 12, color: labelColor)),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'serif',
            ),
          ),
        ],
      ),
    );
  }

  // Added new widget for Lead Generation card
  Widget _buildLeadGenerationCard(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: GestureDetector(
        onTap: () {
          // Implement navigation or action for Lead Generation
          print("Lead Generation tapped");
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LeadGenerationScreen(),
            ),
          );
        },
        child: Container(
          height: 80, // Adjust height as needed
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(0xFFFF9800).withOpacity(0.1), // Orange background
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.trending_up, // Icon representing lead generation
                  color: Color(0xFFFF9800), // Orange icon color
                  size: 32,
                ),

              ),
              // Text
              Expanded(
                child: Text(
                  'Lead Generation', // Text content
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                    fontFamily: 'serif',
                  ),

                ),

              ),

              // Right arrow icon
              Container(
                margin: EdgeInsets.only(right: 16),
                child: Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        height: 100,
        child: Row(
          children: [
            Expanded(
              flex: 1, // This makes it take equal space (1 out of total 2)
              child: _buildQuickActionCard(
                'Sales\nPerson',
                Icons.people,
                Color(0xFF4CAF50),
                    () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SalespersonMainScreen(),
                    ),
                  );
                },
              ),
            ),
            SizedBox(width: 15),
            Expanded(
              flex: 1, // This makes it take equal space (1 out of total 2)
              child: _buildQuickActionCard(
                'Rate\nApprovals',
                Icons.approval,
                Color(0xFF2196F3),
                    () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RateApprovalScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(
      String title,
      IconData icon,
      Color color,
      VoidCallback onTap,
      ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
                height: 1.2,
                fontFamily: 'serif',
              ),
            ),
          ],
        ),
      ),
    );
  }

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
}