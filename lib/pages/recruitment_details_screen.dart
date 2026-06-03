import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';

class RecruitmentDetailsData {
  final String applicationId;
  final String firstName;
  final String middleName;
  final String lastName;
  final String gender;
  final String status;
  final String email;
  final String mobilePhone;
  final String experienceYears;
  final String experienceMonths;
  final String currentSalary;
  final String expectedSalary;
  final String availableToJoinDays;
  final String currentLocation;
  final String currentCompany;
  final String linkedinUrl;
  final String? resumeFile;
  final String jobRole;
  final String companyName;
  final String jobTitle;
  final String currentlyWorking;
  final String dateOfJoining;
  final String dateOfRelieving;
  final String experienceLocation;
  final String createdAt;

  RecruitmentDetailsData({
    required this.applicationId,
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.gender,
    required this.status,
    required this.email,
    required this.mobilePhone,
    required this.experienceYears,
    required this.experienceMonths,
    required this.currentSalary,
    required this.expectedSalary,
    required this.availableToJoinDays,
    required this.currentLocation,
    required this.currentCompany,
    required this.linkedinUrl,
    this.resumeFile,
    required this.jobRole,
    required this.companyName,
    required this.jobTitle,
    required this.currentlyWorking,
    required this.dateOfJoining,
    required this.dateOfRelieving,
    required this.experienceLocation,
    required this.createdAt,
  });

  String get fullName => '${firstName.trim()} ${middleName.trim()} ${lastName.trim()}'.trim().replaceAll(RegExp(r'\s+'), ' ');

  factory RecruitmentDetailsData.fromJson(Map<String, dynamic> json) {
    return RecruitmentDetailsData(
      applicationId: json['application_id']?.toString() ?? '',
      firstName: json['first_name']?.toString() ?? '',
      middleName: json['middle_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      gender: json['gender']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      mobilePhone: json['mobile_phone']?.toString() ?? '',
      experienceYears: json['experience_years']?.toString() ?? '',
      experienceMonths: json['experience_months']?.toString() ?? '',
      currentSalary: json['current_salary']?.toString() ?? '',
      expectedSalary: json['expected_salary']?.toString() ?? '',
      availableToJoinDays: json['available_to_join_days']?.toString() ?? '',
      currentLocation: json['current_location']?.toString() ?? '',
      currentCompany: json['current_company']?.toString() ?? '',
      linkedinUrl: json['linkedin_url']?.toString() ?? '',
      resumeFile: json['resume_file']?.toString(),
      jobRole: json['job_role']?.toString() ?? '',
      companyName: json['company_name']?.toString() ?? '',
      jobTitle: json['job_title']?.toString() ?? '',
      currentlyWorking: json['currently_working']?.toString() ?? '',
      dateOfJoining: json['date_of_joining']?.toString() ?? '',
      dateOfRelieving: json['date_of_relieving']?.toString() ?? '',
      experienceLocation: json['experience_location']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}

class RecruitmentDetailsScreen extends StatefulWidget {
  final String applicationId;

  const RecruitmentDetailsScreen({
    super.key,
    required this.applicationId,
  });

  @override
  State<RecruitmentDetailsScreen> createState() => _RecruitmentDetailsScreenState();
}

class _RecruitmentDetailsScreenState extends State<RecruitmentDetailsScreen> {
  RecruitmentDetailsData? _recruitmentData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchRecruitmentDetails();
  }

  Future<void> _fetchRecruitmentDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.post(
        Uri.parse(AppConstants.FETCH_JOB_APPLICATION_API),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'application_id': widget.applicationId,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'true' || data['status'] == true) {
          setState(() {
            _recruitmentData = RecruitmentDetailsData.fromJson(data['data']);
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = 'Failed to load recruitment details';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'HTTP Error: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
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
          "Recruitment Details",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontFamily: 'serif',
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 40,
        titleSpacing: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryText))
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(_errorMessage!, style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchRecruitmentDetails,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderSection(),
                      const SizedBox(height: 24),
                      _buildPersonalInfoSection(),
                      const SizedBox(height: 24),
                      _buildJobInfoSection(),
                      const SizedBox(height: 24),
                      _buildExperienceSection(),
                      const SizedBox(height: 24),
                      _buildSalarySection(),
                      const SizedBox(height: 24),
                      _buildAdditionalInfoSection(),
                      const SizedBox(height: 50),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHeaderSection() {
    if (_recruitmentData == null) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _recruitmentData!.fullName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      fontFamily: 'serif',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Applied for ${_recruitmentData!.jobTitle} • ID: ${_recruitmentData!.applicationId}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontFamily: 'serif',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Applied on ${_formatDate(_recruitmentData!.createdAt)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                      fontFamily: 'serif',
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusColor(_recruitmentData!.status).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _getStatusColor(_recruitmentData!.status).withValues(alpha: 0.3)),
              ),
              child: Text(
                _recruitmentData!.status,
                style: TextStyle(
                  color: _getStatusColor(_recruitmentData!.status),
                  fontSize: 11,
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

  Widget _buildPersonalInfoSection() {
    if (_recruitmentData == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Personal Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontFamily: 'serif',
          ),
        ),
        const SizedBox(height: 16),
        _buildInfoRow('Email', _recruitmentData!.email.trim()),
        _buildInfoRow('Mobile', _recruitmentData!.mobilePhone.trim()),

        _buildInfoRow('Gender', _recruitmentData!.gender.isEmpty ? 'Not specified' : _recruitmentData!.gender),

        _buildInfoRow('Location', _recruitmentData!.currentLocation.trim()),
        if (_recruitmentData!.linkedinUrl.trim().isNotEmpty) ...[

          _buildInfoRow('LinkedIn', _recruitmentData!.linkedinUrl.trim()),
        ],
      ],
    );
  }

  Widget _buildJobInfoSection() {
    if (_recruitmentData == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Job Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontFamily: 'serif',
          ),
        ),
        const SizedBox(height: 16),
        _buildInfoRow('Position', _recruitmentData!.jobTitle.trim()),

        _buildInfoRow('Job Role', _recruitmentData!.jobRole.trim()),

        _buildInfoRow('Company', _recruitmentData!.companyName.trim()),

        _buildInfoRow('Available to Join', '${_recruitmentData!.availableToJoinDays} days'),
        if (_recruitmentData!.resumeFile != null && _recruitmentData!.resumeFile!.isNotEmpty) ...[

        ],
      ],
    );
  }

  Widget _buildExperienceSection() {
    if (_recruitmentData == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Work Experience',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontFamily: 'serif',
          ),
        ),
        const SizedBox(height: 16),
        _buildInfoRow('Total Experience', '${_recruitmentData!.experienceYears} years ${_recruitmentData!.experienceMonths} months'),

        _buildInfoRow('Current Company', _recruitmentData!.currentCompany.trim()),

        _buildInfoRow('Currently Working', _recruitmentData!.currentlyWorking == '1' ? 'Yes' : 'No'),
        if (_recruitmentData!.dateOfJoining.isNotEmpty) ...[

          _buildInfoRow('Date of Joining', _formatDate(_recruitmentData!.dateOfJoining)),
        ],
        if (_recruitmentData!.dateOfRelieving.isNotEmpty && _recruitmentData!.currentlyWorking != '1') ...[

          _buildInfoRow('Date of Relieving', _formatDate(_recruitmentData!.dateOfRelieving)),
        ],
        if (_recruitmentData!.experienceLocation.trim().isNotEmpty) ...[

          _buildInfoRow('Experience Location', _recruitmentData!.experienceLocation.trim()),
        ],
      ],
    );
  }

  Widget _buildSalarySection() {
    if (_recruitmentData == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Salary Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontFamily: 'serif',
          ),
        ),
        const SizedBox(height: 16),
        _buildInfoRow('Current Salary', '₹${_formatSalary(_recruitmentData!.currentSalary)}/month', isAmount: true),
       
        _buildInfoRow('Expected Salary', '₹${_formatSalary(_recruitmentData!.expectedSalary)}/month', isAmount: true),
      ],
    );
  }

  Widget _buildAdditionalInfoSection() {
    if (_recruitmentData == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Application Timeline',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              fontFamily: 'serif',
            ),
          ),
          const SizedBox(height: 16),
          _buildTimelineItem(
            icon: Icons.person_add,
            iconColor: Colors.blue,
            title: 'Application Submitted',
            date: _formatDate(_recruitmentData!.createdAt),
            description: 'Candidate applied for ${_recruitmentData!.jobTitle} position',
          ),
          const SizedBox(height: 12),
          _buildTimelineItem(
            icon: Icons.assignment_turned_in,
            iconColor: _getStatusColor(_recruitmentData!.status),
            title: 'Current Status',
            date: 'In Progress',
            description: _recruitmentData!.status,
          ),
          if (_recruitmentData!.resumeFile != null && _recruitmentData!.resumeFile!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildResumeSection(),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isAmount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 16, color: Colors.grey[600], fontFamily: 'serif')),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value.isEmpty ? 'Not provided' : value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isAmount ? FontWeight.bold : FontWeight.w500,
              color: Colors.black,
              fontFamily: 'serif',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResumeRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Resume', style: TextStyle(fontSize: 16, color: Colors.grey[600], fontFamily: 'serif')),
        GestureDetector(
          onTap: () => _openResumeInBrowser(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryText.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primaryText.withValues(alpha: 0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.open_in_browser, size: 16, color: AppColors.primaryText),
                SizedBox(width: 4),
                Text(
                  'View Resume',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.primaryText,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'serif',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String date,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                    fontFamily: 'serif',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontFamily: 'serif',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
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

  String _formatSalary(String salary) {
    if (salary.isEmpty) return '0';
    try {
      final amount = double.parse(salary);
      if (amount >= 100000) {
        return '${(amount / 100000).toStringAsFixed(1)}L';
      } else if (amount >= 1000) {
        return '${(amount / 1000).toStringAsFixed(1)}K';
      }
      return amount.toStringAsFixed(0);
    } catch (e) {
      return salary;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Screening & Shortlisting': return const Color(0xFF8B5CF6);
      case 'Interview Process': return const Color(0xFF0EA5E9);
      case 'Selection Process': return const Color(0xFF10B981);
      case 'Offer Letter & Negotiation': return const Color(0xFFF59E0B);
      case 'Background Verification': return const Color(0xFFEF4444);
      case 'Joining & Onboarding': return const Color(0xFF14B8A6);
      default: return Colors.grey;
    }
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return 'Not specified';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  Future<void> _openResumeInBrowser() async {
    if (_recruitmentData?.resumeFile == null || _recruitmentData!.resumeFile!.isEmpty) {
      _showMessage('Resume file not available', isError: true);
      return;
    }

    try {
      String resumeUrl = _recruitmentData!.resumeFile!;
      
      // If the URL doesn't start with http/https, assume it's a relative path
      if (!resumeUrl.startsWith('http://') && !resumeUrl.startsWith('https://')) {
        // Construct full URL - adjust base URL according to your server
        resumeUrl = '${AppConstants.BASE_URL}/uploads/resumes/$resumeUrl';
      }

      // Copy URL to clipboard and show instructions
      await Clipboard.setData(ClipboardData(text: resumeUrl));
      
      _showResumeDialog(resumeUrl);
      
    } catch (e) {
      _showMessage('Error preparing resume URL: $e', isError: true);
    }
  }

  void _showResumeDialog(String url) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.open_in_browser, color: AppColors.primaryText, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Open Resume',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'serif',
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Resume URL has been copied to clipboard:',
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'serif',
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Text(
                  url,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                    fontFamily: 'monospace',
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Paste this URL in your browser to view the resume.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                  fontFamily: 'serif',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                // Copy again in case user wants to copy again
                await Clipboard.setData(ClipboardData(text: url));
                Navigator.of(context).pop();
                _showMessage('URL copied to clipboard!');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryText,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.copy, size: 18),
              label: const Text(
                'Copy URL',
                style: TextStyle(fontFamily: 'serif'),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'serif')),
        backgroundColor: isError ? Colors.red : AppColors.primaryText,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildResumeSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryText.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.description, color: AppColors.primaryText, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Resume Document',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontFamily: 'serif',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'View candidate resume document',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontFamily: 'serif',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () => _openResumeInBrowser(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryText,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.open_in_browser, size: 18),
            label: const Text(
              'View Resume',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFamily: 'serif',
              ),
            ),
          ),
        ],
      ),
    );
  }
}