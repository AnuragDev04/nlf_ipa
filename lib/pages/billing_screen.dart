import 'package:flutter/material.dart';
import 'package:nlf/pages/add_billing_screen.dart';
import 'package:nlf/pages/add_department_screen.dart';
import 'package:nlf/pages/add_user_screen.dart';
import 'package:nlf/pages/billing_screen_edit.dart';
import 'package:nlf/utils/colors.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/constants.dart';

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  _BillingScreenState createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _searchController = TextEditingController();

  List<BillingItem> billings = [];
  List<BillingItem> filteredBillings = [];
  DateTime? _fromDate;
  DateTime? _toDate;
  bool _isLoading = true;

  final String apiUrl = AppConstants.BILLING_ADDRESS_LIST_API;

  @override
  void initState() {
    super.initState();
    _loadBillings();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBillings() async {
    try {
      setState(() => _isLoading = true);

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['status'] == 'true' && (data['success'] == "1" || data['success'] == 1)) {
          List<dynamic> billingData = data['data'];

          List<BillingItem> loadedBillings = billingData.map((item) {
            return BillingItem(
              id: item['id']?.toString() ?? '',
              address: item['address']?.toString() ?? '',
              city: item['city']?.toString() ?? '',
            );
          }).toList();

          setState(() {
            billings = loadedBillings;
            filteredBillings = List.from(loadedBillings);
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
          _showSnackBar(data['message'] ?? 'Failed to load billing addresses', Colors.red);
        }
      } else {
        setState(() => _isLoading = false);
        _showSnackBar('Failed to load billing addresses: HTTP ${response.statusCode}', Colors.red);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Error loading billing addresses: $e', Colors.red);
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'serif')),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _filterBillings(String query) {
    List<BillingItem> tempFiltered = List.from(billings);

    if (_fromDate != null || _toDate != null) {
      // Add date filtering logic here if needed in future
    }

    if (query.isNotEmpty) {
      tempFiltered = tempFiltered
          .where((billing) => billing.city.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }

    setState(() {
      filteredBillings = tempFiltered;
    });
  }

  Future<void> _selectDate(BuildContext context, String type) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null && mounted) {
      setState(() {
        if (type == 'From') {
          _fromDate = picked;
        } else if (type == 'To') {
          _toDate = picked;
        }
        _filterBillings(_searchController.text);
      });
    }
  }

  // ✅ UPDATED: Instant delete with optimistic UI + background API call
  void _deleteBilling(int index) {
    final billToDelete = filteredBillings[index];

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("Confirm Delete", style: TextStyle(fontFamily: 'serif')),
          content: Text(
            "Are you sure you want to delete '${billToDelete.city}'?",
            style: const TextStyle(fontFamily: 'serif'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text("Cancel", style: TextStyle(fontFamily: 'serif')),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();

                // 🚀 OPTIMISTIC UPDATE: Remove from UI immediately for instant feedback
                final billingId = billToDelete.id;

                setState(() {
                  // Remove from main list
                  billings.removeWhere((item) => item.id == billingId);
                  // Remove from filtered list (instant visual update!)
                  filteredBillings.removeWhere((item) => item.id == billingId);
                });

                _showSnackBar('Billing Address deleted successfully', Colors.green);

                // 🔄 Make API call in background - revert only if it fails
                _performDeleteApiCall(billToDelete);
              },
              child: const Text(
                "Delete",
                style: TextStyle(fontFamily: 'serif', color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  // ✅ Background API call with rollback capability
  Future<void> _performDeleteApiCall(BillingItem billing) async {
    try {
      final response = await http.post(
        Uri.parse(AppConstants.DELETE_BILLING_ADDRESS_API),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{'id': billing.id}),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        // If API reports failure, revert the optimistic update
        if (result['status'] != 'true' || result['success'] != '1') {
          _revertDeletion(billing, result['message'] ?? 'Failed to delete billing address');
        }
        // If success, keep the optimistic update (nothing to do)
      } else {
        // HTTP error - revert the optimistic update
        _revertDeletion(billing, 'Failed to connect to server');
      }
    } catch (e) {
      // Exception - revert the optimistic update
      _revertDeletion(billing, 'Error: $e');
    }
  }

  // ✅ Re-adds the billing item if API call failed
  void _revertDeletion(BillingItem billing, String errorMessage) {
    if (!mounted) return;

    setState(() {
      // Re-add to main list if not already present
      if (!billings.any((item) => item.id == billing.id)) {
        billings.add(billing);
      }
      // Re-add to filtered list and re-apply search filter
      if (!filteredBillings.any((item) => item.id == billing.id)) {
        filteredBillings.add(billing);
        if (_searchController.text.isNotEmpty) {
          _filterBillings(_searchController.text);
        }
      }
    });
    _showSnackBar(errorMessage, Colors.red);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Billing Address List",
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
        child: Column(
          children: [
            const SizedBox(height: 10),

            // Search Bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: AppColors.primaryText, width: 1.5),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 15),
                  Icon(Icons.search, color: AppColors.primaryText, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => _filterBillings(value),
                      decoration: const InputDecoration(
                        hintText: 'Search by City',
                        hintStyle: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                          fontFamily: 'serif',
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Filter Section - Date Filters
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              height: 55,
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Text(
                    'Date',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                      fontFamily: 'serif',
                    ),
                  ),
                  const SizedBox(width: 10),
                  _buildDateTextField(context, 'From', _fromDate),
                  const SizedBox(width: 5),
                  _buildDateTextField(context, 'To', _toDate),
                  Spacer(),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _fromDate = null;
                        _toDate = null;
                        _filterBillings(_searchController.text);
                      });
                    },
                    icon: Icon(
                      Icons.close,
                      color: AppColors.primaryText,
                      size: 25,
                    ),
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                    splashRadius: 20,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AddBillingScreen()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black87,
                    backgroundColor: Colors.transparent,
                    side: const BorderSide(color: Colors.black87, width: 2.0),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryText,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add, color: Colors.white, size: 14),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'New Billing Address',
                        style: TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'serif',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Count Badge
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryText.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primaryText.withOpacity(0.3),
                ),
              ),
              child: Text(
                'Showing ${filteredBillings.length} records',
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 12,
                  fontFamily: 'serif',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Loading indicator or Billing List
            Expanded(
              child: _isLoading
                  ? Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryText,
                ),
              )
                  : filteredBillings.isEmpty
                  ? Center(
                child: Text(
                  'No billing addresses found',
                  style: TextStyle(color: Colors.grey[600], fontFamily: 'serif', fontSize: 16),
                ),
              )
                  : _buildBillingList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillingList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: filteredBillings.length,
      itemBuilder: (context, index) {
        return _buildBillingCard(filteredBillings[index], index);
      },
    );
  }

  Widget _buildBillingCard(BillingItem billing, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey[200]!,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        title: Text(
          billing.city,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontFamily: 'serif',
          ),
        ),
        subtitle: Text(
          billing.address,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontFamily: 'serif',
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit, color: Colors.deepPurple.shade700, size: 20),
              onPressed: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.setString("selected_id", billing.id);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BillingScreenEdit(),
                  ),
                );
              },
            ),
            IconButton(
              onPressed: () => _deleteBilling(index),
              icon: Icon(Icons.delete, color: Colors.red[400]),
              tooltip: 'Delete',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTextField(
      BuildContext context,
      String label,
      DateTime? selectedDate,
      ) {
    return SizedBox(
      width: 100,
      height: 40,
      child: TextFormField(
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontFamily: 'serif',
          ),
          hintText: 'Select $label date',
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
            fontFamily: 'serif',
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey, width: 2.0),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          constraints: const BoxConstraints(minHeight: 55, maxHeight: 55),
        ),
        controller: TextEditingController(
          text: selectedDate != null
              ? '${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}'
              : '',
        ),
        onTap: () => _selectDate(context, label),
        style: const TextStyle(
          color: Colors.black,
          fontSize: 14,
          fontFamily: 'serif',
        ),
      ),
    );
  }
}

class BillingItem {
  final String id;
  final String address;
  final String city;

  BillingItem({
    required this.id,
    required this.address,
    required this.city,
  });
}