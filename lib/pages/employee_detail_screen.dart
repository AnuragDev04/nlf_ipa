import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/colors.dart';
import '../utils/constants.dart';

class EmployeeDetailScreen extends StatefulWidget {
  final String empId;
  const EmployeeDetailScreen({super.key, required this.empId});

  @override
  State<EmployeeDetailScreen> createState() => _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends State<EmployeeDetailScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _data;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchEmployee();
  }

  Future<void> _fetchEmployee() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final response = await http.post(
        Uri.parse(AppConstants.EMPLOYEE_FETCH_BY_ID_API),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'emp_id': widget.empId}),
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['status'] == 'true' || result['status'] == true) {
          setState(() {
            _data = result['data'];
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = result['message']?.toString() ?? 'Failed to fetch data';
            _isLoading = false;
          });
          _showError(_errorMessage!);
        }
      } else {
        setState(() {
          _errorMessage = 'HTTP Error: ${response.statusCode}';
          _isLoading = false;
        });
        _showError('Failed to connect to server');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
      _showError('Network error occurred');
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: 'serif')),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _f(String key, {String fallback = 'N/A'}) {
    final v = _data?[key];
    if (v == null) return fallback;
    final s = v.toString().trim();
    return s.isEmpty ? fallback : s;
  }

  List<String> _docs() {
    final raw = _data?['doc'];
    if (raw == null) return [];
    if (raw is List) return raw.map((e) => e.toString()).toList();
    if (raw is String && raw.isNotEmpty) return [raw];
    return [];
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'inactive':
        return Colors.red;
      default:
        return Colors.blue;
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
          'Employee Details',
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
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryText))
          : _errorMessage != null && _data == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 48, color: Colors.grey[600]),
                      const SizedBox(height: 16),
                      Text(_errorMessage!,
                          style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontFamily: 'serif'),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _fetchEmployee,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryText,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8))),
                        child: const Text('Retry',
                            style: TextStyle(fontFamily: 'serif')),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 24),
                      _buildBasicInfo(),
                      const SizedBox(height: 24),
                      _buildAdditionalDetails(),
                      const SizedBox(height: 24),
                      if (_docs().isNotEmpty) ...[
                        _buildDocumentsSection(),
                        const SizedBox(height: 24),
                      ],
                      _buildWorkSection(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }

  // Header: Name + status badge (like Project + stage badge)
  Widget _buildHeader() {
    final status = _f('status');
    final color = _statusColor(status);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Employee',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        fontFamily: 'serif')),
                const SizedBox(height: 4),
                Text(_f('name'),
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontFamily: 'serif')),
              ],
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color, width: 1),
              ),
              child: Text(
                status.toUpperCase(),
                style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'serif'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Basic info rows (like Client Name, Architect, Product, Price)
  Widget _buildBasicInfo() {
    return Column(
      children: [
        _buildInfoRow('Designation', _f('designation')),
        _buildInfoRow('Role', _f('role')),
        _buildInfoRow('Experience', '${_f('experience')} yrs'),
        _buildInfoRow('Salary', '₹ ${_f('salary')}', isBold: true),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(label,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                      isBold ? FontWeight.bold : FontWeight.w500,
                  color: Colors.black,
                  fontFamily: 'serif')),
        ),
        Expanded(
          child: Text(value,
              style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontFamily: 'serif'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  // Additional Details grid card (like lead's Additional Details)
  Widget _buildAdditionalDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Additional Details',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontFamily: 'serif')),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2))
            ],
          ),
          child: Column(
            children: [
              _buildGridRow('Email',
                  _f('email', fallback: 'Not provided'),
                  'Mobile',
                  _f('mob', fallback: 'Not provided')),
              const SizedBox(height: 16),
              _buildGridRow('Location', _f('location'), 'Blood Group',
                  _f('blood_group')),
              const SizedBox(height: 16),
              _buildGridRow('Date of Birth', _f('dob'), 'Joining Date',
                  _f('joining_date')),
              const SizedBox(height: 16),
              _buildGridRow('Work Type', _f('type'), 'Gender',
                  _f('gender')),
              const SizedBox(height: 16),
              _buildGridRow('Emergency Contact',
                  _f('emergency_contact_no', fallback: 'Not provided')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGridRow(String label1, String value1,
      [String? label2, String? value2]) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label1,
                  style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontFamily: 'serif')),
              const SizedBox(height: 4),
              Text(value1,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                      fontFamily: 'serif')),
            ],
          ),
        ),
        if (label2 != null && value2 != null) ...[
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label2,
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontFamily: 'serif')),
                const SizedBox(height: 4),
                Text(value2,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                        fontFamily: 'serif')),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // Documents section (like Remarks & Follow-up card)
  Widget _buildDocumentsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Documents',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontFamily: 'serif')),
          const SizedBox(height: 16),
          ..._docs().map((doc) {
            final fileName = doc.split('/').last;
            final ext = fileName.split('.').last.toLowerCase();
            final isPdf = ext == 'pdf';
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isPdf
                          ? Colors.red.withOpacity(0.1)
                          : Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isPdf
                          ? Icons.picture_as_pdf
                          : Icons.image_outlined,
                      color: isPdf ? Colors.red : Colors.blue,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(fileName,
                        style: const TextStyle(
                            fontSize: 14,
                            fontFamily: 'serif',
                            color: Colors.black87),
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // Work section (like Remarks card with timeline items)
  Widget _buildWorkSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Remarks & Info',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontFamily: 'serif')),
          const SizedBox(height: 16),
          _buildTimelineItem(
            icon: Icons.calendar_today,
            iconColor: Colors.green,
            title: 'Joining Date',
            subtitle: _f('joining_date'),
          ),
          const SizedBox(height: 12),
          _buildTimelineItem(
            icon: Icons.cake_outlined,
            iconColor: Colors.orange,
            title: 'Date of Birth',
            subtitle: _f('dob'),
          ),
          const SizedBox(height: 12),
          _buildTimelineItem(
            icon: Icons.work_history_outlined,
            iconColor: Colors.blue,
            title: 'Experience',
            subtitle: '${_f('experience')} years',
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    fontFamily: 'serif')),
            Text(subtitle,
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontFamily: 'serif')),
          ],
        ),
      ],
    );
  }
}
