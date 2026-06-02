import 'package:flutter/material.dart';
import '../utils/colors.dart';
import 'material_screen.dart';

class MaterialMainScreen extends StatelessWidget {
  const MaterialMainScreen({super.key});

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
          "MATERIAL MANAGEMENT",
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Stats
            _buildHeaderStats(context),

            SizedBox(height: 0),

            // Recent Quotations
            _buildSectionHeader('Order Generation Copies'),
            _buildRecentQuotations(context),

            SizedBox(height: 20),
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: _buildStat( 
                    "24",
                    "Pending Store Approval",
                    AppColors.primaryLight,
                    Colors.black,
                    Icons.pending_actions,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildStat(
                    "6",
                    "Pending Design Approval",
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
                    "Pending Accounts Approval",
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

  Widget _buildQuickActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
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
                fontSize: 11,
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

  Widget _buildRecentQuotations(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Material Card - Added at the top
          _buildSingleQuotationCard(
            'Material',
            'All material details and specifications',
            'View all materials',
            'Active',
            Color(0xFF2196F3),
            // Blue color for material
            Icons.inventory,
            () {
              // Navigate to material management
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MaterialScreen()),
              );
            },
          ),
          SizedBox(height: 16),

          // Store Card
          _buildSingleQuotationCard(
            'Store Department',
            'Manage inventory, stock levels, and material storage',
            '24 Items',
            'Pending',
            Color(0xFFFF9800),
            Icons.store,
            () {
              // Navigate to store management
            },
          ),
          SizedBox(height: 16),
          // Design Card
          _buildSingleQuotationCard(
            'Design Department',
            'Review and approve material specifications',
            '6 Projects',
            'Approved',
            Color(0xFF4CAF50),
            Icons.design_services,
            () {
              // Navigate to design approval
            },
          ),
          SizedBox(height: 16),
          // Planning Card
          _buildSingleQuotationCard(
            'Planning Department',
            'Material planning and purchase order management',
            '3400 Tasks',
            'In Progress',
            Color(0xFFF44336),
            Icons.schedule,
            () {
              // Navigate to planning
            },
          ),
        ],
      ),
    );
  }

  // New method to build individual quotation card with enhanced shadow
  Widget _buildSingleQuotationCard(
    String title,
    String description,
    String count,
    String status,
    Color statusColor,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Container(
      margin: EdgeInsets.all(8), // Added margin around each card
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          // Multiple shadow layers for better 3D effect
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 1,
            blurRadius: 8,
            offset: Offset(0, 4), // Shadow on bottom
          ),
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: Offset(0, 2), // Additional shadow for depth
          ),
          // Shadow on all sides for complete 3D effect
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            spreadRadius: 2,
            blurRadius: 12,
            offset: Offset(0, 0), // Center shadow for all-around effect
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: statusColor, size: 24),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'serif', // Added serif fonts family
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontFamily: 'serif', // Added serif font family
              ),
            ),
            SizedBox(height: 4),
            Text(
              count,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
                fontFamily: 'serif', // Added serif font family
              ),
            ),
          ],
        ),
        trailing: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            status,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: statusColor,
              fontFamily: 'serif', // Added serif fonts family
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPerformanceOverview() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Monthly Performance',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'serif', // Added serif font family
                ),
              ),
              SizedBox(height: 15),
              // Simple chart representation
              Expanded(
                child: Row(
                  children: [
                    _buildChartBar('Jan', 80, Color(0xFF4CAF50)),
                    _buildChartBar('Feb', 25, Color(0xFF2196F3)),
                    _buildChartBar('Mar', 40, Color(0xFFFF9800)),
                    _buildChartBar('Apr', 75, Color(0xFF9C27B0)),
                    _buildChartBar('May', 85, Color(0xFFF44336)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChartBar(String label, double height, Color color) {
    return Expanded(
      child: Column(
        children: [
          Expanded(
            child: Container(
              width: 20,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
              ),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  height: height,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.7),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
              fontFamily: 'serif',
            ),
          ),
        ],
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
      // Equal vertical padding
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
                    fontFamily: 'serif', // Added serif font family
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 12,
                    fontFamily: 'serif', // Added serif font family
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
                  fontFamily: 'serif', // Added serif font family
                ),
              ),
              SizedBox(height: 12),

              // Description
              Text(
                'Entered are your login credentials. Do you want to change it?',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontFamily: 'serif', // Added serif font family
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
                  fontFamily: 'serif', // Added serif font family
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
                  fontFamily: 'serif', // Added serif font family
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
                          fontFamily: 'serif', // Added serif font family
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // Add your update logic here
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
                          fontFamily: 'serif', // Added serif font family
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
}

class TenderItem {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController unitController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();

  void dispose() {
    nameController.dispose();
    unitController.dispose();
    quantityController.dispose();
  }
}
