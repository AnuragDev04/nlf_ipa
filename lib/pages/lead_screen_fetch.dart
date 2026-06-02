import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:nlf/utils/colors.dart';
import 'package:nlf/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LeadScreenFetch extends StatefulWidget {
  final String leadId;

  const LeadScreenFetch({super.key, required this.leadId});

  @override
  State<LeadScreenFetch> createState() => _LeadScreenFetchState();
}

class _LeadScreenFetchState extends State<LeadScreenFetch> {
  bool _isLoading = true;
  Map<String, dynamic>? _leadData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchLeadData();
  }

  Future<void> _fetchLeadData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final response = await http.post(
        Uri.parse(AppConstants.FETCH_LEAD_API),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({"id": widget.leadId}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['status'] == 'true' && data['success'] == '1') {
          setState(() {
            _leadData = data['data'];
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = data['message'] ?? 'Failed to fetch lead data';
            _isLoading = false;
          });
          _showErrorSnackBar(_errorMessage!);
        }
      } else {
        setState(() {
          _errorMessage = 'HTTP Error: ${response.statusCode}';
          _isLoading = false;
        });
        _showErrorSnackBar('Failed to connect to server');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
      _showErrorSnackBar('Network error occurred');
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(fontFamily: 'serif'),
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _formatField(String? value, {String fallback = 'N/A'}) {
    if (value == null || value.isEmpty || value == '0') {
      return fallback;
    }
    return value;
  }

  String _formatPrice(String? amount) {
    if (amount == null || amount.isEmpty) return 'N/A';
    return '₹${amount} Lakhs';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          "Lead Details",
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
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: Colors.orange,
        ),
      )
          : _errorMessage != null && _leadData == null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontFamily: 'serif',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _fetchLeadData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(fontFamily: 'serif'),
              ),
            ),
          ],
        ),
      )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            _buildHeaderSection(),
            const SizedBox(height: 24),

            // Basic Info Section - Lead Details
            _buildLeadInfoSection(),
            const SizedBox(height: 24),

            // Additional Details Section
            _buildAdditionalDetailsSection(),
            const SizedBox(height: 24),

            // Remarks & Stage Section - With Card
            _buildRemarksSection(),
            const SizedBox(height: 0),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Project',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontFamily: 'serif',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatField(_leadData?['project_name'])}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontFamily: 'serif',
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getStageColor(_leadData?['stage']).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _getStageColor(_leadData?['stage']),
                  width: 1,
                ),
              ),
              child: Text(
                _formatField(_leadData?['stage'], fallback: 'Unknown')
                    .toUpperCase(),
                style: TextStyle(
                  color: _getStageColor(_leadData?['stage']),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'serif',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getStageColor(String? stage) {
    if (stage == null) return Colors.grey;
    final lowerStage = stage.toLowerCase();
    if (lowerStage.contains('approved') || lowerStage.contains('confirmed')) {
      return Colors.green;
    } else if (lowerStage.contains('pending') ||
        lowerStage.contains('submitted')) {
      return Colors.orange;
    } else if (lowerStage.contains('rejected') ||
        lowerStage.contains('closed')) {
      return Colors.red;
    }
    return Colors.blue;
  }

  Widget _buildLeadInfoSection() {
    return Column(
      children: [
        _buildInfoRow('Client Name', _formatField(_leadData?['client_name'])),
        _buildInfoRow('Architect', _formatField(_leadData?['architech_name'])),
        _buildInfoRow('Product', _formatField(_leadData?['product'])),
        _buildInfoRow('Price', _formatPrice(_leadData?['amount']),
            isAmount: true),
      ],
    );
  }

 /* Widget _buildInfoRow(String label, String value, {bool isAmount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isAmount ? FontWeight.bold : FontWeight.w500,
              color: Colors.black,
              fontFamily: 'serif',
            )),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontFamily: 'serif',
          ),
        ),
      ],
    );
  }*/
  Widget _buildInfoRow(String label, String value, {bool isAmount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start, // Prevents vertical alignment issues
      children: [
        // Label column - fixed minimum width to prevent squeezing
        SizedBox(
          width: 120, // Adjust this value based on your longest key
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isAmount ? FontWeight.bold : FontWeight.w500,
              color: Colors.black,
              fontFamily: 'serif',
            ),
          ),
        ),
        // Value column - flexible with overflow handling
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontFamily: 'serif',
            ),
            maxLines: 2, // Allow up to 2 lines for long values
            overflow: TextOverflow.ellipsis, // Add "..." if text is too long
            softWrap: true, // Allow text to wrap naturally
          ),
        ),
      ],
    );
  }

  Widget _buildAdditionalDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Additional Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontFamily: 'serif',
          ),
        ),
        const SizedBox(height: 16),
        _buildDetailGrid(),
      ],
    );
  }

  Widget _buildDetailGrid() {
    return Container(
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
          _buildGridRow('Email',
              _formatField(_leadData?['email'], fallback: 'Not provided'),
              'Contact',
              _formatField(_leadData?['contact'], fallback: 'Not provided')),
          const SizedBox(height: 16),
          _buildGridRow('Location', _formatField(_leadData?['location']),
              'Branch', _formatField(_leadData?['branch'])),
          const SizedBox(height: 16),
          _buildGridRow('Segment', _formatField(_leadData?['segment']), 'Area',
              '${_formatField(_leadData?['area'])} sqm'),
          const SizedBox(height: 16),
          _buildGridRow('Contractor', _formatField(_leadData?['contractor']),
              'Department', _formatField(_leadData?['department_name'])),
          const SizedBox(height: 16),
          _buildGridRow(
            'Salesperson',
            _formatField(_leadData?['employee_name']),
          ),
        ],
      ),
    );
  }

  // Updated to support optional second key-value pair
  Widget _buildGridRow(String label1, String value1,
      [String? label2, String? value2]) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label1,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontFamily: 'serif',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value1,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                  fontFamily: 'serif',
                ),
              ),
            ],
          ),
        ),
        if (label2 != null && value2 != null) ...[
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label2,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontFamily: 'serif',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value2,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                    fontFamily: 'serif',
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRemarksSection() {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Remarks & Follow-up',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              fontFamily: 'serif',
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child:
                      const Icon(Icons.notes, color: Colors.blue, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Remarks',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                        fontFamily: 'serif',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  _formatField(_leadData?['remark'],
                      fallback: 'No remarks added'),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    fontFamily: 'serif',
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // ✅ Timeline items KEPT in Remarks section (as requested)
          _buildTimelineItem(
            icon: Icons.calendar_today,
            iconColor: Colors.green,
            title: 'Last Visit',
            date: _formatField(_leadData?['visiting_date']),
          ),
          const SizedBox(height: 12),
          _buildTimelineItem(
            icon: Icons.event_available,
            iconColor: Colors.orange,
            title: 'Next Follow-up',
            date: _formatField(_leadData?['nxt_visit_date']),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String date,
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
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black,
                fontFamily: 'serif',
              ),
            ),
            Text(
              date,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontFamily: 'serif',
              ),
            ),
          ],
        ),
      ],
    );
  }
}