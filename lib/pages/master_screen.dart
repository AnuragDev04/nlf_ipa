import 'package:flutter/material.dart';
import 'package:nlf/pages/billing_screen.dart';
import 'package:nlf/pages/branch_screen.dart';
import 'package:nlf/pages/department_screen.dart';
import 'package:nlf/pages/order_approval_screen.dart';
import 'package:nlf/pages/po_approval_screen.dart';
import 'package:nlf/pages/product_screen.dart';
import 'package:nlf/pages/product_type_screen.dart';
import 'package:nlf/pages/quotation.dart';
import 'package:nlf/pages/quote_approval_screen.dart';
import 'package:nlf/pages/role_screen.dart';
import 'package:nlf/pages/segment_screen.dart';
import 'package:nlf/pages/signature_screen.dart';
import 'package:nlf/pages/stage_screen.dart';
import 'package:nlf/pages/unit_screen.dart';
import 'package:nlf/pages/user_registration_screen.dart';
import 'package:nlf/pages/vendor_screen.dart';
import '../utils/colors.dart';

// Helper class for action items (defined at top for clarity)
class _ActionItem {
  final String label;
  final IconData icon;
  final Widget screen;
  final bool isSelected;
  final bool isEmpty;

  _ActionItem({
    required this.label,
    required this.icon,
    required this.screen,
    this.isSelected = false,
    this.isEmpty = false,
  });
}

class MasterScreen extends StatelessWidget {
  const MasterScreen({super.key});

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
          "Master Management",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontFamily: 'serif', // ✅ Added serif
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
            SizedBox(height: 16),
            _buildSectionHeader("Quick Action"),
            // Quick Actions - 3 cards per row
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: User, Branch, Role
                  _buildActionRow(context, [
                    _ActionItem(
                      label: "User Login",
                      icon: Icons.add_circle_outline_rounded,
                      screen: UserRegistrationScreen(),
                      isSelected: true,
                    ),
                    _ActionItem(
                      label: "Branch",
                      icon: Icons.note_add_sharp,
                      screen: BranchScreen(),
                      isSelected: false,
                    ),
                    _ActionItem(
                      label: "Role",
                      icon: Icons.warehouse_sharp,
                      screen: RoleScreen(),
                      isSelected: false,
                    ),
                  ]),
                  SizedBox(height: 16),
                  // Row 2: Material, Unit, Stage
                  _buildActionRow(context, [
                    _ActionItem(
                      label: "Department",
                      icon: Icons.business,
                      screen: DepartmentScreen(),
                      isSelected: false,
                    ),

                    _ActionItem(
                      label: "Unit",
                      icon: Icons.people,
                      screen: UnitScreen(),
                      isSelected: false,
                    ),
                    _ActionItem(
                      label: "Stage",
                      icon: Icons.settings,
                      screen: StageScreen(),
                      isSelected: false,
                    ),
                  ]),
                  SizedBox(height: 16),
                  // Row 3: Department, Rate, Product
                  _buildActionRow(context, [
                    _ActionItem(
                      label: "Billing Address",
                      icon: Icons.attach_money,
                      screen: BillingScreen(),
                      isSelected: false,
                    ),
                    _ActionItem(
                      label: "Product",
                      icon: Icons.shopping_bag,
                      screen: ProductScreen(),
                      isSelected: false,
                    ),
                    _ActionItem(
                      label: "Product Type",
                      icon: Icons.category,
                      screen: ProductTypeScreen(),
                      isSelected: false,
                    ),
                  ]),
                  SizedBox(height: 16),
                  // Row 4: Signature, Vendor, (Empty placeholder)
                  _buildActionRow(context, [
                    _ActionItem(
                      label: "Signature",
                      icon: Icons.edit,
                      screen: SignatureScreen(),
                      isSelected: false,
                    ),
                    _ActionItem(
                      label: "Vendor",
                      icon: Icons.storefront,
                      screen: VendorScreen(),
                      isSelected: false,
                    ),
                    // Empty placeholder to maintain 3-column layout
                    _ActionItem(
                      label: "Segments",
                      icon: Icons.segment,
                      screen: SegmentScreen(), // No-op screen
                      isSelected: false,
                    ),
                  ]),
                  SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // CORRECTED: Flat Row structure without nested Expanded widgets
  Widget _buildActionRow(BuildContext context, List<_ActionItem> items) {
    List<Widget> children = [];

    for (int i = 0; i < items.length; i++) {
      children.add(
        Expanded(
          child: GestureDetector(
            onTap: () {
              if (!items[i].isEmpty) {
                print('${items[i].label} Clicked');
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => items[i].screen),
                );
              }
            },
            child: _buildRoutine(
              items[i].label,
              items[i].icon,
              items[i].isSelected,
              isEmpty: items[i].isEmpty,
            ),
          ),
        ),
      );

      // Add spacing between items (not after last item)
      if (i < items.length - 1) {
        children.add(SizedBox(width: 15));
      }
    }

    return Row(children: children);
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
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 2,
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          fontFamily: 'serif', // ✅ Added serif
        ),
      ),
    );
  }

  Widget _buildRoutine(
    String label,
    IconData icon,
    bool selected, {
    bool isEmpty = false,
  }) {
    if (isEmpty) {
      // Maintain layout consistency with proper height
      return Container(
        height: 90,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
      );
    }

    return Container(
      height: 90,
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
              fontFamily: 'serif', // ✅ Added serif
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryText, size: 24),
          SizedBox(width: 8),
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
                    fontFamily: 'serif', // ✅ Added serif
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 12,
                    fontFamily: 'serif', // ✅ Added serif
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
                  fontFamily: 'serif', // ✅ Added serif
                ),
              ),
              SizedBox(height: 12),
              // Description
              Text(
                'Entered are your login credentials. Do you want to change it?',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontFamily: 'serif', // ✅ Added serif
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
                  fontFamily: 'serif', // ✅ Added serif
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
                child: Text(
                  'Mobile', // Assuming this displays the mobile number
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'serif',
                  ), // ✅ Added serif
                ),
              ),
              SizedBox(height: 20),
              // Password
              Text(
                'Password',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                  fontFamily: 'serif', // ✅ Added serif
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
                child: Text(
                  'Password', // Assuming this displays the password
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'serif',
                  ), // ✅ Added serif
                ),
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
                          fontFamily: 'serif', // ✅ Added serif
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
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
                          fontFamily: 'serif', // ✅ Added serif
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
