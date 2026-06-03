import 'package:flutter/material.dart';
import 'package:nlf/pages/appointment_generater_add_screen.dart';
import 'package:nlf/pages/appointment_generater_edit_screen.dart';
import 'package:nlf/utils/colors.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class AppointmentGenerationScreen extends StatefulWidget {
  const AppointmentGenerationScreen({super.key});

  @override
  State<AppointmentGenerationScreen> createState() =>
      _AppointmentGenerationScreenState();
}

class _AppointmentGenerationScreenState
    extends State<AppointmentGenerationScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<AppointmentItem> appointments = [];
  List<AppointmentItem> filteredAppointments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    try {
      setState(() => _isLoading = true);
      final response = await http.get(
        Uri.parse(AppConstants.APPOINTMENT_LETTER_LIST_API),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'true' && data['data'] != null) {
          final list = (data['data'] as List).map((item) => AppointmentItem(
                id: item['id']?.toString() ?? '',
                to: item['to']?.toString() ?? '',
                appointmentDate: item['appointment_date']?.toString() ?? '',
                probationPeriod: item['probation_period']?.toString() ?? '',
                payPackage: item['pay_package']?.toString() ?? '',
                officeTiming: item['office_timing']?.toString() ?? '',
                noticePeriod: item['notice_period']?.toString() ?? '',
                appointmentApproval:
                    item['appointment_approval']?.toString() ?? '',
              )).toList();

          list.sort((a, b) {
            int idA = int.tryParse(a.id) ?? 0;
            int idB = int.tryParse(b.id) ?? 0;
            return idB.compareTo(idA);
          });

          setState(() {
            appointments = list;
            filteredAppointments = list;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading appointments: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterAppointments(String query) {
    final q = query.toLowerCase();
    setState(() {
      filteredAppointments = appointments.where((a) {
        return a.to.toLowerCase().contains(q) ||
            a.appointmentDate.toLowerCase().contains(q) ||
            a.probationPeriod.toLowerCase().contains(q) ||
            a.payPackage.toLowerCase().contains(q) ||
            a.appointmentApproval.toLowerCase().contains(q);
      }).toList();
    });
  }

  Future<void> _deleteAppointment(AppointmentItem appointment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete',
            style: TextStyle(fontFamily: 'serif')),
        content: Text(
          'Are you sure you want to delete appointment for "${appointment.to.isNotEmpty ? appointment.to : 'this record'}"?',
          style: const TextStyle(fontFamily: 'serif'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:
                const Text('Cancel', style: TextStyle(fontFamily: 'serif')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(fontFamily: 'serif', color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final response = await http.post(
        Uri.parse(AppConstants.DELETE_APPOINTMENT_LETTER_API),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': appointment.id}),
      );
      if (response.statusCode == 200) {
        setState(() {
          appointments.removeWhere((a) => a.id == appointment.id);
          filteredAppointments.removeWhere((a) => a.id == appointment.id);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Deleted successfully',
                style: TextStyle(fontFamily: 'serif')),
            backgroundColor: Colors.green,
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text('Error: $e', style: const TextStyle(fontFamily: 'serif')),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Color _getApprovalColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return const Color(0xFF10B981);
      case 'rejected':
        return const Color(0xFFEF4444);
      case 'pending':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF6B7280);
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
          'Appointment Letters',
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
                      onChanged: _filterAppointments,
                      decoration: InputDecoration(
                        hintText: 'Search by Name, Date, Package, Status...',
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
                        _filterAppointments('');
                      },
                    )
                  else
                    const SizedBox(width: 15),
                ],
              ),
            ),

            // Generate New button
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              child: Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddAppointmentScreen(),
                      ),
                    );
                    if (result == true && mounted) _loadAppointments();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black87,
                    backgroundColor: Colors.transparent,
                    side: const BorderSide(color: Colors.black87, width: 2.0),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
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
                        child: const Icon(Icons.add,
                            color: Colors.white, size: 14),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Generate New',
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

            const SizedBox(height: 10),

            // Record count badge
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryText.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border:
                    Border.all(color: AppColors.primaryText.withOpacity(0.3)),
              ),
              child: Text(
                'Showing ${filteredAppointments.length} records',
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
                  ? Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primaryText))
                  : filteredAppointments.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: filteredAppointments.length,
                          itemBuilder: (context, index) =>
                              _buildAppointmentCard(filteredAppointments[index]),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(AppointmentItem appointment) {
    final approvalColor = _getApprovalColor(appointment.appointmentApproval);

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
            // Colored top bar
            Container(
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    approvalColor,
                    approvalColor.withOpacity(0.7),
                    approvalColor.withOpacity(0.4),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row: dot + name + status badge
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        margin: const EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(
                          color: approvalColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: approvalColor.withOpacity(0.4),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          appointment.to.isNotEmpty ? appointment.to : '—',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                            fontFamily: 'serif',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: approvalColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Border.all(color: approvalColor.withOpacity(0.4)),
                        ),
                        child: Text(
                          appointment.appointmentApproval.isNotEmpty
                              ? appointment.appointmentApproval
                              : 'N/A',
                          style: TextStyle(
                            color: approvalColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'serif',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Info grid: Appointment Date, Probation Period, Pay Package
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
                                icon: Icons.calendar_today_outlined,
                                label: 'Appointment Date',
                                value: appointment.appointmentDate.isNotEmpty
                                    ? appointment.appointmentDate
                                    : 'N/A',
                                iconColor: const Color(0xFF3B82F6),
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 36,
                              color: Colors.grey[200],
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 8),
                            ),
                            Expanded(
                              child: _buildInfoItem(
                                icon: Icons.schedule_outlined,
                                label: 'Probation Period',
                                value: appointment.probationPeriod.isNotEmpty
                                    ? appointment.probationPeriod
                                    : 'N/A',
                                iconColor: const Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildInfoItem(
                          icon: Icons.payments_outlined,
                          label: 'Pay Package',
                          value: appointment.payPackage.isNotEmpty
                              ? appointment.payPackage
                              : 'N/A',
                          iconColor: const Color(0xFF8B5CF6),
                          isFullWidth: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Action buttons: View, Edit, Delete
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _buildActionButton(
                        icon: Icons.visibility_rounded,
                        label: 'View',
                        color: const Color(0xFF6366F1),
                        onTap: () {
                          // TODO: navigate to appointment detail screen
                        },
                      ),
                      const SizedBox(width: 6),
                      _buildActionButton(
                        icon: Icons.edit_rounded,
                        label: 'Edit',
                        color: const Color(0xFFF59E0B),
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AppointmentGeneraterEditScreen(
                                appointmentId: appointment.id,
                              ),
                            ),
                          );
                          if (result == true && mounted) _loadAppointments();
                        },
                      ),
                      const SizedBox(width: 6),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _deleteAppointment(appointment),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.delete_rounded,
                                    size: 13, color: Colors.red.shade700),
                                const SizedBox(width: 4),
                                Text(
                                  'Delete',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.red.shade700,
                                    fontFamily: 'serif',
                                  ),
                                ),
                              ],
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

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
    bool isFullWidth = false,
  }) {
    return Container(
      padding: isFullWidth
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
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
              mainAxisSize: MainAxisSize.min,
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
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                    fontFamily: 'serif',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
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
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color,
                  fontFamily: 'serif',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.description_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No appointment letters found',
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
            style: TextStyle(
                fontSize: 14, color: Colors.grey[500], fontFamily: 'serif'),
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

class AppointmentItem {
  final String id;
  final String to;
  final String appointmentDate;
  final String probationPeriod;
  final String payPackage;
  final String officeTiming;
  final String noticePeriod;
  final String appointmentApproval;

  AppointmentItem({
    required this.id,
    required this.to,
    required this.appointmentDate,
    required this.probationPeriod,
    required this.payPackage,
    required this.officeTiming,
    required this.noticePeriod,
    required this.appointmentApproval,
  });
}
