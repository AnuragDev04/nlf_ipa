import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/colors.dart';
import '../utils/constants.dart';
import 'add_job_application_screen.dart';
import 'recruitment_details_screen.dart';

const List<String> kRecruitmentStatuses = [
  'Screening & Shortlisting',
  'Interview Process',
  'Selection Process',
  'Offer Letter & Negotiation',
  'Background Verification',
  'Joining & Onboarding',
];

class JobApplication {
  final String applicationId;
  final String firstName;
  final String middleName;
  final String lastName;
  final String email;
  final String mobile;
  final String location;
  final String jobRole;
  final String jobTitle;
  final String companyName;
  final String resumeFile;
  final String experienceYears;
  final String experienceMonths;
  final DateTime? createdAt;
  String status;

  JobApplication({
    required this.applicationId,
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.email,
    required this.mobile,
    required this.location,
    required this.jobRole,
    required this.jobTitle,
    required this.companyName,
    required this.resumeFile,
    required this.experienceYears,
    required this.experienceMonths,
    required this.status,
    this.createdAt,
  });

  String get fullName =>
      '${firstName.trim()} ${middleName.trim()} ${lastName.trim()}'.trim().replaceAll(RegExp(r'\s+'), ' ');

  factory JobApplication.fromJson(Map<String, dynamic> json) {
    DateTime? createdAt;
    try {
      final dateStr = json['created_at']?.toString() ?? json['application_date']?.toString();
      if (dateStr != null && dateStr.isNotEmpty) {
        createdAt = DateTime.parse(dateStr);
      }
    } catch (e) {
      createdAt = null;
    }
    
    return JobApplication(
      applicationId: json['application_id']?.toString() ?? '',
      firstName: json['first_name']?.toString() ?? '',
      middleName: json['middle_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      mobile: json['mobile_phone']?.toString() ?? '',
      location: json['current_location']?.toString() ?? '',
      jobRole: json['job_role']?.toString() ?? '',
      jobTitle: json['job_title']?.toString() ?? '',
      companyName: json['company_name']?.toString() ?? '',
      resumeFile: json['resume_file']?.toString() ?? '',
      experienceYears: json['experience_years']?.toString() ?? '',
      experienceMonths: json['experience_months']?.toString() ?? '',
      status: json['status']?.toString() ?? kRecruitmentStatuses.first,
      createdAt: createdAt,
    );
  }
}

class AllRecruitmentScreen extends StatefulWidget {
  final String? statusFilter;
  
  const AllRecruitmentScreen({super.key, this.statusFilter});

  @override
  State<AllRecruitmentScreen> createState() => _AllRecruitmentScreenState();
}

class _AllRecruitmentScreenState extends State<AllRecruitmentScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = true;

  List<JobApplication> _all = [];

  List<JobApplication> get _filtered {
    if (_searchQuery.isEmpty) return _all;
    final q = _searchQuery.toLowerCase();
    return _all.where((a) =>
        a.fullName.toLowerCase().contains(q) ||
        a.jobTitle.toLowerCase().contains(q) ||
        a.jobRole.toLowerCase().contains(q) ||
        a.email.toLowerCase().contains(q) ||
        a.location.toLowerCase().contains(q)).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadApplications() async {
    setState(() => _isLoading = true);
    try {
      Map<String, dynamic> requestBody = {'Content-Type': 'application/json'};
      
      // Add status filter if provided
      if (widget.statusFilter != null && widget.statusFilter!.isNotEmpty) {
        requestBody['status'] = widget.statusFilter!;
      }
      
      final response = await http.post(
        Uri.parse(AppConstants.JOB_APPLICATION_LIST_API),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'true' || data['status'] == true) {
          final List<dynamic> raw = data['data'];
          final applications = raw.map((e) => JobApplication.fromJson(e)).toList();
          // Sort by date in descending order (latest first)
          applications.sort((a, b) {
            if (a.createdAt == null && b.createdAt == null) return 0;
            if (a.createdAt == null) return 1;
            if (b.createdAt == null) return -1;
            return b.createdAt!.compareTo(a.createdAt!);
          });
          setState(() => _all = applications);
        } else {
          _showError(data['message']?.toString() ?? 'Failed to load');
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

  Future<void> _updateApplicationStatus(JobApplication application, String newStatus) async {
    try {
      final response = await http.put(
        Uri.parse(AppConstants.UPDATE_JOB_APPLICATION_API),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'application_id': application.applicationId,
          'status': newStatus,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'true' || data['status'] == true) {
          setState(() {
            application.status = newStatus;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Status updated successfully', style: const TextStyle(fontFamily: 'serif')),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } else {
          _showError(data['message']?.toString() ?? 'Failed to update status');
        }
      } else {
        _showError('HTTP ${response.statusCode}');
      }
    } catch (e) {
      _showError('Error updating status: $e');
    }
  }

  void _confirmDelete(JobApplication a) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Application', style: TextStyle(fontFamily: 'serif')),
        content: Text('Are you sure you want to delete "${a.fullName}" application? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(context);
              _deleteApplication(a);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
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

  void _showView(JobApplication a) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primaryText.withValues(alpha: 0.15),
              child: Text(
                a.fullName.isNotEmpty ? a.fullName[0].toUpperCase() : '?',
                style: const TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(a.fullName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'serif')),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _vRow(Icons.work, 'Job Title', a.jobTitle),
              _vRow(Icons.business, 'Job Role', a.jobRole),
              _vRow(Icons.email, 'Email', a.email),
              _vRow(Icons.phone, 'Mobile', a.mobile),
              _vRow(Icons.location_on, 'Location', a.location),
              _vRow(Icons.flag, 'Status', a.status),
              _vRow(Icons.work_history, 'Experience',
                  '${a.experienceYears}y ${a.experienceMonths}m'),
              if (a.resumeFile.isNotEmpty)
                _vRow(Icons.attach_file, 'Resume', a.resumeFile),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryText,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _vRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.primaryText),
          const SizedBox(width: 8),
          SizedBox(width: 80, child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey))),
          Expanded(child: Text(value.isEmpty ? 'N/A' : value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.statusFilter != null && widget.statusFilter!.isNotEmpty 
              ? widget.statusFilter!
              : 'All Recruitment',
          style: const TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold, fontFamily: 'serif', fontSize: 18),
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
                      onChanged: (v) => setState(() => _searchQuery = v),
                      decoration: InputDecoration(
                        hintText: 'Search by name, role, location…',
                        hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14, fontFamily: 'serif'),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    IconButton(
                      icon: Icon(Icons.clear, size: 18, color: Colors.grey[500]),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    ),
                  const SizedBox(width: 5),
                ],
              ),
            ),

            // Count badge
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryText.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primaryText.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    'Showing ${list.length} records',
                    style: const TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 12,
                        fontFamily: 'serif',
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Add Application button (right-aligned, like LeadGenerationScreen)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AddJobApplicationScreen()),
                    );
                    if (result == true && mounted) _loadApplications();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black87,
                    backgroundColor: Colors.transparent,
                    side: const BorderSide(color: Colors.black87, width: 2.0),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 20, height: 20,
                        decoration: const BoxDecoration(
                            color: AppColors.primaryText, shape: BoxShape.circle),
                        child: const Icon(Icons.add, color: Colors.white, size: 14),
                      ),
                      const SizedBox(width: 8),
                      const Text('Add Application',
                          style: TextStyle(
                              color: AppColors.secondaryText,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'serif')),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primaryText))
                  : list.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.search_off, size: 60, color: Colors.grey[300]),
                              const SizedBox(height: 12),
                              Text('No applications found',
                                  style: TextStyle(color: Colors.grey[500], fontSize: 15, fontFamily: 'serif')),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadApplications,
                          color: AppColors.primaryText,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            itemCount: list.length,
                            itemBuilder: (_, i) => _buildCard(list[i]),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(JobApplication a) {
    final color = _statusColor(a.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // Top gradient bar
            Container(
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withValues(alpha: 0.7), color.withValues(alpha: 0.3)],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: avatar + name + status dropdown
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 10, height: 10,
                        margin: const EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(
                          color: color, shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 6, spreadRadius: 1)],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(a.fullName,
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w700,
                                    color: Color(0xFF1E293B), fontFamily: 'serif'),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Text(a.jobTitle.trim().isEmpty ? 'N/A' : a.jobTitle.trim(),
                                style: TextStyle(fontSize: 12, color: Colors.grey[600], fontFamily: 'serif')),
                          ],
                        ),
                      ),
                      // Status dropdown
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: color.withValues(alpha: 0.4)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: kRecruitmentStatuses.contains(a.status) ? a.status : kRecruitmentStatuses.first,
                            isDense: true,
                            icon: Icon(Icons.arrow_drop_down_rounded, size: 16, color: color),
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color, fontFamily: 'serif'),
                            dropdownColor: Colors.white,
                            items: kRecruitmentStatuses.map((s) => DropdownMenuItem(
                              value: s,
                              child: Text(s, style: TextStyle(fontSize: 11, color: _statusColor(s), fontFamily: 'serif')),
                            )).toList(),
                            onChanged: (v) {
                              if (v != null && v != a.status) {
                                _updateApplicationStatus(a, v);
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Info grid card
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _infoItem(Icons.email_outlined, 'Email',
                                a.email.trim().isEmpty ? 'N/A' : a.email.trim(), const Color(0xFF3B82F6))),
                            Container(width: 1, height: 36, color: Colors.grey[200], margin: const EdgeInsets.symmetric(horizontal: 8)),
                            Expanded(child: _infoItem(Icons.phone_outlined, 'Mobile',
                                a.mobile.trim().isEmpty ? 'N/A' : a.mobile.trim(), const Color(0xFF10B981))),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _infoItem(Icons.location_on_outlined, 'Location',
                                a.location.trim().isEmpty ? 'N/A' : a.location.trim(), const Color(0xFFF59E0B))),
                            Container(width: 1, height: 36, color: Colors.grey[200], margin: const EdgeInsets.symmetric(horizontal: 8)),
                            Expanded(child: _infoItem(Icons.business_center_outlined, 'Role',
                                a.jobRole.trim().isEmpty ? 'N/A' : a.jobRole.trim(), const Color(0xFF8B5CF6))),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Resume full width
                        _infoItem(
                          Icons.attach_file,
                          'Resume',
                          a.resumeFile.isEmpty ? 'Not uploaded' : a.resumeFile.split('/').last,
                          const Color(0xFF6366F1),
                          isFullWidth: true,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _actionButton(Icons.visibility_rounded, 'View', const Color(0xFF6366F1), () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RecruitmentDetailsScreen(applicationId: a.applicationId),
                          ),
                        );
                      }),
                      const SizedBox(width: 6),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red.shade700, size: 20),
                        onPressed: () => _confirmDelete(a),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
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

  Widget _infoItem(IconData icon, String label, String value, Color iconColor, {bool isFullWidth = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 23, padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
          child: Icon(icon, size: 13, color: iconColor),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1E293B), fontFamily: 'serif'),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.w500, fontFamily: 'serif')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _actionButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 4),
              Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color, fontFamily: 'serif')),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Screening & Shortlisting':   return const Color(0xFF8B5CF6);
      case 'Interview Process':          return const Color(0xFF0EA5E9);
      case 'Selection Process':          return const Color(0xFF10B981);
      case 'Offer Letter & Negotiation': return const Color(0xFFF59E0B);
      case 'Background Verification':    return const Color(0xFFEF4444);
      case 'Joining & Onboarding':       return const Color(0xFF14B8A6);
      default:                           return Colors.grey;
    }
  }

  Future<void> _deleteApplication(JobApplication application) async {
    try {
      final response = await http.delete(
        Uri.parse(AppConstants.DELETE_JOB_APPLICATION_API),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'application_id': application.applicationId,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'true' || data['status'] == true) {
          setState(() {
            _all.removeWhere((x) => x.applicationId == application.applicationId);
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Application deleted successfully', style: const TextStyle(fontFamily: 'serif')),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } else {
          _showError(data['message']?.toString() ?? 'Failed to delete application');
        }
      } else {
        _showError('HTTP ${response.statusCode}');
      }
    } catch (e) {
      _showError('Error deleting application: $e');
    }
  }
}
