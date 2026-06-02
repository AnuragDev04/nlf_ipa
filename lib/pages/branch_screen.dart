import 'package:flutter/material.dart';
import 'package:nlf/pages/add_branch_screen.dart';
import 'package:nlf/utils/colors.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/constants.dart';

class BranchScreen extends StatefulWidget {
  const BranchScreen({super.key});

  @override
  _BranchScreenState createState() => _BranchScreenState();
}

class _BranchScreenState extends State<BranchScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _searchController = TextEditingController();

  List<BranchItem> branches = [];
  List<BranchItem> filteredBranches = [];
  DateTime? _fromDate;
  DateTime? _toDate;
  bool _isLoading = true;

  final String apiUrl = AppConstants.BRANCH_LIST_API;

  @override
  void initState() {
    super.initState();
    _loadBranches();
  }

  Future<void> _loadBranches() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if ((data['success'] == "1" || data['success'] == 1)) {
          List<dynamic> branchData = data['data'];

          List<BranchItem> loadedBranches = branchData.map((item) {
            return BranchItem(
              id: item['id']?.toString() ?? '',
              branchName: item['branch_name']?.toString() ?? '',
              headerImage: item['header_image']?.toString() ?? '',
              gstNo: item['gst_no']?.toString() ?? '',
              address: item['address']?.toString() ?? '',
            );
          }).toList();

          setState(() {
            branches = loadedBranches;
            filteredBranches = loadedBranches;
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
          String errorMessage = data['message']?.toString() ?? 'Unknown error';
          print('API Error: $errorMessage');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to load branches: $errorMessage',
                style: TextStyle(fontFamily: 'serif'),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        setState(() {
          _isLoading = false;
        });
        print('Failed to load branches: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to load branches: HTTP ${response.statusCode}',
              style: TextStyle(fontFamily: 'serif'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading branches: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error loading branches: $e',
            style: TextStyle(fontFamily: 'serif'),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _filterBranches(String query) {
    List<BranchItem> tempFiltered = [...branches];

    if (query.isNotEmpty) {
      tempFiltered = tempFiltered
          .where(
            (branch) =>
                branch.branchName.toLowerCase().contains(query.toLowerCase()) ||
                branch.gstNo.toLowerCase().contains(query.toLowerCase()) ||
                branch.address.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    }

    setState(() {
      filteredBranches = tempFiltered;
    });
  }

  Future<void> _selectDate(BuildContext context, String type) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: AppColors.primaryText,
            colorScheme: ColorScheme.light(primary: AppColors.primaryText),
            buttonTheme: ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (type == 'From') {
          _fromDate = picked;
        } else if (type == 'To') {
          _toDate = picked;
        }
        _filterBranches(_searchController.text);
      });
    }
  }

  Future<void> _deleteBranch(int index) async {
    if (index < 0 || index >= filteredBranches.length) return;

    final String branchId = filteredBranches[index].id;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            "Confirm Delete",
            style: TextStyle(fontFamily: 'serif'),
          ),
          content: Text(
            "Are you sure you want to delete ${filteredBranches[index].branchName}?",
            style: const TextStyle(fontFamily: 'serif'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Cancel",
                style: TextStyle(fontFamily: 'serif'),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context); // Close dialog immediately
                final prefs = await SharedPreferences.getInstance();
                String? empId = prefs.getString('emp_id');

                if (empId == null || empId.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Error: User session expired. Please log in again.',
                        style: TextStyle(fontFamily: 'serif'),
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                setState(() {
                  branches.removeWhere((b) => b.id == branchId);
                  if (index < filteredBranches.length && filteredBranches[index].id == branchId) {
                    filteredBranches.removeAt(index);
                  } else {
                    filteredBranches.removeWhere((b) => b.id == branchId);
                  }
                });

                try {
                  final response = await http.post(
                    Uri.parse(AppConstants.DELETE_BRANCH_API),
                    headers: {'Content-Type': 'application/json'},
                    body: jsonEncode({
                      "id": branchId,
                      "emp_id": empId,
                    }),
                  );

                  if (response.statusCode == 200) {
                    final Map<String, dynamic> data = json.decode(response.body);

                    if (data['status'] == 'true' &&
                        (data['success'] == '1' || data['success'] == 1)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            data['message'] ?? 'Branch deleted successfully!',
                            style: TextStyle(fontFamily: 'serif'),
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );

                    } else {
                      throw Exception(data['message'] ?? 'Failed to delete branch');
                    }
                  } else {
                    throw Exception('Server error: ${response.statusCode}');
                  }
                } catch (e) {
                  print('Delete Branch Error: $e');

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Error: ${e.toString().replaceAll('Exception: ', '')}',
                        style: TextStyle(fontFamily: 'serif'),
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                  if (_loadBranches != null) {
                    await _loadBranches();
                  }
                }
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
          "Branch List",
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
            SizedBox(height: 10),

            // Search Bar
            Container(
              margin: EdgeInsets.symmetric(horizontal: 10),
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: AppColors.primaryText, width: 1.5),
              ),
              child: Row(
                children: [
                  SizedBox(width: 15),
                  Icon(Icons.search, color: AppColors.primaryText, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => _filterBranches(value),
                      decoration: InputDecoration(
                        hintText: 'Search by Branch Name, GST No or Address',
                        hintStyle: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 14,
                          fontFamily: 'serif',
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                    ),
                  ),
                  SizedBox(width: 15),
                ],
              ),
            ),

            SizedBox(height: 10),

            // Filter Section - Date Filters
            Container(
              margin: EdgeInsets.symmetric(horizontal: 10),
              height: 55,
              padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Text(
                    'Date',
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontSize: 14,
                      fontFamily: 'serif',
                    ),
                  ),
                  SizedBox(width: 10),
                  _buildDateTextField(context, 'From', _fromDate),
                  SizedBox(width: 5),
                  _buildDateTextField(context, 'To', _toDate),
                  Spacer(),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _fromDate = null;
                        _toDate = null;
                        _filterBranches(_searchController.text);
                      });
                    },
                    icon: Icon(
                      Icons.close,
                      color: AppColors.primaryText,
                      size: 25,
                    ),
                    padding: EdgeInsets.all(8),
                    constraints: BoxConstraints(),
                    splashRadius: 20,
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddBranchScreen(),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black87,
                    backgroundColor: Colors.transparent,
                    side: BorderSide(color: Colors.black87, width: 2.0),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                        decoration: BoxDecoration(
                          color: AppColors.primaryText,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.add, color: Colors.white, size: 14),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'New Branch',
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

            SizedBox(height: 10),

            // Count Badge
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryText.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primaryText.withOpacity(0.3),
                ),
              ),
              child: Text(
                'Showing ${filteredBranches.length} records',
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 12,
                  fontFamily: 'serif',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            SizedBox(height: 10),

            // Loading indicator or Branch List
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryText,
                      ),
                    )
                  : _buildBranchList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBranchList() {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 20),
      itemCount: filteredBranches.length,
      itemBuilder: (context, index) {
        return _buildBranchCard(filteredBranches[index], index);
      },
    );
  }

  Widget _buildBranchCard(BranchItem branch, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// IMAGE
            GestureDetector(
              onTap: () {
                if (branch.headerImage.isNotEmpty) {
                  showDialog(
                    context: context,
                    builder: (_) {
                      return Dialog(
                        backgroundColor: Colors.black,
                        insetPadding: const EdgeInsets.all(10),
                        child: Stack(
                          children: [
                            /// FULL IMAGE
                            InteractiveViewer(
                              child: CachedNetworkImage(
                                imageUrl: branch.headerImage.trim(),
                                fit: BoxFit.contain,
                                width: double.infinity,
                              ),
                            ),

                            /// CLOSE BUTTON
                            Positioned(
                              top: 10,
                              right: 10,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 28,
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }
              },
              child: Stack(
                children: [
                  SizedBox(
                    height: 110,
                    width: double.infinity,
                    child: branch.headerImage.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: branch.headerImage.trim(),
                            fit: BoxFit.cover,
                            width: double.infinity,
                          )
                        : Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.image, size: 40),
                          ),
                  ),
                ],
              ),
            ),

            /// CARD CONTENT
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// NAME + DELETE
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          branch.branchName,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                            fontFamily: 'serif',
                          ),
                        ),
                      ),

                      Container(
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.delete,
                            color: Colors.red.shade700,
                            size: 20,
                          ),
                          onPressed: () => _deleteBranch(
                            index,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  /// GST
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.receipt_long,
                        size: 15,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          "GST: ${branch.gstNo.isNotEmpty ? branch.gstNo : 'Not Provided'}",
                          style: const TextStyle(
                            fontWeight: FontWeight.w400,
                            color: Colors.black87,
                            fontSize: 13,
                            fontFamily: 'serif',
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 5),

                  /// ADDRESS
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 15,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          branch.address.isNotEmpty
                              ? branch.address
                              : "Not provided",
                          style: const TextStyle(
                            fontWeight: FontWeight.w400,
                            color: Colors.black87,
                            fontSize: 13,
                            fontFamily: 'serif',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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
          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          constraints: const BoxConstraints(minHeight: 55, maxHeight: 55),
        ),
        controller: TextEditingController(
          text: selectedDate != null
              ? '${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}'
              : '',
        ),
        onTap: () => _selectDate(context, label),
        style: TextStyle(
          color: Colors.black,
          fontSize: 14,
          fontFamily: 'serif',
        ),
      ),
    );
  }
}

class BranchItem {
  final String id;
  final String branchName;
  final String headerImage;
  final String gstNo;
  final String address;

  BranchItem({
    required this.id,
    required this.branchName,
    required this.headerImage,
    required this.gstNo,
    required this.address,
  });
}
