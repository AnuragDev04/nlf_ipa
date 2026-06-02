import 'package:flutter/material.dart';
import 'package:nlf/utils/colors.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../utils/constants.dart';

class FollowUpScreen extends StatefulWidget {
  const FollowUpScreen({super.key});

  @override
  _FollowUpScreenState createState() => _FollowUpScreenState();
}

class _FollowUpScreenState extends State<FollowUpScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<FollowUpItem> _followUps = [];
  List<FollowUpItem> _filteredFollowUps = [];
  bool _isLoading = true;
  String? _approvingId;

  final String _apiUrl = AppConstants.SALES_FOLLOWUP_LIST_API;
  final String _updateApiUrl = AppConstants.UPDATE_FOLLOWUP_API;

  @override
  void initState() {
    super.initState();
    _loadFollowUps();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFollowUps() async {
    try {
      setState(() => _isLoading = true);

      final today = DateFormat('dd-MM-yyyy').format(DateTime.now());

      final requestBody = {'nxt_visit_date': today, 'emp_id': ''};

      print('📡 Fetching follow-ups from: $_apiUrl');
      print('📤 Request body: $requestBody');

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        final success = data['success'];
        final isSuccess = success == 1 || success == '1' || success == true;

        if ((data['status'] == 'True' || data['status'] == 'true') &&
            isSuccess &&
            data['data'] != null) {
          List<dynamic> followUpData = data['data'];

          List<FollowUpItem> loadedItems = followUpData.map((item) {
            return FollowUpItem(
              id: item['id']?.toString() ?? '',
              projectName: item['project_name']?.toString() ?? 'N/A',
              clientName: item['client_name']?.toString() ?? 'N/A',
              visitingDate: item['visiting_date']?.toString() ?? 'N/A',
              nextVisitDate: item['nxt_visit_date']?.toString() ?? 'N/A',
              product: item['product']?.toString() ?? '',
              architectName: item['architech_name']?.toString() ?? '',
              branch: item['branch']?.toString() ?? '',
              location: item['location']?.toString() ?? '',
              stage: item['stage']?.toString() ?? '',
              remark: item['remark']?.toString() ?? '',
              amount: item['amount']?.toString() ?? '',
              area: item['area']?.toString() ?? '',
              empApproval:
                  item['emp_approval']?.toString()?.toLowerCase() ?? 'pending',
              empId: item['emp_id']?.toString() ?? '',
            );
          }).toList();

          setState(() {
            _followUps = loadedItems;
            _filteredFollowUps = List.from(loadedItems);
            _isLoading = false;
          });

          print('✅ Loaded ${loadedItems.length} follow-up items');
        } else {
          setState(() => _isLoading = false);
          print('❌ API Error: ${data['message']}');
          _showSnackBar(
            data['message'] ?? 'Failed to load follow-ups',
            Colors.red,
          );
        }
      } else {
        setState(() => _isLoading = false);
        print('❌ HTTP Error: ${response.statusCode}');
        _showSnackBar(
          'Failed to load: HTTP ${response.statusCode}',
          Colors.red,
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print('❌ Exception: $e');
      _showSnackBar('Error: $e', Colors.red);
    }
  }

  // ✅ FIXED: Toggle approval with correct parameters & instant UI update
  Future<void> _toggleApproval(FollowUpItem item) async {
    // Prevent duplicate taps on same item
    if (_approvingId == item.id) return;

    // ✅ Already approved? Show message and return
    if (item.empApproval.toLowerCase() == 'approved') {
      _showSnackBar('Already approved!', Colors.grey);
      return;
    }

    print('🔄 Approving follow-up ID: ${item.id}');

    // Show loading state for this specific item
    setState(() => _approvingId = item.id);

    try {
      // ✅ CORRECTED REQUEST BODY:
      // - 'id': Use item.id (lead ID from list) - DYNAMIC
      // - 'emp_approval': Always "Approved" - STATIC
      final requestBody = {
        'id': item.id, // ✅ Dynamic: from list data
        'emp_approval': 'Approved', // ✅ Static: always "Approved"
      };

      print('📤 Update request: $requestBody');

      final response = await http.post(
        Uri.parse(_updateApiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      print('📥 Update response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        final success = result['success'];
        final isSuccess = success == 1 || success == '1' || success == true;

        if ((result['status'] == 'True' || result['status'] == 'true') &&
            isSuccess) {
          _updateLocalApprovalStatus(item.id, 'Approved');
          _showSnackBar(result['Follow Up Done'] ?? 'Approved!', Colors.green);
          _loadFollowUps();
        } else {
          _showSnackBar(result['Follow Up Done'] ?? 'Approved!', Colors.green);
          _loadFollowUps();
        }
      } else {
        //_showSnackBar(result['message'] ?? 'Failed to update', Colors.red);
        _showSnackBar('Server error: ${response.statusCode}', Colors.red);
      }
    } catch (e) {
      print('❌ Approval error: $e');
      _showSnackBar('Error: $e', Colors.red);
    } finally {
      // Clear loading state
      if (mounted) {
        setState(() => _approvingId = null);
      }
    }
  }

  // ✅ Update local lists instantly without re-fetching
  void _updateLocalApprovalStatus(String id, String newStatus) {
    // Update in MAIN list
    final mainIndex = _followUps.indexWhere((item) => item.id == id);
    if (mainIndex != -1) {
      _followUps[mainIndex] = _followUps[mainIndex].copyWith(
        empApproval: newStatus,
      );
    }

    // Update in FILTERED list (for instant UI reflection)
    final filteredIndex = _filteredFollowUps.indexWhere(
      (item) => item.id == id,
    );
    if (filteredIndex != -1) {
      _filteredFollowUps[filteredIndex] = _filteredFollowUps[filteredIndex]
          .copyWith(empApproval: newStatus);
    }
  }

  void _filterFollowUps(String query) {
    if (query.isEmpty) {
      setState(() => _filteredFollowUps = List.from(_followUps));
      return;
    }

    final lowerQuery = query.toLowerCase();
    final filtered = _followUps
        .where(
          (item) =>
              item.projectName.toLowerCase().contains(lowerQuery) ||
              item.clientName.toLowerCase().contains(lowerQuery) ||
              item.location.toLowerCase().contains(lowerQuery),
        )
        .toList();

    setState(() => _filteredFollowUps = filtered);
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

  Color _getApprovalStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getStageColor(String stage) {
    final stageLower = stage.toLowerCase().trim();

    if (stageLower.contains('upcoming') || stageLower.contains('new') || stageLower.contains('lead')) {
      return const Color(0xFF3B82F6); // Blue
    } else if (stageLower.contains('tender') || stageLower.contains('rfp') || stageLower.contains('bid')) {
      return const Color(0xFFF59E0B); // Amber/Orange
    } else if (stageLower.contains('quotation submitted') || stageLower.contains('quote') || stageLower.contains('proposal')) {
      return const Color(0xFF14B8A6); // Teal
    } else if (stageLower.contains('negotiation') || stageLower.contains('negotiation')) {
      return const Color(0xFFEC4899); // Pink
    } else if (stageLower.contains('order received') || stageLower.contains('confirmed') || stageLower.contains('won')) {
      return const Color(0xFF10B981); // Green
    } else if (stageLower.contains('closed') || stageLower.contains('completed') || stageLower.contains('delivered')) {
      return const Color(0xFF6366F1); // Indigo
    } else if (stageLower.contains('lost') || stageLower.contains('rejected') || stageLower.contains('cancelled')) {
      return const Color(0xFFEF4444); // Red
    } else if (stageLower.contains('pending') || stageLower.contains('hold') || stageLower.contains('onhold')) {
      return const Color(0xFF8B5CF6); // Purple
    } else if (stageLower.contains('under specification') || stageLower.contains('technical')) {
      return const Color(0xFFA855F7); // Violet
    } else if (stageLower.contains('open') || stageLower.contains('active')) {
      return const Color(0xFFEAB308); // Yellow
    }

    return const Color(0xFF6B7280);
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
          "Follow-Ups",
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

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
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
                      onChanged: _filterFollowUps,
                      decoration: const InputDecoration(
                        hintText: 'Search by Project, Client, Location',
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
                'Showing ${_filteredFollowUps.length} follow-ups',
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 12,
                  fontFamily: 'serif',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryText,
                      ),
                    )
                  : _filteredFollowUps.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.assignment_turned_in_rounded,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No follow-ups found',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontFamily: 'serif',
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredFollowUps.length,
                      itemBuilder: (context, index) {
                        return _buildFollowUpCard(_filteredFollowUps[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFollowUpCard(FollowUpItem item) {
    final isApproved = item.empApproval.toLowerCase() == 'approved';
    final isProcessing = _approvingId == item.id;

    final stageColor = _getStageColor(item.stage);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.projectName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                              fontFamily: 'serif',
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: stageColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: stageColor.withOpacity(0.4),
                              ),
                            ),
                            child: Text(
                              item.stage.isNotEmpty
                                  ? item.stage.toUpperCase()
                                  : 'N/A',
                              style: TextStyle(
                                color: stageColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'serif',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _toggleApproval(item),
                      child: Row(
                        children: [
                          if (isProcessing)
                            const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: isApproved
                                    ? Colors.green
                                    : Colors.transparent,
                                border: Border.all(
                                  color: isApproved
                                      ? Colors.green
                                      : Colors.grey[400]!,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: isApproved
                                  ? const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 14,
                                    )
                                  : null,
                            ),
                          const SizedBox(width: 6),
                          Text(
                            'Done',
                            style: TextStyle(
                              color: isApproved
                                  ? Colors.green
                                  : Colors.grey[600],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'serif',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Icon(
                      Icons.person_outline_rounded,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Client: ',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'serif',
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item.clientName,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'serif',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Visited On: ',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'serif',
                      ),
                    ),
                    Text(
                      item.visitingDate != 'N/A'
                          ? _formatDate(item.visitingDate)
                          : 'N/A',
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'serif',
                      ),
                    ),
                  ],
                ),

                if (item.nextVisitDate != 'N/A' &&
                    item.nextVisitDate.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.event_available_rounded,
                        size: 14,
                        color: Colors.orange[700],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Next: ',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'serif',
                        ),
                      ),
                      Text(
                        _formatDate(item.nextVisitDate),
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'serif',
                        ),
                      ),
                    ],
                  ),
                ],

                if (item.remark.isNotEmpty && item.remark != 'N/A') ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.notes_rounded,
                          size: 14,
                          color: Colors.blue[700],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item.remark,
                            style: TextStyle(
                              color: Colors.grey[800],
                              fontSize: 12,
                              fontFamily: 'serif',
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      if (dateString.isEmpty || dateString == 'N/A') return 'N/A';
      final parts = dateString.split('-');
      if (parts.length == 3) {
        final day = parts[0];
        final month = _getMonthName(parts[1]);
        final year = parts[2];
        return '$day $month $year';
      }
      return dateString;
    } catch (_) {
      return dateString;
    }
  }

  String _getMonthName(String monthNum) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final index = int.tryParse(monthNum);
    if (index != null && index >= 1 && index <= 12) {
      return months[index - 1];
    }
    return monthNum;
  }
}

class FollowUpItem {
  final String id;
  final String projectName;
  final String clientName;
  final String visitingDate;
  final String nextVisitDate;
  final String product;
  final String architectName;
  final String branch;
  final String location;
  final String stage;
  final String remark;
  final String amount;
  final String area;
  String empApproval;
  final String empId;

  FollowUpItem({
    required this.id,
    required this.projectName,
    required this.clientName,
    required this.visitingDate,
    required this.nextVisitDate,
    required this.product,
    required this.architectName,
    required this.branch,
    required this.location,
    required this.stage,
    required this.remark,
    required this.amount,
    required this.area,
    required this.empApproval,
    required this.empId,
  });

  FollowUpItem copyWith({
    String? id,
    String? projectName,
    String? clientName,
    String? visitingDate,
    String? nextVisitDate,
    String? product,
    String? architectName,
    String? branch,
    String? location,
    String? stage,
    String? remark,
    String? amount,
    String? area,
    String? empApproval,
    String? empId,
  }) {
    return FollowUpItem(
      id: id ?? this.id,
      projectName: projectName ?? this.projectName,
      clientName: clientName ?? this.clientName,
      visitingDate: visitingDate ?? this.visitingDate,
      nextVisitDate: nextVisitDate ?? this.nextVisitDate,
      product: product ?? this.product,
      architectName: architectName ?? this.architectName,
      branch: branch ?? this.branch,
      location: location ?? this.location,
      stage: stage ?? this.stage,
      remark: remark ?? this.remark,
      amount: amount ?? this.amount,
      area: area ?? this.area,
      empApproval: empApproval ?? this.empApproval,
      empId: empId ?? this.empId,
    );
  }
}
