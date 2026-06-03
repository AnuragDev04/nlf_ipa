import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:nlf/pages/add_quotation_screen.dart';
import 'package:nlf/pages/quotation_details_screen.dart';
import 'package:nlf/pages/add_order_screen.dart';
import 'package:nlf/utils/colors.dart';
import 'package:nlf/utils/constants.dart';

class QuotationsScreen extends StatefulWidget {
  const QuotationsScreen({super.key});

  @override
  _QuotationsScreenState createState() => _QuotationsScreenState();
}

class _QuotationsScreenState extends State<QuotationsScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _searchController = TextEditingController();
  List<QuotationItem> quotations = [];
  List<QuotationItem> filteredQuotations = [];
  bool _isLoading = false;
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    _fetchQuotations();
  }

  Future<void> _fetchQuotations() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse(AppConstants.QUOTATION_LIST_API));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true || data['status'] == 'true') {
          final List<dynamic> quoteData = data['data'] ?? [];
          setState(() {
            quotations = quoteData.map((json) => QuotationItem.fromJson(json)).toList();
            filteredQuotations = quotations;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? 'Failed to fetch quotations')),
          );
        }
      }
    } catch (e) {
      debugPrint("Error fetching quotations: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterTenders(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredQuotations = quotations;
        _filterByDateRange(); // Re-apply date filter
      } else {
        filteredQuotations = quotations
            .where(
              (quotation) =>
                  quotation.name.toLowerCase().contains(
                    query.toLowerCase(),
                  ) ||
                  quotation.quoteNo.toLowerCase().contains(
                    query.toLowerCase(),
                  ) ||
                  quotation.quoteId.toLowerCase().contains(
                    query.toLowerCase(),
                  ),
            )
            .toList();
        _filterByDateRange(); // Apply date filter to search results
      }
    });
  }

  Future<void> _selectDate(BuildContext context, String type) async {
    // ✅ REMOVED THE BUILDER TO GET SIMPLE DATE PICKER
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      // Removed builder for simple date picker
    );

    if (picked != null) {
      setState(() {
        if (type == 'From') {
          _fromDate = picked;
        } else if (type == 'To') {
          _toDate = picked;
        }

        // Filter after selecting date
        _filterByDateRange();
      });
    }
  }

  void _updateQuotationStatus(int index, String newStatus) {
    setState(() {
      // Find the original index in the main list
      int originalIndex = quotations.indexWhere(
        (q) => q.quoteId == filteredQuotations[index].quoteId,
      );

      if (originalIndex != -1) {
        quotations[originalIndex] = QuotationItem(
          quoteId: quotations[originalIndex].quoteId,
          quoteNo: quotations[originalIndex].quoteNo,
          name: quotations[originalIndex].name,
          date: quotations[originalIndex].date,
          city: quotations[originalIndex].city,
          branch: quotations[originalIndex].branch,
          status: newStatus,
          adminApproval: quotations[originalIndex].adminApproval,
          total: quotations[originalIndex].total,
          terms: quotations[originalIndex].terms,
          items: quotations[originalIndex].items,
        );

        // Update filtered list as well
        filteredQuotations[index] = quotations[originalIndex];
      }
    });
  }

  void _filterByDateRange() {
    setState(() {
      filteredQuotations = quotations.where((quotation) {
        DateTime quotationDate = DateTime.parse(
          quotation.date,
        ); // Ensure date is in 'yyyy-MM-dd' format

        bool afterFrom =
            _fromDate == null ||
            quotationDate.isAfter(_fromDate!.subtract(Duration(days: 1)));
        bool beforeTo =
            _toDate == null ||
            quotationDate.isBefore(_toDate!.add(Duration(days: 1)));

        return afterFrom && beforeTo;
      }).toList();

      // Re-apply search filter if needed
      final String query = _searchController.text;
      if (query.isNotEmpty) {
        filteredQuotations = filteredQuotations
            .where(
              (quotation) =>
                  quotation.name.toLowerCase().contains(
                    query.toLowerCase(),
                  ) ||
                  quotation.quoteNo.toLowerCase().contains(
                    query.toLowerCase(),
                  ) ||
                  quotation.quoteId.toLowerCase().contains(
                    query.toLowerCase(),
                  ),
            )
            .toList();
      }
    });
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'reject':
      case 'rejected':
        return Colors.red;
      case 'revise':
      case 'revised':
        return Colors.orange;
      case 'finalised':
      case 'finalized':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      case 'approved':
      case 'approve':
        return Colors.green;
      case 'draft':
        return Colors.grey;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.blueGrey;
    }
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
          "All Quotations",
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
            // Header
            SizedBox(height: 5),
            // Search Bar
            Container(
              margin: EdgeInsets.symmetric(horizontal: 10),
              // Set fixed height
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: AppColors.primaryText, width: 1.5),
              ),
              child: Row(
                children: [
                  SizedBox(width: 15), // Add some left padding
                  Icon(Icons.search, color: AppColors.primaryText, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: _filterTenders,
                      decoration: InputDecoration(
                        hintText: 'Search by Client name or Quotation number',
                        hintStyle: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 14,
                          fontFamily: 'serif',
                        ),
                        border: InputBorder.none,
                        // Remove content padding from TextField to fit within the container
                        contentPadding: EdgeInsets.zero,
                        isDense: true, // Reduces default padding
                      ),
                    ),
                  ),
                  SizedBox(width: 15), // Add some right padding
                ],
              ),
            ),

            SizedBox(height: 20),

            // Filter Section
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
                        _filterByDateRange();
                      });
                    },
                    icon: Icon(Icons.close, color: Colors.red, size: 25),
                    padding: EdgeInsets.all(8),
                    constraints: BoxConstraints(),
                    splashRadius: 20,
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

            // New Quotation Button
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddQuotationScreen(),
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
                        'New Quotation',
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

            SizedBox(height: 20),

            // Quotation List
            Expanded(
              child: RefreshIndicator(
                onRefresh: _fetchQuotations,
                color: AppColors.primaryText,
                child: _isLoading && quotations.isEmpty
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primaryText))
                    : filteredQuotations.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.description_outlined, size: 64, color: Colors.grey[300]),
                                const SizedBox(height: 16),
                                const Text(
                                  'No quotations found',
                                  style: TextStyle(fontFamily: 'serif', color: Color(0xFF94A3B8), fontSize: 16),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            itemCount: filteredQuotations.length,
                            itemBuilder: (context, index) {
                              return _buildEnhancedQuotationCard(filteredQuotations[index]);
                            },
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateButton(String label) {
    DateTime? selectedDate;

    if (label == 'From') {
      selectedDate = _fromDate;
    } else if (label == 'To') {
      selectedDate = _toDate;
    }

    return GestureDetector(
      onTap: () => _selectDate(context, label),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
            SizedBox(width: 5),
            Text(
              selectedDate != null
                  ? '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'
                  : label,
              style: TextStyle(
                color: selectedDate != null ? Colors.black87 : Colors.grey[700],
                fontSize: 12,
                fontFamily: 'serif',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedQuotationCard(QuotationItem quotation) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QuotationDetailsScreen(),
                ),
              );
            },
            child: Column(
              children: [
                // Status Bar
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getStatusColor(quotation.status),
                        _getStatusColor(quotation.status).withOpacity(0.6),
                      ],
                    ),
                  ),
                ),

                Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: _getStatusColor(
                                quotation.status,
                              ).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.description_outlined,
                              color: _getStatusColor(quotation.status),
                              size: 22,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  quotation.name,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1E293B),
                                    fontFamily: 'serif',
                                  ),
                                ),
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today_rounded,
                                      size: 12,
                                      color: Color(0xFF94A3B8),
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      quotation.date,
                                      style: TextStyle(
                                        color: Color(0xFF64748B),
                                        fontSize: 12,
                                        fontFamily: 'serif',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(
                                quotation.status,
                              ).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              quotation.status.toUpperCase(),
                              style: TextStyle(
                                color: _getStatusColor(quotation.status),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                fontFamily: 'serif',
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 16),

                      // Info Grid
                      Container(
                        padding: EdgeInsets.all(12),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildInfoItem(
                                Icons.receipt_long_rounded,
                                'Quote No',
                                quotation.quoteNo.isNotEmpty ? quotation.quoteNo : 'ID: ${quotation.quoteId}',
                                Color(0xFF3B82F6),
                              ),
                            ),
                            if (quotation.status.toLowerCase() == 'approved') ...[
                              Container(
                                width: 1,
                                height: 40,
                                color: Color(0xFFE2E8F0),
                              ),
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AddOrderScreen(),
                                      ),
                                    );
                                  },
                                  child: Center(
                                    child: Container(
                                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [Colors.orange, Colors.orangeAccent],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.orange.withOpacity(0.3),
                                            blurRadius: 4,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        'Create Work Order',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'serif',
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      SizedBox(height: 16),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: _buildEnhancedActionButton(
                              Icons.visibility_rounded,
                              'View',
                              Color(0xFF6366F1),
                              Color(0xFFEEF2FF),
                              () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        QuotationDetailsScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: _buildEnhancedActionButton(
                              Icons.download_rounded,
                              'Download',
                              Color(0xFF10B981),
                              Color(0xFFECFDF5),
                              () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Downloading ${quotation.quoteNo.isNotEmpty ? quotation.quoteNo : quotation.quoteId}...',
                                    ),
                                    backgroundColor: Color(0xFF10B981),
                                  ),
                                );
                              },
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: _buildEnhancedActionButton(
                              Icons.history_rounded,
                              'Revision',
                              Colors.white,
                              Colors.transparent,
                              () => _showCreateRevisionDialog(
                                context,
                                quotation,
                              ),
                              gradient: LinearGradient(
                                colors: [Colors.red, Colors.redAccent],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              textColor: Colors.white,
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
        ),
      ),
    );
  }

  Widget _buildInfoItem(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: color.withOpacity(0.7)),
              SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'serif',
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
              fontFamily: 'serif',
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedActionButton(
    IconData icon,
    String label,
    Color color,
    Color bgColor,
    VoidCallback onTap, {
    Gradient? gradient,
    Color? textColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: gradient == null ? bgColor : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: textColor ?? color, size: 16),
                SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      color: textColor ?? color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'serif',
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditReasonDialog(BuildContext context, QuotationItem quotation) {
    TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Edit Rejection Reason',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'serif',
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quotation: ${quotation.quoteNo.isNotEmpty ? quotation.quoteNo : quotation.quoteId}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  fontFamily: 'serif',
                ),
              ),
              Text(
                'Customer: ${quotation.name}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  fontFamily: 'serif',
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Enter rejection reason',
                  labelStyle: TextStyle(
                    color: Colors.black, // ✅ Black label text
                    fontFamily: 'serif',
                  ),
                  hintText: 'Enter reason for rejection...',
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    fontFamily: 'serif',
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Colors.grey, // ✅ Grey focus border
                      width: 2.0,
                    ),
                  ),
                  contentPadding: EdgeInsets.all(12),
                  constraints: const BoxConstraints(
                    minHeight: 55, // ✅ Fixed height
                    maxHeight: 55,
                  ),
                ),
                style: TextStyle(
                  color: Colors.black, // ✅ Black text
                  fontFamily: 'serif',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontFamily: 'serif',
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // Handle save reason logic here
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Rejection reason saved for ${quotation.quoteNo.isNotEmpty ? quotation.quoteNo : quotation.quoteId}',
                      style: TextStyle(fontFamily: 'serif'),
                    ),
                    backgroundColor: Colors.red[400],
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryText,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Save Reason',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'serif',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showCreateRevisionDialog(
    BuildContext context,
    QuotationItem quotation,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Create Revision',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'serif',
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quotation: ${quotation.quoteNo.isNotEmpty ? quotation.quoteNo : quotation.quoteId}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  fontFamily: 'serif',
                ),
              ),
              Text(
                'Customer: ${quotation.name}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                  fontFamily: 'serif',
                ),
              ),
              SizedBox(height: 16),
              Text(
                'This will create a new revision of the quotation with updated terms and conditions.',
                style: TextStyle(fontSize: 14, fontFamily: 'serif'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontFamily: 'serif',
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // Handle create revision logic here
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Revision created for ${quotation.quoteNo.isNotEmpty ? quotation.quoteNo : quotation.quoteId}',
                      style: TextStyle(fontFamily: 'serif'),
                    ),
                    backgroundColor: Colors.orange[400],
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryText,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Create Revision',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'serif',
                ),
              ),
            ),
          ],
        );
      },
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
            color: Colors.black, // ✅ Black label text
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
            borderSide: BorderSide(
              color: Colors.grey, // ✅ Grey focus border
              width: 2.0,
            ),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          constraints: const BoxConstraints(
            minHeight: 55, // ✅ Fixed height
            maxHeight: 55,
          ),
        ),
        controller: TextEditingController(
          text: selectedDate != null
              ? '${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}'
              : '',
        ),
        onTap: () => _selectDate(context, label),
        style: TextStyle(
          color: Colors.black, // ✅ Black text
          fontSize: 14,
          fontFamily: 'serif',
        ),
      ),
    );
  }
}

class QuotationItem {
  final String quoteId;
  final String quoteNo;
  final String name;
  final String date;
  final String city;
  final String branch;
  final String status;
  final String adminApproval;
  final String total;
  final String terms;
  final List<dynamic> items;

  QuotationItem({
    required this.quoteId,
    required this.quoteNo,
    required this.name,
    required this.date,
    required this.city,
    required this.branch,
    required this.status,
    required this.adminApproval,
    required this.total,
    required this.terms,
    required this.items,
  });

  factory QuotationItem.fromJson(Map<String, dynamic> json) {
    String status = json['status']?.toString() ?? '';
    // Fallback logic if status is missing or empty
    if (status.isEmpty || status.toLowerCase() == 'draft') {
      if (json['admin_approval']?.toString().toLowerCase() == 'yes') {
        status = 'Approved';
      }
    }

    return QuotationItem(
      quoteId: json['quote_id']?.toString() ?? '',
      quoteNo: json['quote_no']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      branch: json['branch']?.toString() ?? '',
      status: status,
      adminApproval: json['admin_approval']?.toString() ?? '',
      total: json['total']?.toString() ?? '',
      terms: json['terms']?.toString() ?? '',
      items: json['items'] ?? [],
    );
  }
}
