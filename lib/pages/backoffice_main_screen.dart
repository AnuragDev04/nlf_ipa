import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nlf/pages/annexure_screen.dart';
import 'package:nlf/pages/order_confirm_screen.dart';
import 'package:nlf/pages/po_approval_screen.dart';
import 'package:nlf/pages/product_screen.dart';
import 'package:nlf/pages/quotation.dart';
import '../utils/colors.dart';

// Helper class for action items
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

class BackofficeMainScreen extends StatelessWidget {
  const BackofficeMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Back Office Management",
          style: GoogleFonts.lora(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 50,
        titleSpacing: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Stats
            _buildHeaderStats(context),
            const SizedBox(height: 16),
            _buildSectionHeader("Operational Tasks"),
            // Quick Actions - 3 cards per row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Row 1: Quotations, Work Orders, PO Vendor
                  _buildActionRow(context, [
                    _ActionItem(
                      label: "Quotations",
                      icon: Icons.description_outlined,
                      screen: const QuotationsScreen(),
                      isSelected: true,
                    ),
                    _ActionItem(
                      label: "Work Orders",
                      icon: Icons.assignment_turned_in_outlined,
                      screen: const OrderConfirmScreen(),
                      isSelected: false,
                    ),
                    _ActionItem(
                      label: "PO Vendor",
                      icon: Icons.shopping_cart_outlined,
                      screen: const Scaffold(body: Center(child: Text("PO Vendor Screen"))), // Placeholder if needed
                      isSelected: false,
                    ),
                  ]),
                  const SizedBox(height: 16),
                  // Row 2: Annexures, Closed Project, Product
                  _buildActionRow(context, [
                    _ActionItem(
                      label: "Annexures",
                      icon: Icons.attachment_outlined,
                      screen: const AnnexureScreen(),
                      isSelected: false,
                    ),
                    _ActionItem(
                      label: "Closed Projects",
                      icon: Icons.check_circle_outline,
                      screen: const Scaffold(body: Center(child: Text("Closed Projects Screen"))),
                      isSelected: false,
                    ),
                    _ActionItem(
                      label: "Products",
                      icon: Icons.shopping_bag_outlined,
                      screen: const ProductScreen(),
                      isSelected: false,
                    ),
                  ]),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionRow(BuildContext context, List<_ActionItem> items) {
    List<Widget> children = [];
    for (int i = 0; i < items.length; i++) {
      children.add(
        Expanded(
          child: GestureDetector(
            onTap: () {
              if (!items[i].isEmpty) {
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
      if (i < items.length - 1) {
        children.add(const SizedBox(width: 15));
      }
    }
    return Row(children: children);
  }

  Widget _buildHeaderStats(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStat(
                  "24",
                  "Pending Rate Approval",
                  const Color(0xFFFFF5F5),
                  const Color(0xFFC62828),
                  Icons.pending_actions,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStat(
                  "6",
                  "Pending Orders",
                  const Color(0xFFF1F8E9),
                  const Color(0xFF2E7D32),
                  Icons.construction,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStat(
                  "3400",
                  "Pending Quotes",
                  const Color(0xFFFFF3E0),
                  const Color(0xFFE65100),
                  Icons.inventory_2,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStat(
                  "8.0M",
                  "Vendor PO Value",
                  const Color(0xFFF3E5F5),
                  const Color(0xFF6A1B9A),
                  Icons.account_balance_wallet,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Text(
        title,
        style: GoogleFonts.lora(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildRoutine(String label, IconData icon, bool selected, {bool isEmpty = false}) {
    if (isEmpty) {
      return Container(height: 100);
    }
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: selected ? AppColors.primaryText : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: selected ? Colors.white.withOpacity(0.2) : const Color(0xFFF8FAFC),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: selected ? Colors.white : AppColors.primaryText,
              size: 26,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.lora(
              color: selected ? Colors.white : Colors.black87,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String value, String label, Color backgroundColor, Color textColor, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor.withOpacity(0.7), size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.lora(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.lora(
                    color: textColor.withOpacity(0.8),
                    fontSize: 10,
                  ),
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
