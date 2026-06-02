import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:nlf/pages/billing_screen.dart';
import 'package:nlf/utils/colors.dart';
import 'package:nlf/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BillingScreenEdit extends StatefulWidget {
  final String? billingId; // ✅ Optional: Pass billing ID from previous screen

  const BillingScreenEdit({super.key, this.billingId});

  @override
  State<BillingScreenEdit> createState() => _BillingScreenEditState();
}

class _BillingScreenEditState extends State<BillingScreenEdit> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  bool _isLoading = false;
  String? _billingId;

  @override
  void initState() {
    super.initState();
    _loadBillingId();
   }

  @override
  void dispose() {
    _cityController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _loadBillingId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? billingId = prefs.getString("selected_id");

    if (billingId != null) {
      _billingId = billingId;
      _fetchBillingAddress(billingId);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'ID not found',
            style: TextStyle(fontFamily: 'serif'),
          ),
          backgroundColor: Colors.red,
        ),
      );
      Navigator.pop(context);
    }
  }

  // ✅ API URLs from constants
  final String fetchApiUrl = AppConstants.FETCH_BILLING_ADDRESS_API;
  final String updateApiUrl = AppConstants.UPDATE_BILLING_ADDRESS_API;

  // ✅ FETCH: Load billing address data on screen init
  Future<void> _fetchBillingAddress(String billingId) async {
    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(fetchApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': billingId}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> result = json.decode(response.body);

        final status = result['status'];
        final isSuccess = status == true || status == 'true' || status == '1';

        if (isSuccess && result['data'] != null) {
          final data = result['data'];

          setState(() {
            _cityController.text = data['city']?.toString() ?? '';
            _addressController.text = data['address']?.toString() ?? '';
            _billingId = data['id']?.toString() ?? _billingId;
          });
        } else {
          _showSnackBar(result['message'] ?? 'Failed to load billing address', Colors.red);
        }
      } else {
        _showSnackBar('Server error: ${response.statusCode}', Colors.red);
      }
    } catch (e) {
      print('Error fetching billing address: $e');
      _showSnackBar('Error loading data: $e', Colors.red);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ✅ UPDATE: Save billing address with ID parameter
  Future<void> _saveBilling() async {
    if (_formKey.currentState!.validate() && _billingId != null) {
      setState(() => _isLoading = true);

      try {
        final response = await http.post(
          Uri.parse(updateApiUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'id': _billingId,
            'city': _cityController.text.trim(),
            'address': _addressController.text.trim(),
          }),
        );

        if (response.statusCode == 200) {
          final Map<String, dynamic> result = json.decode(response.body);

          final status = result['status'];
          final isSuccess = status == true || status == 'true' || status == '1';

          if (isSuccess && (result['success'] == '1' || result['success'] == 1)) {
            _showSnackBar(result['message'] ?? 'Billing address updated successfully!', Colors.green);
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const BillingScreen()),
                  (route) => false,
            );
          } else {
            _showSnackBar(result['message'] ?? 'Failed to update billing address', Colors.red);
          }
        } else {
          _showSnackBar('Server error: ${response.statusCode}', Colors.red);
        }
      } catch (e) {
        print('Error updating billing address: $e');
        _showSnackBar('Error saving data: $e', Colors.red);
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _showSnackBar(String message, Color backgroundColor) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(fontFamily: 'serif')),
        backgroundColor: backgroundColor,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _cancelBilling() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Edit Billing Address",
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
      body: _isLoading && _cityController.text.isEmpty && _addressController.text.isEmpty
          ? Center(child: CircularProgressIndicator(color: AppColors.primaryText))
          : Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Billing Address Details'),
                    const SizedBox(height: 20),

                    // City Field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'City',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'serif',
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _cityController,
                          enabled: !_isLoading, // ✅ Disable while loading
                          style: TextStyle(color: Colors.black, fontFamily: 'serif'),
                          decoration: InputDecoration(
                            labelText: 'City',
                            labelStyle: TextStyle(color: AppColors.greyText, fontFamily: 'serif'),
                            prefixIcon: Icon(Icons.location_city, color: AppColors.greyText),
                            hintText: 'Enter city',
                            hintStyle: TextStyle(color: AppColors.greyText, fontFamily: 'serif'),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.lightGrey),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.secondaryText),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'City is required';
                            }
                            if (value.trim().length < 2) {
                              return 'City must be at least 2 characters';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Address Field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Address',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'serif',
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _addressController,
                          enabled: !_isLoading, // ✅ Disable while loading
                          style: TextStyle(color: Colors.black, fontFamily: 'serif'),
                          decoration: InputDecoration(
                            labelText: 'Address',
                            labelStyle: TextStyle(color: AppColors.greyText, fontFamily: 'serif'),
                            prefixIcon: Icon(Icons.location_on, color: AppColors.greyText),
                            hintText: 'Enter full address',
                            hintStyle: TextStyle(color: AppColors.greyText, fontFamily: 'serif'),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.lightGrey),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppColors.secondaryText),
                            ),
                          ),
                          maxLines: 4,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Address is required';
                            }
                            if (value.trim().length < 10) {
                              return 'Address must be at least 10 characters';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),

            // Save and Cancel Buttons
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveBilling,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryText,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                          : Text(
                        'Update Billing Address',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'serif',
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 15),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : _cancelBilling, // ✅ Disable while loading
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.grey[600],
                        side: BorderSide(color: Colors.grey[600]!, width: 2.0),
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'serif',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
        fontFamily: 'serif',
      ),
    );
  }
}