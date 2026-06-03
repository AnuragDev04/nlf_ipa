import 'package:flutter/material.dart';
import 'package:nlf/utils/colors.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import 'package:intl/intl.dart';

class OfferLetterApprovalScreen extends StatefulWidget {
  const OfferLetterApprovalScreen({super.key});

  @override
  State<OfferLetterApprovalScreen> createState() => _OfferLetterApprovalScreenState();
}

class _OfferLetterApprovalScreenState extends State<OfferLetterApprovalScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<OfferLetterRecord> allOfferLetters = [];
  List<OfferLetterRecord> filteredOfferLetters = [];
  bool _isLoading = true;
  int _selectedTabIndex = 0; // 0: All, 1: Pending, 2: Approved

  @override
  void initState() {
    super.initState();
    _loadOfferLetters();
  }

  Future<void> _loadOfferLetters() async {
    try {
      setState(() => _isLoading = true);
      
      Map<String, dynamic> requestBody = {};
      
      // Set parameters based on selected tab
      if (_selectedTabIndex == 1) {
        // Pending tab - show only Pending records
        requestBody = {"offer_approval": "Pending"};
      } else if (_selectedTabIndex == 2) {
        // Approved tab - show only Approved records
        requestBody = {"offer_approval": "Approved"};
      }
      // For All tab (index 0), send empty body - no parameters
      
      final response = await http.post(
        Uri.parse(AppConstants.OFFER_LETTER_LIST_API),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == "true"|| data['status'] == true) {
          final list = (data['data'] as List).map((item) => OfferLetterRecord(
            id: item['id']?.toString() ?? '',
            to: item['to']?.toString() ?? 'Unknown',
            subject: item['subject']?.toString() ?? '',
            role: item['role']?.toString() ?? '',
            place: item['place']?.toString() ?? '',
            startDate: item['start_date']?.toString() ?? '',
            returnDate: item['return_date']?.toString() ?? '',
            offerApproval: item['offer_approval']?.toString() ?? 'Pending',
            createdAt: item['created_at']?.toString() ?? '',
            updatedAt: item['updated_at']?.toString() ?? '',
          )).toList();
          
          // Sort by latest data first in descending order - multiple criteria
          list.sort((a, b) {
            // Primary sort: by created_at (most recent first)
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
            
            // Secondary sort: by updated_at if created_at is same or unavailable
            if (a.updatedAt.isNotEmpty && b.updatedAt.isNotEmpty) {
              try {
                final dateA = DateTime.parse(a.updatedAt);
                final dateB = DateTime.parse(b.updatedAt);
                final result = dateB.compareTo(dateA); // Descending order
                if (result != 0) return result;
              } catch (e) {
                // If parsing fails, continue to next criteria
              }
            }
            
            // Tertiary sort: by start_date (most recent start dates first)
            if (a.startDate.isNotEmpty && b.startDate.isNotEmpty) {
              try {
                final dateA = DateTime.parse(a.startDate);
                final dateB = DateTime.parse(b.startDate);
                final result = dateB.compareTo(dateA); // Descending order
                if (result != 0) return result;
              } catch (e) {
                // If parsing fails, continue to next criteria
              }
            }
            
            // Final fallback: by ID (higher ID = more recent record)
            final idA = int.tryParse(a.id) ?? 0;
            final idB = int.tryParse(b.id) ?? 0;
            return idB.compareTo(idA); // Descending order
          });
          
          setState(() {
            allOfferLetters = list;
            filteredOfferLetters = list;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading offer letters: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterOfferLetters(String query) {
    setState(() {
      filteredOfferLetters = allOfferLetters.where((offer) {
        final q = query.toLowerCase();
        return offer.to.toLowerCase().contains(q) ||
            offer.subject.toLowerCase().contains(q) ||
            offer.role.toLowerCase().contains(q) ||
            offer.place.toLowerCase().contains(q);
      }).toList();
    });
  }

  void _onTabChanged(int index) {
    setState(() {
      _selectedTabIndex = index;
      _searchController.clear();
    });
    _loadOfferLetters();
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('d MMM yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'approved by management':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'approved by management':
        return Icons.check_circle_rounded;
      case 'pending':
        return Icons.pending_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
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
          "Offer Letter Approvals",
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
                      onChanged: _filterOfferLetters,
                      decoration: InputDecoration(
                        hintText: 'Search by Name, Subject, Role, Place...',
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
                        _filterOfferLetters('');
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
                'Showing ${filteredOfferLetters.length} offer letters',
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
                  : filteredOfferLetters.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: filteredOfferLetters.length,
                          itemBuilder: (context, index) =>
                              _buildOfferLetterCard(filteredOfferLetters[index]),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomTabBar() {
    final List<String> tabTitles = ["All", "Pending", "Approved"];

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

  Widget _buildOfferLetterCard(OfferLetterRecord offer) {
    final statusColor = _getStatusColor(offer.offerApproval);
    bool isChecked = false;

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
                          _getStatusIcon(offer.offerApproval),
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
                              offer.to,
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
                              offer.role.isNotEmpty 
                                  ? offer.role 
                                  : 'No role specified',
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
                              offer.offerApproval.toUpperCase(),
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

                  // Offer details grid
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
                                icon: Icons.subject_rounded,
                                label: 'Subject',
                                value: offer.subject.isNotEmpty ? offer.subject : 'N/A',
                                iconColor: const Color(0xFF3B82F6),
                              ),
                            ),
                            Container(width: 1, height: 36, color: Colors.grey[200], margin: const EdgeInsets.symmetric(horizontal: 8)),
                            Expanded(
                              child: _buildInfoItem(
                                icon: Icons.location_on_rounded,
                                label: 'Place',
                                value: offer.place.isNotEmpty ? offer.place : 'N/A',
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
                                icon: Icons.calendar_today_rounded,
                                label: 'Start Date',
                                value: _formatDate(offer.startDate),
                                iconColor: const Color(0xFFEF4444),
                              ),
                            ),
                            Container(width: 1, height: 36, color: Colors.grey[200], margin: const EdgeInsets.symmetric(horizontal: 8)),
                            Expanded(
                              child: _buildInfoItem(
                                icon: Icons.event_rounded,
                                label: 'Return Date',
                                value: _formatDate(offer.returnDate),
                                iconColor: const Color(0xFF8B5CF6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Offer Approval Checkbox Section
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withOpacity(0.1)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.approval_rounded, color: Colors.blue[700], size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Offer Approval',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                            fontFamily: 'serif',
                          ),
                        ),
                        const Spacer(),
                        StatefulBuilder(
                          builder: (context, setCheckboxState) {
                            bool isApproved = offer.offerApproval.toLowerCase() == 'approved';
                            return Checkbox(
                              value: isApproved,
                              onChanged: offer.offerApproval.toLowerCase() == 'pending' 
                                ? (bool? value) {
                                    if (value == true) {
                                      _approveOfferLetter(offer);
                                    }
                                  }
                                : null, // Disable checkbox if already approved or rejected
                              activeColor: AppColors.primaryText,
                              checkColor: Colors.white,
                            );
                          },
                        ),
                      ],
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

  Future<void> _approveOfferLetter(OfferLetterRecord offer) async {
    try {
      final response = await http.put(
        Uri.parse(AppConstants.UPDATE_OFFER_LETTER_STATUS_API),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "id": offer.id,
          "offer_approval": "Approved"
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == "true") {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Offer letter approved successfully', style: TextStyle(fontFamily: 'serif')),
              backgroundColor: Colors.green,
            ),
          );
          _loadOfferLetters(); // Refresh the list
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${data['message'] ?? 'Failed to approve offer letter'}', style: const TextStyle(fontFamily: 'serif')),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to approve offer letter', style: TextStyle(fontFamily: 'serif')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e', style: const TextStyle(fontFamily: 'serif')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildEmptyState() {
    String emptyMessage = 'No offer letters found';
    if (_selectedTabIndex == 1) {
      emptyMessage = 'No pending offer letters';
    } else if (_selectedTabIndex == 2) {
      emptyMessage = 'No approved offer letters';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.work_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            emptyMessage,
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
                : 'Offer letters will appear here',
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

class OfferLetterRecord {
  final String id;
  final String to;
  final String subject;
  final String role;
  final String place;
  final String startDate;
  final String returnDate;
  final String offerApproval;
  final String createdAt;
  final String updatedAt;

  OfferLetterRecord({
    required this.id,
    required this.to,
    required this.subject,
    required this.role,
    required this.place,
    required this.startDate,
    required this.returnDate,
    required this.offerApproval,
    required this.createdAt,
    required this.updatedAt,
  });
}