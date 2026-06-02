import 'package:flutter/material.dart';
import 'package:nlf/pages/add_department_screen.dart';
import 'package:nlf/utils/colors.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class DepartmentScreen extends StatefulWidget {
  const DepartmentScreen({super.key});

  @override
  _DepartmentScreenState createState() => _DepartmentScreenState();
}

class _DepartmentScreenState extends State<DepartmentScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<DepartmentItem> departments = [];
  List<DepartmentItem> filteredDepartments = [];
  bool _isLoading = true;
  DateTime? _fromDate;
  DateTime? _toDate;

  final String apiUrl = AppConstants.DEPARTMENT_LIST_API;
  final String deleteApiUrl = AppConstants.DELETE_DEPARTMENT_API;

  @override
  void initState() {
    super.initState();
    _loadDepartments();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDepartments() async {
    try {
      setState(() => _isLoading = true);

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['status'] == 'true' &&
            (data['success'] == "1" || data['success'] == 1)) {
          List<dynamic> departmentData = data['data'] ?? [];

          List<DepartmentItem> loadedDepartments = departmentData.map((item) {
            return DepartmentItem(
              dpt_id: item['dpt_id']?.toString() ?? '',
              department: item['department']?.toString() ?? '',
            );
          }).toList();

          setState(() {
            departments = loadedDepartments;
            filteredDepartments = List.from(loadedDepartments);
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
          _showSnackBar(
            data['message'] ?? 'Failed to load departments',
            Colors.red,
          );
        }
      } else {
        setState(() => _isLoading = false);
        _showSnackBar(
          'Failed to load departments: HTTP ${response.statusCode}',
          Colors.red,
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar('Error loading departments: $e', Colors.red);
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

  void _filterDepartments(String query) {
    List<DepartmentItem> tempFiltered = List.from(departments);

    if (query.isNotEmpty) {
      tempFiltered = tempFiltered
          .where(
            (dept) =>
                dept.department.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    }

    if (_fromDate != null || _toDate != null) {
      // Add date filtering logic here if needed
    }

    setState(() {
      filteredDepartments = tempFiltered;
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
        _filterDepartments(_searchController.text);
      });
    }
  }

  void _deleteDepartment(int index) {
    final deptToDelete = filteredDepartments[index];

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text("Confirm Delete", style: TextStyle(fontFamily: 'serif')),
          content: Text(
            "Are you sure you want to delete '${deptToDelete.department}'?",
            style: TextStyle(fontFamily: 'serif'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text("Cancel", style: TextStyle(fontFamily: 'serif')),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();

                final deptId = deptToDelete.dpt_id;
                setState(() {
                  departments.removeWhere((item) => item.dpt_id == deptId);
                  filteredDepartments.removeWhere(
                    (item) => item.dpt_id == deptId,
                  );
                });
                _showSnackBar('Department deleted successfully', Colors.green);
                _loadDepartments();
                _performDeleteApiCall(deptToDelete);
              },
              child: Text(
                "Delete",
                style: TextStyle(fontFamily: 'serif', color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performDeleteApiCall(DepartmentItem dept) async {
    try {
      final response = await http.post(
        Uri.parse(deleteApiUrl),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{'dpt_id': dept.dpt_id}),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result['status'] != 'true' || result['success'] != '1') {
          _revertDeletion(
            dept,
            result['message'] ?? 'Failed to delete department',
          );
        }
      } else {
        _revertDeletion(dept, 'Failed to connect to server');
      }
    } catch (e) {
      _revertDeletion(dept, 'Error: $e');
    }
  }

  void _revertDeletion(DepartmentItem dept, String errorMessage) {
    if (!mounted) return;

    setState(() {
      if (!departments.any((item) => item.dpt_id == dept.dpt_id)) {
        departments.add(dept);
      }
      if (!filteredDepartments.any((item) => item.dpt_id == dept.dpt_id)) {
        filteredDepartments.add(dept);
        if (_searchController.text.isNotEmpty) {
          _filterDepartments(_searchController.text);
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
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Department List",
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
                      onChanged: (value) => _filterDepartments(value),
                      decoration: InputDecoration(
                        hintText: 'Search by Department Name',
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
                        _filterDepartments(_searchController.text);
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
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddDepartmentScreen(),
                    ),
                  ),
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
                        'New Department',
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
                'Showing ${filteredDepartments.length} records',
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 12,
                  fontFamily: 'serif',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            SizedBox(height: 10),

            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryText,
                      ),
                    )
                  : filteredDepartments.isEmpty
                  ? Center(
                      child: Text(
                        'No departments found',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontFamily: 'serif',
                          fontSize: 16,
                        ),
                      ),
                    )
                  : _buildDepartmentList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDepartmentList() {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 20),
      itemCount: filteredDepartments.length,
      itemBuilder: (context, index) {
        return _buildDepartmentCard(filteredDepartments[index], index);
      },
    );
  }

  Widget _buildDepartmentCard(DepartmentItem department, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey[200]!,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        title: Text(
          department.department,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
            fontFamily: 'serif',
          ),
        ),
        trailing: IconButton(
          onPressed: () => _deleteDepartment(index),
          icon: Icon(Icons.delete, color: Colors.red[400]),
          tooltip: 'Delete',
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

class DepartmentItem {
  final String dpt_id;
  final String department;

  DepartmentItem({required this.dpt_id, required this.department});
}
