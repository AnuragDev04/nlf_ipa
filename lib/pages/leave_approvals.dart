import 'package:flutter/material.dart';
import 'package:nlf/utils/colors.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class LeaveApprovalsScreen extends StatefulWidget {
  const LeaveApprovalsScreen({super.key});

  @override
  State<LeaveApprovalsScreen> createState() => _LeaveApprovalsScreenState();
}

class _LeaveApprovalsScreenState extends State<LeaveApprovalsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<EmployeeItem> employees = [];
  List<EmployeeItem> filteredEmployees = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    try {
      setState(() => _isLoading = true);
      final response = await http.post(
        Uri.parse(AppConstants.EMPLOYEE_LIST_API),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({}),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true && data['success'] == '1') {
          final list = (data['data'] as List).map((item) => EmployeeItem(
            empId: item['emp_id']?.toString() ?? '',
            name: item['name']?.toString() ?? '',
            designation: item['designation']?.toString() ?? '',
            role: item['role']?.toString() ?? '',
            location: item['location']?.toString() ?? '',
            status: item['status']?.toString() ?? '',
          )).toList();
          // Sort by emp_id descending (latest first)
          list.sort((a, b) {
            int idA = int.tryParse(a.empId) ?? 0;
            int idB = int.tryParse(b.empId) ?? 0;
            return idB.compareTo(idA);
          });
          setState(() {
            employees = list;
            filteredEmployees = list;
          });
        }
      }
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterEmployees(String query) {
    setState(() {
      filteredEmployees = employees.where((e) {
        final q = query.toLowerCase();
        return e.name.toLowerCase().contains(q) ||
            e.designation.toLowerCase().contains(q) ||
            e.role.toLowerCase().contains(q) ||
            e.location.toLowerCase().contains(q);
      }).toList();
    });
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
          "Employee Leave",
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
            // Search Bar
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
                  Icon(Icons.search, color: AppColors.primaryText, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: _filterEmployees,
                      decoration: InputDecoration(
                        hintText: 'Search by Name, Role, Location...',
                        hintStyle: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 14,
                          fontFamily: 'serif',
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                      style: const TextStyle(fontSize: 14, fontFamily: 'serif'),
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(Icons.clear, size: 18, color: Colors.grey[600]),
                      onPressed: () {
                        _searchController.clear();
                        _filterEmployees('');
                      },
                    )
                  else
                    const SizedBox(width: 15),
                ],
              ),
            ),

            // Record count badge
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryText.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primaryText.withOpacity(0.3)),
              ),
              child: Text(
                'Showing ${filteredEmployees.length} employees',
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 12,
                  fontFamily: 'serif',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // List
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: AppColors.primaryText))
                  : filteredEmployees.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: filteredEmployees.length,
                          itemBuilder: (context, index) =>
                              _buildEmployeeCard(filteredEmployees[index]),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeCard(EmployeeItem emp) {
    final isActive = emp.status.toLowerCase() == 'active';
    final statusColor = isActive ? const Color(0xFF10B981) : Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
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
                    statusColor,
                    statusColor.withOpacity(0.7),
                    statusColor.withOpacity(0.4),
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
                        backgroundColor: AppColors.primaryText.withOpacity(0.15),
                        child: Text(
                          emp.name.isNotEmpty ? emp.name[0].toUpperCase() : '?',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryText,
                            fontSize: 18,
                            fontFamily: 'serif',
                          ),
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
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E293B),
                                fontFamily: 'serif',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              emp.designation.isNotEmpty ? emp.designation : emp.role,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontFamily: 'serif',
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: statusColor.withOpacity(0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: statusColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              emp.status.toUpperCase(),
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'serif',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Info grid: Role & Location
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildInfoItem(
                            icon: Icons.badge_outlined,
                            label: 'Role',
                            value: emp.role.isNotEmpty ? emp.role : 'N/A',
                            iconColor: const Color(0xFF3B82F6),
                          ),
                        ),
                        Container(width: 1, height: 36, color: Colors.grey[200], margin: const EdgeInsets.symmetric(horizontal: 8)),
                        Expanded(
                          child: _buildInfoItem(
                            icon: Icons.location_on_outlined,
                            label: 'Location',
                            value: emp.location.isNotEmpty ? emp.location : 'N/A',
                            iconColor: const Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Add Leave button
                  Align(
                    alignment: Alignment.centerRight,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _showAddLeaveDialog(emp),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryText.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.primaryText.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryText,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.add, color: Colors.white, size: 12),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Add Leave',
                                style: TextStyle(
                                  color: AppColors.primaryText,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'serif',
                                ),
                              ),
                            ],
                          ),
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

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
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
                  fontFamily: 'serif',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[500],
                  fontFamily: 'serif',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showAddLeaveDialog(EmployeeItem emp) {
    DateTime? fromDate;
    DateTime? toDate;
    int numberOfDays = 0;
    bool isSubmitting = false;
    String? fromDateError;
    String? toDateError;

    String _formatDate(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';

    String _displayDate(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

    void _calcDays(StateSetter set) {
      if (fromDate != null && toDate != null && !toDate!.isBefore(fromDate!)) {
        numberOfDays = toDate!.difference(fromDate!).inDays + 1;
      } else {
        numberOfDays = 0;
      }
      set(() {});
    }

    Future<void> _pickDate(bool isFrom, StateSetter set) async {
      final picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );
      if (picked != null) {
        if (isFrom) {
          fromDate = picked;
          fromDateError = null;
          if (toDate != null && toDate!.isBefore(fromDate!)) toDate = null;
        } else {
          toDate = picked;
          toDateError = null;
        }
        _calcDays(set);
      }
    }

    Future<void> _submitLeave(StateSetter set) async {
      bool valid = true;
      if (fromDate == null) { fromDateError = 'Required'; valid = false; }
      if (toDate == null) { toDateError = 'Required'; valid = false; }
      if (!valid) { set(() {}); return; }

      set(() => isSubmitting = true);
      try {
        final response = await http.post(
          Uri.parse(AppConstants.ADD_LEAVE_API),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'emp_id': emp.empId,
            'from_date': _formatDate(fromDate!),
            'to_date': _formatDate(toDate!),
            'day': numberOfDays.toString(),
          }),
        );
        if (!mounted) return;
        final data = json.decode(response.body);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            data['message']?.toString() ?? 'Leave added successfully',
            style: const TextStyle(fontFamily: 'serif'),
          ),
          backgroundColor: (data['status'] == true || data['success'] == '1')
              ? Colors.green
              : Colors.red,
        ));
      } catch (e) {
        set(() => isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e', style: const TextStyle(fontFamily: 'serif')),
          backgroundColor: Colors.red,
        ));
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => Dialog(
          backgroundColor: Colors.grey[50],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Text(
                    'Add Leave',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      fontFamily: 'serif',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    emp.name,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      fontFamily: 'serif',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Divider(height: 1, color: Colors.grey[300]),
                  const SizedBox(height: 20),

                  // From Date
                  _buildLeaveLabel('From Date', isRequired: true),
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: () => _pickDate(true, set),
                    child: Container(
                      height: 55,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: fromDateError != null
                              ? Colors.red
                              : fromDate != null
                                  ? AppColors.primaryText
                                  : Colors.grey[300]!,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 18,
                            color: fromDateError != null ? Colors.red : Colors.grey[500],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              fromDate != null ? _displayDate(fromDate!) : 'Select from date',
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: 'serif',
                                color: fromDate != null ? Colors.black87 : Colors.grey[500],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (fromDateError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 4),
                      child: Text(fromDateError!, style: const TextStyle(color: Colors.red, fontSize: 12, fontFamily: 'serif')),
                    ),
                  const SizedBox(height: 14),

                  // To Date
                  _buildLeaveLabel('To Date', isRequired: true),
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: () => _pickDate(false, set),
                    child: Container(
                      height: 55,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: toDateError != null
                              ? Colors.red
                              : toDate != null
                                  ? AppColors.primaryText
                                  : Colors.grey[300]!,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 18,
                            color: toDateError != null ? Colors.red : Colors.grey[500],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              toDate != null ? _displayDate(toDate!) : 'Select to date',
                              style: TextStyle(
                                fontSize: 14,
                                fontFamily: 'serif',
                                color: toDate != null ? Colors.black87 : Colors.grey[500],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (toDateError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 4),
                      child: Text(toDateError!, style: const TextStyle(color: Colors.red, fontSize: 12, fontFamily: 'serif')),
                    ),
                  const SizedBox(height: 14),

                  // Number of Days (read-only Material style)
                  _buildLeaveLabel('Number of Days'),
                  const SizedBox(height: 4),
                  Container(
                    height: 55,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Icon(Icons.date_range, size: 18, color: Colors.grey[500]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            numberOfDays > 0
                                ? '$numberOfDays day${numberOfDays > 1 ? 's' : ''}'
                                : 'Auto calculated',
                            style: TextStyle(
                              fontSize: 14,
                              fontFamily: 'serif',
                              fontWeight: numberOfDays > 0 ? FontWeight.w600 : FontWeight.normal,
                              color: numberOfDays > 0 ? AppColors.primaryText : Colors.grey[400],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: isSubmitting ? null : () => _submitLeave(set),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryText,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            disabledBackgroundColor: AppColors.primaryText.withOpacity(0.4),
                          ),
                          child: isSubmitting
                              ? const SizedBox(
                                  width: 20, height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Text(
                                  'Add Leave',
                                  style: TextStyle(fontFamily: 'serif', fontSize: 16),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.grey[600],
                            side: BorderSide(color: Colors.grey[600]!, width: 2.0),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(fontFamily: 'serif', fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeaveLabel(String label, {bool isRequired = false}) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            fontFamily: 'serif',
          ),
        ),
        if (isRequired)
          const Text(' *', style: TextStyle(color: Colors.red, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'serif')),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No employees found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
              fontFamily: 'serif',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search',
            style: TextStyle(fontSize: 14, color: Colors.grey[500], fontFamily: 'serif'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class EmployeeItem {
  final String empId;
  final String name;
  final String designation;
  final String role;
  final String location;
  final String status;

  EmployeeItem({
    required this.empId,
    required this.name,
    required this.designation,
    required this.role,
    required this.location,
    required this.status,
  });
}
