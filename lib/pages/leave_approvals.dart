import 'package:flutter/material.dart';
import 'package:nlf/utils/colors.dart';

class LeaveApprovalsScreen extends StatefulWidget {
  const LeaveApprovalsScreen({super.key});

  @override
  State<LeaveApprovalsScreen> createState() => _LeaveApprovalsScreenState();
}

class _LeaveApprovalsScreenState extends State<LeaveApprovalsScreen> {
  String selectedLeaveType = 'All Types';
  String selectedDate = 'All Dates';
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<LeaveRequest> leaveRequests = [
    LeaveRequest(
      id: '1',
      employeeName: 'Ethan Harper',
      leaveType: 'Vacation',
      startDate: 'Jul 15',
      endDate: 'Jul 20',
      duration: '5 days',
      profileImage: 'assets/images/ethan.jpg',
    ),
    LeaveRequest(
      id: '2',
      employeeName: 'Olivia Bennett',
      leaveType: 'Sick Leave',
      startDate: 'Aug 5',
      endDate: 'Aug 7',
      duration: '3 days',
      profileImage: 'assets/images/olivia.jpg',
    ),
    LeaveRequest(
      id: '3',
      employeeName: 'Noah Carter',
      leaveType: 'Personal Leave',
      startDate: 'Sep 1',
      endDate: 'Sep 3',
      duration: '3 days',
      profileImage: 'assets/images/noah.jpg',
    ),
  ];

  List<LeaveRequest> get filteredLeaveRequests {
    return leaveRequests.where((request) {
      final matchesSearch =
          searchQuery.isEmpty ||
          request.employeeName.toLowerCase().contains(
            searchQuery.toLowerCase(),
          ) ||
          request.leaveType.toLowerCase().contains(searchQuery.toLowerCase());

      final matchesLeaveType =
          selectedLeaveType == 'All Types' ||
          request.leaveType == selectedLeaveType;

      return matchesSearch && matchesLeaveType;
    }).toList();
  }

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
          "LEAVE REQUESTS",
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
      body: Column(
        children: [
          // Search Bar
          // Search Bar - Styled like your second example
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey[50], // matches your original fill color
              borderRadius: BorderRadius.circular(12), // or 15 if you prefer
              border: Border.all(
                color: AppColors.primaryText, // 🔴 Red border as requested
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 15),
                Icon(Icons.search, color: Colors.grey[600], size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (query) {
                      setState(() {
                        searchQuery = query;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search by Employee Name or Leave Type',
                      hintStyle: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 14,
                        fontFamily: 'serif',
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      fontFamily: 'serif',
                    ),
                  ),
                ),
                // Optional: Show clear button only when there's text
                if (searchQuery.isNotEmpty)
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(Icons.clear, size: 18, color: Colors.grey[600]),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        searchQuery = '';
                      });
                    },
                  )
                else
                  const SizedBox(width: 15),
                // maintain right padding when no icon
              ],
            ),
          ),

          // Filter Section
          SizedBox(
            height: 50,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              // reduce vertical padding
              child: Row(
                children: [
                  Expanded(
                    child: _buildFilterDropdown(
                      label: 'Leave Type',
                      value: selectedLeaveType,
                      onChanged: (value) {
                        setState(() {
                          selectedLeaveType = value!;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildFilterDropdown(
                      label: 'Date',
                      value: selectedDate,
                      onChanged: (value) {
                        setState(() {
                          selectedDate = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Leave Requests List
          Expanded(
            child: filteredLeaveRequests.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: filteredLeaveRequests.length,
                    itemBuilder: (context, index) {
                      final request = filteredLeaveRequests[index];
                      return _buildLeaveRequestCard(request);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String value,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 20),
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            fontFamily: 'serif',
          ),
          items: _getDropdownItems(label),
          onChanged: onChanged,
        ),
      ),
    );
  }

  List<DropdownMenuItem<String>> _getDropdownItems(String label) {
    if (label == 'Leave Type') {
      return [
        'All Types',
        'Vacation',
        'Sick Leave',
        'Personal Leave',
        'Emergency Leave',
      ].map((String value) {
        return DropdownMenuItem<String>(value: value, child: Text(value));
      }).toList();
    } else {
      return [
        'All Dates',
        'This Week',
        'This Month',
        'Last Month',
        'Custom Range',
      ].map((String value) {
        return DropdownMenuItem<String>(value: value, child: Text(value));
      }).toList();
    }
  }

  Widget _buildLeaveRequestCard(LeaveRequest request) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Profile Image
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.grey[300],
                child: Text(
                  request.employeeName.split(' ').map((e) => e[0]).join(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'serif',
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Employee Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.employeeName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                        fontFamily: 'serif',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      request.leaveType,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),

              // Date and Duration
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${request.startDate} - ${request.endDate}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    request.duration,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  label: 'Reject',
                  color: Colors.red[50]!,
                  textColor: Colors.red[600]!,
                  onPressed: () => _handleReject(request),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  label: 'Approve',
                  color: Colors.green[50]!,
                  textColor: Colors.green[600]!,
                  onPressed: () => _handleApprove(request),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required Color color,
    required Color textColor,
    required VoidCallback onPressed,
  }) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFamily: 'serif',
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleApprove(LeaveRequest request) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Approve Leave Request'),
          content: Text(
            'Are you sure you want to approve ${request.employeeName}\'s leave request?',
          ),
          actions: [
            // Primary action FIRST (so Cancel appears last visually on Android)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${request.employeeName}\'s leave request approved',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Approve'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _handleReject(LeaveRequest request) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reject Leave Request'),
          content: Text(
            'Are you sure you want to reject ${request.employeeName}\'s leave request?',
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${request.employeeName}\'s leave request rejected',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Reject'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
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
            'No leave requests found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
              fontFamily: 'serif',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
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

class LeaveRequest {
  final String id;
  final String employeeName;
  final String leaveType;
  final String startDate;
  final String endDate;
  final String duration;
  final String profileImage;

  LeaveRequest({
    required this.id,
    required this.employeeName,
    required this.leaveType,
    required this.startDate,
    required this.endDate,
    required this.duration,
    required this.profileImage,
  });
}
