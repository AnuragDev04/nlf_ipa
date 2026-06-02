import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:nlf/pages/onboarding.dart';
import 'package:nlf/pages/employee_detail_screen.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';

class EmployeeScreen extends StatefulWidget {
  const EmployeeScreen({super.key});

  @override
  State<EmployeeScreen> createState() => _EmployeeScreenState();
}

class _EmployeeScreenState extends State<EmployeeScreen> {
  final _searchController = TextEditingController();

  List<EmployeeModel> _allEmployees = [];
  List<EmployeeModel> _filteredEmployees = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadEmployees() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse(AppConstants.EMPLOYEE_LIST_API),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if ((data['status'] == true || data['status'] == 'true') &&
            (data['success'] == '1' || data['success'] == 1)) {
          final List<dynamic> raw = data['data'];
          final list = raw.map((item) => EmployeeModel.fromJson(item)).toList();
          // Sort descending by emp_id so latest employee appears first
          list.sort((a, b) {
            final idA = int.tryParse(a.empId) ?? 0;
            final idB = int.tryParse(b.empId) ?? 0;
            return idB.compareTo(idA);
          });
          setState(() {
            _allEmployees = list;
            _filteredEmployees = List.from(list);
          });
        } else {
          _showError(data['message']?.toString() ?? 'Failed to load employees');
        }
      } else {
        _showError('HTTP ${response.statusCode}');
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: 'serif')),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _filter(String query) {
    setState(() {
      _filteredEmployees = query.isEmpty
          ? List.from(_allEmployees)
          : _allEmployees
              .where((e) =>
                  e.name.toLowerCase().contains(query.toLowerCase()) ||
                  e.email.toLowerCase().contains(query.toLowerCase()) ||
                  e.designation.toLowerCase().contains(query.toLowerCase()))
              .toList();
    });
  }

  Future<void> _deleteEmployee(EmployeeModel emp) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete', style: TextStyle(fontFamily: 'serif')),
        content: Text(
          'Are you sure you want to delete ${emp.name}?',
          style: const TextStyle(fontFamily: 'serif'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(fontFamily: 'serif')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(fontFamily: 'serif', color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final response = await http.post(
        Uri.parse(AppConstants.DELETE_EMPLOYEE_DATA_API),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'emp_id': emp.empId}),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if ((result['status'] == 'true' || result['status'] == true) &&
            (result['success'] == '1' || result['success'] == 1)) {
          setState(() {
            _allEmployees.removeWhere((e) => e.empId == emp.empId);
            _filteredEmployees.removeWhere((e) => e.empId == emp.empId);
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  result['message']?.toString() ?? 'Employee deleted successfully',
                  style: const TextStyle(fontFamily: 'serif'),
                ),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  result['message']?.toString() ?? 'Failed to delete employee',
                  style: const TextStyle(fontFamily: 'serif'),
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Server error: HTTP ${response.statusCode}',
                style: const TextStyle(fontFamily: 'serif'),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: $e',
              style: const TextStyle(fontFamily: 'serif'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
          'Employee List',
          style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontFamily: 'serif',
              fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 40,
        titleSpacing: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: AppColors.primaryText, width: 1.5),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 15),
                  const Icon(Icons.search, color: AppColors.primaryText, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: _filter,
                      decoration: InputDecoration(
                        hintText: 'Search by Name, Email, Designation',
                        hintStyle: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                            fontFamily: 'serif'),
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

            // New Employee button + count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Record count badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryText.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppColors.primaryText.withOpacity(0.3)),
                    ),
                    child: Text(
                      'Showing ${_filteredEmployees.length} records',
                      style: const TextStyle(
                          color: AppColors.primaryText,
                          fontSize: 12,
                          fontFamily: 'serif',
                          fontWeight: FontWeight.w500),
                    ),
                  ),

                  // New Employee button
                  OutlinedButton(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const OnboardingScreen()),
                      );
                      _loadEmployees();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black87,
                      side: const BorderSide(color: Colors.black87, width: 2.0),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                              color: AppColors.primaryText,
                              shape: BoxShape.circle),
                          child: const Icon(Icons.add,
                              color: Colors.white, size: 14),
                        ),
                        const SizedBox(width: 8),
                        const Text('New Employee',
                            style: TextStyle(
                                color: AppColors.secondaryText,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                fontFamily: 'serif')),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // List
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primaryText))
                  : _filteredEmployees.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_outline,
                                  size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text('No employees found',
                                  style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                      fontFamily: 'serif')),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadEmployees,
                          color: AppColors.primaryText,
                          child: ListView.builder(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 10),
                            itemCount: _filteredEmployees.length,
                            itemBuilder: (_, i) =>
                                _buildCard(_filteredEmployees[i]),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(EmployeeModel emp) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 4))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // Top color bar
            Container(
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryText,
                    AppColors.primaryText.withOpacity(0.7),
                    AppColors.primaryText.withOpacity(0.3),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row: avatar + name + status badge
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor:
                            AppColors.primaryText.withOpacity(0.15),
                        child: Text(
                          emp.name.isNotEmpty
                              ? emp.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              color: AppColors.primaryText,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              fontFamily: 'serif'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              emp.name,
                              style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1E293B),
                                  fontFamily: 'serif'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'ID: ${emp.empId}',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[500],
                                  fontFamily: 'serif'),
                            ),
                          ],
                        ),
                      ),
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: emp.status.toLowerCase() == 'active'
                              ? Colors.green.withOpacity(0.12)
                              : Colors.grey.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: emp.status.toLowerCase() == 'active'
                                ? Colors.green.withOpacity(0.4)
                                : Colors.grey.withOpacity(0.4),
                          ),
                        ),
                        child: Text(
                          emp.status.isEmpty ? 'N/A' : emp.status,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'serif',
                              color: emp.status.toLowerCase() == 'active'
                                  ? Colors.green[700]
                                  : Colors.grey[600]),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Info grid
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _infoItem(
                                icon: Icons.email_outlined,
                                label: 'Email',
                                value: emp.email.isEmpty ? 'N/A' : emp.email,
                                iconColor: const Color(0xFF3B82F6),
                              ),
                            ),
                            Container(
                                width: 1,
                                height: 36,
                                color: Colors.grey[200],
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 8)),
                            Expanded(
                              child: _infoItem(
                                icon: Icons.work_outline,
                                label: 'Designation',
                                value: emp.designation.isEmpty
                                    ? 'N/A'
                                    : emp.designation,
                                iconColor: const Color(0xFF8B5CF6),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _infoItem(
                          icon: Icons.calendar_today_outlined,
                          label: 'Joining Date',
                          value: emp.joiningDate.isEmpty
                              ? 'N/A'
                              : emp.joiningDate,
                          iconColor: const Color(0xFF10B981),
                          isFullWidth: true,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Action row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _actionButton(
                        icon: Icons.visibility_rounded,
                        label: 'View',
                        color: const Color(0xFF6366F1),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EmployeeDetailScreen(
                                empId: emp.empId),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        icon: Icon(Icons.delete,
                            color: Colors.red.shade700, size: 20),
                        onPressed: () => _deleteEmployee(emp),
                        tooltip: 'Delete',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 6),
                      // Offer button
                      Material(
                        color: const Color(0xFF0EA5E9),
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Offer letter for ${emp.name}',
                                    style: const TextStyle(
                                        fontFamily: 'serif')),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            child: const Text(
                              'Offer',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  fontFamily: 'serif'),
                            ),
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

  Widget _infoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
    bool isFullWidth = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 23,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 13, color: iconColor),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                    fontFamily: 'serif'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                    fontFamily: 'serif'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 4),
              Text(label,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: color,
                      fontFamily: 'serif')),
            ],
          ),
        ),
      ),
    );
  }

}

class EmployeeModel {
  final String empId;
  final String name;
  final String email;
  final String mobile;
  final String designation;
  final String joiningDate;
  final String status;
  final String role;
  final String location;

  EmployeeModel({
    required this.empId,
    required this.name,
    required this.email,
    required this.mobile,
    required this.designation,
    required this.joiningDate,
    required this.status,
    required this.role,
    required this.location,
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeModel(
      empId: json['emp_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      mobile: json['mob']?.toString() ?? '',
      designation: json['designation']?.toString() ?? '',
      joiningDate: json['joining_date']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
    );
  }
}
