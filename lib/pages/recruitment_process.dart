import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/colors.dart';
import '../utils/constants.dart';
import 'all_recruitment_screen.dart' show AllRecruitmentScreen;
import 'recruitment_details_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DATA MODEL
// ─────────────────────────────────────────────────────────────────────────────

const List<String> kRecruitmentStatuses = [
  'Screening & Shortlisting',
  'Interview Process',
  'Selection Decision',
  'Offer Letter & Negotiation',
  'Background Verification',
  'Joining & Onboarding',
];

class Applicant {
  final String id;
  final String name;
  final String jobTitle;
  final String department;
  final String email;
  final String mobile;
  final String location;
  final String? resumeUrl;
  final DateTime? createdAt;
  String status;

  Applicant({
    required this.id,
    required this.name,
    required this.jobTitle,
    required this.department,
    required this.email,
    required this.mobile,
    required this.location,
    this.resumeUrl,
    this.createdAt,
    required this.status,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// RECRUITMENT PROCESS SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class RecruitmentProcessScreen extends StatelessWidget {
  const RecruitmentProcessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<_StageCard> cards = [
      _StageCard(
        title: 'All\nRecruitment',
        icon: Icons.groups,
        iconColor: Color(0xFF3B82F6),
        bgColor: Color(0xFFEFF6FF),
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AllRecruitmentScreen())),
      ),
      _StageCard(
        title: 'Screening &\nShortlisting',
        icon: Icons.filter_list_alt,
        iconColor: Color(0xFF8B5CF6),
        bgColor: Color(0xFFF5F3FF),
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AllRecruitmentScreen(statusFilter: 'Screening & Shortlisting'))),
      ),
      _StageCard(
        title: 'Interview\nProcess',
        icon: Icons.record_voice_over,
        iconColor: Color(0xFF0EA5E9),
        bgColor: Color(0xFFE0F2FE),
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AllRecruitmentScreen(statusFilter: 'Interview Process'))),
      ),
      _StageCard(
        title: 'Selection\nDecision',
        icon: Icons.how_to_reg,
        iconColor: Color(0xFF10B981),
        bgColor: Color(0xFFECFDF5),
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AllRecruitmentScreen(statusFilter: 'Selection Process'))),
      ),
      _StageCard(
        title: 'Offer Letter &\nNegotiation',
        icon: Icons.description,
        iconColor: Color(0xFFF59E0B),
        bgColor: Color(0xFFFFFBEB),
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AllRecruitmentScreen(statusFilter: 'Offer Letter & Negotiation'))),
      ),
      _StageCard(
        title: 'Background\nVerification',
        icon: Icons.verified_user,
        iconColor: Color(0xFFEF4444),
        bgColor: Color(0xFFFEF2F2),
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AllRecruitmentScreen(statusFilter: 'Background Verification'))),
      ),
      _StageCard(
        title: 'Joining &\nOnboarding',
        icon: Icons.person_add_alt_1,
        iconColor: Color(0xFF14B8A6),
        bgColor: Color(0xFFEFFEFE),
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AllRecruitmentScreen(statusFilter: 'Joining & Onboarding'))),
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Recruitment Process Dashboard',
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryText, AppColors.error],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.work_outline, color: Colors.white, size: 36),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Recruitment Process',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'serif',
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Manage end-to-end hiring workflow',
                            style: TextStyle(fontSize: 13, color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              // Section label
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Recruitment Stages',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    fontFamily: 'serif',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: cards.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.9,
                ),
                itemBuilder: (context, index) => _buildStageCard(cards[index]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStageCard(_StageCard card) {
    return GestureDetector(
      onTap: card.onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.grey[300]!, blurRadius: 8, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: card.bgColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(card.icon, color: card.iconColor, size: 26),
            ),
            const SizedBox(height: 10),
            Text(
              card.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                height: 1.3,
                fontFamily: 'serif',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STAGE CARD MODEL
// ─────────────────────────────────────────────────────────────────────────────

class _StageCard {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final VoidCallback? onTap;

  const _StageCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    this.onTap,
  });
}


// ─────────────────────────────────────────────────────────────────────────────
// APPLICANT CARD WIDGET
// ─────────────────────────────────────────────────────────────────────────────

class _ApplicantCard extends StatelessWidget {
  final Applicant applicant;
  final ValueChanged<String> onStatusChanged;
  final VoidCallback onView;
  final VoidCallback onDelete;

  const _ApplicantCard({
    required this.applicant,
    required this.onStatusChanged,
    required this.onView,
    required this.onDelete,
  });

  Color _statusColor(String status) {
    switch (status) {
      case 'Screening & Shortlisting':   return const Color(0xFF8B5CF6);
      case 'Interview Process':          return const Color(0xFF0EA5E9);
      case 'Selection Decision':         return const Color(0xFF10B981);
      case 'Offer Letter & Negotiation': return const Color(0xFFF59E0B);
      case 'Background Verification':    return const Color(0xFFEF4444);
      case 'Joining & Onboarding':       return const Color(0xFF14B8A6);
      default:                           return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(applicant.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.grey[300]!, blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          // ── Coloured top strip + avatar + name ──────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: color.withValues(alpha: 0.18),
                  child: Text(
                    applicant.name.isNotEmpty ? applicant.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
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
                        applicant.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          fontFamily: 'serif',
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        applicant.jobTitle,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                // ── Status dropdown inline ──────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: applicant.status,
                      isDense: true,
                      icon: Icon(Icons.keyboard_arrow_down, color: color, size: 16),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                      items: kRecruitmentStatuses
                          .map((s) => DropdownMenuItem(
                                value: s,
                                child: Text(
                                  s,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _statusColor(s),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null && v != applicant.status) {
                          onStatusChanged(v);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          // ── Details ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Column(
              children: [
                _infoRow(Icons.business, 'Department', applicant.department),
                _infoRow(Icons.email_outlined, 'Email', applicant.email),
                _infoRow(Icons.phone_outlined, 'Mobile', applicant.mobile),
                _infoRow(Icons.location_on_outlined, 'Location', applicant.location),
                // Resume row
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      Icon(Icons.attach_file, size: 15, color: Colors.grey[500]),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 80,
                        child: Text('Resume',
                            style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                      ),
                      if (applicant.resumeUrl != null)
                        GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Opening ${applicant.resumeUrl}')),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.4)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.visibility, size: 13, color: Color(0xFF3B82F6)),
                                SizedBox(width: 4),
                                Text('View',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF3B82F6),
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        )
                      else
                        Text('Not uploaded',
                            style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 18, indent: 14, endIndent: 14),
          // ── Action buttons ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onView,
                    icon: const Icon(Icons.visibility_outlined, size: 16),
                    label: const Text('View', style: TextStyle(fontSize: 13, fontFamily: 'serif')),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF3B82F6),
                      side: const BorderSide(color: Color(0xFF3B82F6)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('Delete', style: TextStyle(fontSize: 13, fontFamily: 'serif')),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red[600],
                      side: BorderSide(color: Colors.red[400]!),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: Colors.grey[500]),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(label,
                style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}





// ─────────────────────────────────────────────────────────────────────────────
// SHARED STAGE-FILTERED SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class _StageFilteredScreen extends StatefulWidget {
  final String title;
  final String filterStatus;
  final Color accentColor;
  final IconData icon;

  const _StageFilteredScreen({
    required this.title,
    required this.filterStatus,
    required this.accentColor,
    required this.icon,
  });

  @override
  State<_StageFilteredScreen> createState() => _StageFilteredScreenState();
}

class _StageFilteredScreenState extends State<_StageFilteredScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Each stage screen has its own local list pre-filtered to that stage
  late final List<Applicant> _applicants;

  @override
  void initState() {
    super.initState();
    // Seed with sample data matching this stage and sort by date descending
    final allApplicants = _sampleData()
        .where((a) => a.status == widget.filterStatus)
        .toList();
    
    // Sort by date in descending order (latest first)
    allApplicants.sort((a, b) {
      if (a.createdAt == null && b.createdAt == null) return 0;
      if (a.createdAt == null) return 1;
      if (b.createdAt == null) return -1;
      return b.createdAt!.compareTo(a.createdAt!);
    });
    
    _applicants = allApplicants;
  }

  List<Applicant> _sampleData() => [
        Applicant(id: 's1', name: 'Rahul Sharma', jobTitle: 'Flutter Developer', department: 'Engineering', email: 'rahul.sharma@email.com', mobile: '+91 98765 43210', location: 'Mumbai, Maharashtra', resumeUrl: 'resume_rahul.pdf', status: 'Screening & Shortlisting', createdAt: DateTime.now().subtract(const Duration(days: 1))),
        Applicant(id: 's2', name: 'Priya Nair', jobTitle: 'UI/UX Designer', department: 'Design', email: 'priya.nair@email.com', mobile: '+91 91234 56789', location: 'Bangalore, Karnataka', resumeUrl: null, status: 'Interview Process', createdAt: DateTime.now().subtract(const Duration(days: 2))),
        Applicant(id: 's3', name: 'Amit Verma', jobTitle: 'Project Manager', department: 'Operations', email: 'amit.verma@email.com', mobile: '+91 87654 32109', location: 'Delhi, NCR', resumeUrl: 'resume_amit.pdf', status: 'Selection Decision', createdAt: DateTime.now().subtract(const Duration(days: 3))),
        Applicant(id: 's4', name: 'Sneha Patel', jobTitle: 'HR Executive', department: 'Human Resources', email: 'sneha.patel@email.com', mobile: '+91 99887 76655', location: 'Ahmedabad, Gujarat', resumeUrl: null, status: 'Offer Letter & Negotiation', createdAt: DateTime.now().subtract(const Duration(days: 4))),
        Applicant(id: 's5', name: 'Karan Mehta', jobTitle: 'Backend Developer', department: 'Engineering', email: 'karan.mehta@email.com', mobile: '+91 88776 65544', location: 'Pune, Maharashtra', resumeUrl: 'resume_karan.pdf', status: 'Background Verification', createdAt: DateTime.now().subtract(const Duration(days: 5))),
        Applicant(id: 's6', name: 'Divya Rao', jobTitle: 'Marketing Executive', department: 'Marketing', email: 'divya.rao@email.com', mobile: '+91 77665 54433', location: 'Chennai, Tamil Nadu', resumeUrl: null, status: 'Joining & Onboarding', createdAt: DateTime.now().subtract(const Duration(days: 6))),
      ];

  List<Applicant> get _filtered {
    if (_searchQuery.isEmpty) return _applicants;
    final q = _searchQuery.toLowerCase();
    return _applicants.where((a) =>
        a.name.toLowerCase().contains(q) ||
        a.jobTitle.toLowerCase().contains(q) ||
        a.department.toLowerCase().contains(q) ||
        a.email.toLowerCase().contains(q) ||
        a.location.toLowerCase().contains(q)).toList();
  }

  Future<void> _updateApplicantStatus(Applicant applicant, String newStatus) async {
    try {
      final response = await http.put(
        Uri.parse(AppConstants.UPDATE_JOB_APPLICATION_API),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'application_id': applicant.id,
          'status': newStatus,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'true' || data['status'] == true) {
          setState(() {
            applicant.status = newStatus;
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

  Future<void> _deleteApplicant(Applicant applicant) async {
    try {
      final response = await http.delete(
        Uri.parse(AppConstants.DELETE_JOB_APPLICATION_API),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'application_id': applicant.id,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'true' || data['status'] == true) {
          setState(() {
            _applicants.removeWhere((x) => x.id == applicant.id);
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final list = _filtered;
    final accent = widget.accentColor;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontFamily: 'serif',
            fontSize: 16,
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
            // ── Header banner ─────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.08),
                border: Border(bottom: BorderSide(color: accent.withValues(alpha: 0.2))),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(widget.icon, color: accent, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.filterStatus,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: accent,
                        fontFamily: 'serif',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // ── Search + Add ──────────────────────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (v) => setState(() => _searchQuery = v),
                        decoration: InputDecoration(
                          hintText: 'Search by name, role, location…',
                          hintStyle: TextStyle(fontSize: 13, color: Colors.grey[500]),
                          prefixIcon: Icon(Icons.search, color: Colors.grey[500], size: 20),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear, size: 18, color: Colors.grey[500]),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () => _showAddDialog(context),
                    icon: const Icon(Icons.add, size: 18, color: Colors.white),
                    label: const Text('Add',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'serif', fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryText,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ),
            // ── Count chip ────────────────────────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.only(left: 16, bottom: 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${list.length} Applicant${list.length == 1 ? '' : 's'}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: accent,
                      fontFamily: 'serif',
                    ),
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            // ── List ─────────────────────────────────────────────────────
            Expanded(
              child: list.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 12),
                          Text(
                            'No applicants in this stage',
                            style: TextStyle(color: Colors.grey[500], fontSize: 15),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tap Add to add one',
                            style: TextStyle(color: Colors.grey[400], fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
                      itemCount: list.length,
                      itemBuilder: (context, index) => _ApplicantCard(
                        applicant: list[index],
                        onStatusChanged: (newStatus) => _updateApplicantStatus(list[index], newStatus),
                        onView: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RecruitmentDetailsScreen(applicationId: list[index].id),
                            ),
                          );
                        },
                        onDelete: () => _confirmDelete(context, list[index]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Dialogs ───────────────────────────────────────────────────────────────

  void _showAddDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final jobCtrl = TextEditingController();
    final deptCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final mobileCtrl = TextEditingController();
    final locationCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: widget.accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.person_add, color: widget.accentColor, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('Add Application',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'serif')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(nameCtrl, 'Full Name', Icons.person),
              const SizedBox(height: 10),
              _field(jobCtrl, 'Job Title', Icons.work),
              const SizedBox(height: 10),
              _field(deptCtrl, 'Department / Role', Icons.business),
              const SizedBox(height: 10),
              _field(emailCtrl, 'Email', Icons.email, keyboard: TextInputType.emailAddress),
              const SizedBox(height: 10),
              _field(mobileCtrl, 'Mobile No.', Icons.phone, keyboard: TextInputType.phone),
              const SizedBox(height: 10),
              _field(locationCtrl, 'Location', Icons.location_on),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryText,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty) return;
              setState(() {
                final newApplicant = Applicant(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameCtrl.text.trim(),
                  jobTitle: jobCtrl.text.trim(),
                  department: deptCtrl.text.trim(),
                  email: emailCtrl.text.trim(),
                  mobile: mobileCtrl.text.trim(),
                  location: locationCtrl.text.trim(),
                  resumeUrl: null,
                  status: widget.filterStatus,
                  createdAt: DateTime.now(),
                );
                _applicants.insert(0, newApplicant); // Insert at top for latest first
              });
              Navigator.pop(ctx);
            },
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showViewDialog(BuildContext context, Applicant a) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: widget.accentColor.withValues(alpha: 0.15),
              child: Text(
                a.name.isNotEmpty ? a.name[0].toUpperCase() : '?',
                style: TextStyle(color: widget.accentColor, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(a.name,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'serif')),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _vRow(Icons.work, 'Job Title', a.jobTitle),
            _vRow(Icons.business, 'Department', a.department),
            _vRow(Icons.email, 'Email', a.email),
            _vRow(Icons.phone, 'Mobile', a.mobile),
            _vRow(Icons.location_on, 'Location', a.location),
            _vRow(Icons.flag, 'Status', a.status),
            if (a.resumeUrl != null) _vRow(Icons.attach_file, 'Resume', a.resumeUrl!),
          ],
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

  void _confirmDelete(BuildContext context, Applicant a) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Application', style: TextStyle(fontFamily: 'serif')),
        content: Text('Are you sure you want to delete "${a.name}" application? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(context);
              _deleteApplicant(a);
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

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {TextInputType keyboard = TextInputType.text}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }

  Widget _vRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: widget.accentColor),
          const SizedBox(width: 8),
          SizedBox(width: 80, child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
