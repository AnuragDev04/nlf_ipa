import 'package:flutter/material.dart';
import 'package:nlf/utils/colors.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import 'package:intl/intl.dart';

class LeaveApprovalListScreen extends StatefulWidget {
  const LeaveApprovalListScreen({super.key});

  @override
  State<LeaveApprovalListScreen> createState() => _LeaveApprovalListScreenState();
}

class _LeaveApprovalListScreenState extends State<LeaveApprovalListScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<LeaveRecord> allLeaves = [];
  List<LeaveRecord> filteredLeaves = [];
  bool _isLoading = true;
  int _selectedTabIndex = 0; // 0: Pending, 1: Approved

  @override
  void initState() {
    super.initState();
    _loadLeaveRecords();
  }

  Future<void> _loadLeaveRecords() async {
    try {
      setState(() => _isLoading = true);
      
      final leaveApprovalStatus = _selectedTabIndex == 0 ? "pending" : "approved";
      
      final response = await http.post(
        Uri.parse(AppConstants.ATTENDANCE_LIST_API),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"leave_approval": leaveApprovalStatus}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == "true" && data['success'] == "1") {
          final list = (data['data'] as List).map((item) => LeaveRecord(
            id: item['id']?.toString() ?? '',
            empId: item['emp_id']?.toString() ?? '',
            empName: item['name']?.toString() ?? item['emp_name']?.toString() ?? 'Unknown',
            designation: item['designation']?.toString() ?? '',
            fromDate: item['from_date']?.toString() ?? '',
            toDate: item['to_date']?.toString() ?? '',
            attendanceDate: item['attendance_date']?.toString() ?? '',
            day: item['day']?.toString() ?? '',
            leaveType: item['leav_type']?.toString() ?? '',
            leaveApproval: item['leave_approval']?.toString() ?? '',
            status: item['status']?.toString() ?? '',
            createdAt: item['created_at']?.toString() ?? '',
          )).toList();
          
          // Sort by date in descending order (latest dates first)
          list.sort((a, b) {
            // Primary sort: by from_date (most recent leave dates first)
            if (a.fromDate.isNotEmpty && b.fromDate.isNotEmpty) {
              try {
                final dateA = DateTime.parse(a.fromDate);
                final dateB = DateTime.parse(b.fromDate);
                final result = dateB.compareTo(dateA); // Descending order
                if (result != 0) return result;
              } catch (e) {
                // If parsing fails, continue to next criteria
              }
            }
            
            // Secondary sort: by attendance_date if from_date is same or unavailable
            if (a.attendanceDate.isNotEmpty && b.attendanceDate.isNotEmpty) {
              try {
                final dateA = DateTime.parse(a.attendanceDate);
                final dateB = DateTime.parse(b.attendanceDate);
                final result = dateB.compareTo(dateA); // Descending order
                if (result != 0) return result;
              } catch (e) {
                // If parsing fails, continue to next criteria
              }
            }
            
            // Tertiary sort: by created_at (most recent submissions first)
            if (a.createdAt.isNotEmpty && b.createdAt.isNotEmpty) {
              try {
                final dateA = DateTime.parse(a.createdAt);
                final dateB = DateTime.parse(b.createdAt);
                final result = dateB.compareTo(dateA); // Descending order
                if (result != 0) return result;
              } catch (e) {
                // If parsing fails, continue to next criteria
              }
            }
            
            // Quaternary sort: by to_date if other dates are same
            if (a.toDate.isNotEmpty && b.toDate.isNotEmpty) {
              try {
                final dateA = DateTime.parse(a.toDate);
                final dateB = DateTime.parse(b.toDate);
                final result = dateB.compareTo(dateA); // Descending order
                if (result != 0) return result;
              } catch (e) {
                // If parsing fails, fallback to ID comparison
              }
            }
            
            // Final fallback: by ID (higher ID = more recent record)
            final idA = int.tryParse(a.id) ?? 0;
            final idB = int.tryParse(b.id) ?? 0;
            return idB.compareTo(idA); // Descending order
          });
          
          setState(() {
            allLeaves = list;
            filteredLeaves = list;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading leave records: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterLeaves(String query) {
    setState(() {
      filteredLeaves = allLeaves.where((leave) {
        final q = query.toLowerCase();
        return leave.empName.toLowerCase().contains(q) ||
            leave.designation.toLowerCase().contains(q) ||
            leave.leaveType.toLowerCase().contains(q);
      }).toList();
    });
  }

  void _onTabChanged(int index) {
    setState(() {
      _selectedTabIndex = index;
      _searchController.clear();
    });
    _loadLeaveRecords();
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('d MMM yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  String _getStatusDisplayText(String status, String approval) {
    if (approval.toLowerCase() == 'pending') return 'Pending';
    if (approval.toLowerCase() == 'approved') return 'Approved';
    return status;
  }

  Color _getStatusColor(String approval) {
    switch (approval.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String approval) {
    switch (approval.toLowerCase()) {
      case 'approved':
        return Icons.check_circle_rounded;
      case 'pending':
        return Icons.pending_rounded;
      default:
        return Icons.help_rounded;
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
          "Leave Approvals",
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
            // Tab Bar
            _buildCustomTabBar(),
            
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
                      onChanged: _filterLeaves,
                      decoration: InputDecoration(
                        hintText: 'Search by Name, Designation, Leave Type...',
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
                        _filterLeaves('');
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
                'Showing ${filteredLeaves.length} leave records',
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
                  : filteredLeaves.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: filteredLeaves.length,
                          itemBuilder: (context, index) =>
                              _buildLeaveCard(filteredLeaves[index]),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomTabBar() {
    final List<String> tabTitles = ["Pending", "Approved"];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      height: 45,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: List.generate(tabTitles.length, (index) {
          final isSelected = _selectedTabIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => _onTabChanged(index),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryText : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  tabTitles[index],
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    fontFamily: 'serif',
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildLeaveCard(LeaveRecord leave) {
    final statusColor = _getStatusColor(leave.leaveApproval);

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
                  // Header row: icon + name + status badge
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getStatusIcon(leave.leaveApproval),
                          color: statusColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              leave.empName,
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
                              leave.designation.isNotEmpty 
                                  ? leave.designation 
                                  : 'Employee ID: ${leave.empId}',
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
                              _getStatusDisplayText(leave.status, leave.leaveApproval).toUpperCase(),
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

                  // Leave details grid
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
                              child: _buildInfoItem(
                                icon: Icons.calendar_today_rounded,
                                label: 'From Date',
                                value: _formatDate(leave.fromDate),
                                iconColor: const Color(0xFF3B82F6),
                              ),
                            ),
                            Container(width: 1, height: 36, color: Colors.grey[200], margin: const EdgeInsets.symmetric(horizontal: 8)),
                            Expanded(
                              child: _buildInfoItem(
                                icon: Icons.event_rounded,
                                label: 'To Date',
                                value: _formatDate(leave.toDate),
                                iconColor: const Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoItem(
                                icon: Icons.timer_rounded,
                                label: 'Duration',
                                value: leave.day.isNotEmpty ? leave.day : 'N/A',
                                iconColor: const Color(0xFFEF4444),
                              ),
                            ),
                            Container(width: 1, height: 36, color: Colors.grey[200], margin: const EdgeInsets.symmetric(horizontal: 8)),
                            Expanded(
                              child: _buildInfoItem(
                                icon: Icons.category_rounded,
                                label: 'Leave Type',
                                value: leave.leaveType.isNotEmpty ? leave.leaveType : 'General',
                                iconColor: const Color(0xFF8B5CF6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Approval action for pending items
                  if (_selectedTabIndex == 0) ...[
                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _showApprovalDialog(leave),
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
                                Icon(Icons.approval_rounded, color: AppColors.primaryText, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  'Approve',
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

  void _showApprovalDialog(LeaveRecord leave) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Approve Leave Request',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            fontFamily: 'serif',
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Employee: ${leave.empName}',
              style: const TextStyle(fontSize: 14, fontFamily: 'serif'),
            ),
            const SizedBox(height: 4),
            Text(
              'Duration: ${leave.day}',
              style: const TextStyle(fontSize: 14, fontFamily: 'serif'),
            ),
            const SizedBox(height: 4),
            Text(
              'Dates: ${_formatDate(leave.fromDate)} - ${_formatDate(leave.toDate)}',
              style: const TextStyle(fontSize: 14, fontFamily: 'serif'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey[600],
                fontFamily: 'serif',
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _approveLeave(leave);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text(
              'Approve',
              style: TextStyle(fontFamily: 'serif'),
            ),
          ),
        ],
      ),
    );
  }

  void _approveLeave(LeaveRecord leave) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.primaryText),
              const SizedBox(height: 16),
              const Text(
                'Approving leave request...',
                style: TextStyle(fontFamily: 'serif', fontSize: 14),
              ),
            ],
          ),
        ),
      );

      final response = await http.post(
        Uri.parse(AppConstants.UPDATE_LEAVE_APPROVAL_API),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "id": leave.id,
          "leave_approval": "Approved"
        }),
      );

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == "true" && data['success'] == "1") {
          // Success - show success message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  data['message']?.toString() ?? 'Leave approved successfully',
                  style: const TextStyle(fontFamily: 'serif'),
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
              ),
            );
            
            // Refresh the list to update the data
            _loadLeaveRecords();
          }
        } else {
          // API returned error
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  data['message']?.toString() ?? 'Failed to approve leave',
                  style: const TextStyle(fontFamily: 'serif'),
                ),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      } else {
        // HTTP error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Server error: ${response.statusCode}',
                style: const TextStyle(fontFamily: 'serif'),
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      // Network or parsing error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${e.toString()}',
              style: const TextStyle(fontFamily: 'serif'),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            _selectedTabIndex == 0 ? 'No pending leave requests' : 'No approved leaves found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
              fontFamily: 'serif',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isNotEmpty 
                ? 'Try adjusting your search'
                : 'Leave requests will appear here',
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

class LeaveRecord {
  final String id;
  final String empId;
  final String empName;
  final String designation;
  final String fromDate;
  final String toDate;
  final String attendanceDate;
  final String day;
  final String leaveType;
  final String leaveApproval;
  final String status;
  final String createdAt;

  LeaveRecord({
    required this.id,
    required this.empId,
    required this.empName,
    required this.designation,
    required this.fromDate,
    required this.toDate,
    required this.attendanceDate,
    required this.day,
    required this.leaveType,
    required this.leaveApproval,
    required this.status,
    required this.createdAt,
  });
}