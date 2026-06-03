import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';

class AddJobApplicationScreen extends StatefulWidget {
  const AddJobApplicationScreen({super.key});

  @override
  State<AddJobApplicationScreen> createState() => _AddJobApplicationScreenState();
}

class _AddJobApplicationScreenState extends State<AddJobApplicationScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  // Personal Info
  final _firstNameCtrl = TextEditingController();
  final _middleNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _expYearsCtrl = TextEditingController();
  final _expMonthsCtrl = TextEditingController();
  final _currentSalaryCtrl = TextEditingController();
  final _expectedSalaryCtrl = TextEditingController();
  final _joinDaysCtrl = TextEditingController();
  final _currentLocationCtrl = TextEditingController();
  final _expLocationCtrl = TextEditingController();

  // Job Details
  final _jobTitleCtrl = TextEditingController();
  final _jobRoleCtrl = TextEditingController();
  final _currentCompanyCtrl = TextEditingController();
  final _companyNameCtrl = TextEditingController();
  final _linkedinCtrl = TextEditingController();
  final _dateOfJoiningCtrl = TextEditingController();
  final _dateOfRelievingCtrl = TextEditingController();

  String? _selectedGender;
  String? _currentlyWorking;
  PlatformFile? _resumeFile;

  // Dropdown error states
  String? _genderError;

  final _genderOptions = ['Male', 'Female', 'Other'];
  final _workingOptions = ['Yes', 'No'];

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _middleNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _mobileCtrl.dispose();
    _expYearsCtrl.dispose();
    _expMonthsCtrl.dispose();
    _currentSalaryCtrl.dispose();
    _expectedSalaryCtrl.dispose();
    _joinDaysCtrl.dispose();
    _currentLocationCtrl.dispose();
    _expLocationCtrl.dispose();
    _jobTitleCtrl.dispose();
    _jobRoleCtrl.dispose();
    _currentCompanyCtrl.dispose();
    _companyNameCtrl.dispose();
    _linkedinCtrl.dispose();
    _dateOfJoiningCtrl.dispose();
    _dateOfRelievingCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectDate(TextEditingController ctrl) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      ctrl.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _pickResume() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _resumeFile = result.files.first);
    }
  }

  bool _validateDropdowns() {
    bool valid = true;
    if (_selectedGender == null) {
      _genderError = 'Required';
      valid = false;
    } else {
      _genderError = null;
    }
    return valid;
  }

  Future<void> _submit() async {
    final dropdownsValid = _validateDropdowns();
    setState(() {});
    if (!_formKey.currentState!.validate() || !dropdownsValid) return;

    setState(() => _isSubmitting = true);
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(AppConstants.ADD_JOB_APPLICATION_API),
      );

      request.fields['first_name'] = _firstNameCtrl.text.trim();
      request.fields['middle_name'] = _middleNameCtrl.text.trim();
      request.fields['last_name'] = _lastNameCtrl.text.trim();
      request.fields['gender'] = _selectedGender ?? '';
      request.fields['email'] = _emailCtrl.text.trim();
      request.fields['mobile_phone'] = _mobileCtrl.text.trim();
      request.fields['experience_years'] = _expYearsCtrl.text.trim();
      request.fields['experience_months'] = _expMonthsCtrl.text.trim();
      request.fields['current_salary'] = _currentSalaryCtrl.text.trim();
      request.fields['expected_salary'] = _expectedSalaryCtrl.text.trim();
      request.fields['available_to_join_days'] = _joinDaysCtrl.text.trim();
      request.fields['current_location'] = _currentLocationCtrl.text.trim();
      request.fields['experience_location'] = _expLocationCtrl.text.trim();
      request.fields['job_title'] = _jobTitleCtrl.text.trim();
      request.fields['job_role'] = _jobRoleCtrl.text.trim();
      request.fields['current_company'] = _currentCompanyCtrl.text.trim();
      request.fields['company_name'] = _companyNameCtrl.text.trim();
      request.fields['linkedin_url'] = _linkedinCtrl.text.trim();
      request.fields['currently_working'] = _currentlyWorking ?? 'No';
      request.fields['date_of_joining'] = _dateOfJoiningCtrl.text.trim();
      request.fields['date_of_relieving'] = _dateOfRelievingCtrl.text.trim();

      if (_resumeFile != null) {
        if (_resumeFile!.bytes != null) {
          request.files.add(http.MultipartFile.fromBytes(
            'resume_file',
            _resumeFile!.bytes!,
            filename: _resumeFile!.name,
          ));
        } else if (_resumeFile!.path != null) {
          request.files.add(await http.MultipartFile.fromPath(
            'resume_file',
            _resumeFile!.path!,
            filename: _resumeFile!.name,
          ));
        }
      }

      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      debugPrint('ADD_JOB_APPLICATION [${response.statusCode}]: $responseData');

      if (responseData.isEmpty) throw Exception('Empty response (HTTP ${response.statusCode})');

      Map<String, dynamic> result;
      try {
        result = json.decode(responseData);
      } catch (_) {
        throw Exception('Invalid response: $responseData');
      }

      final isSuccess = response.statusCode == 200 &&
          (result['status'] == 'true' ||
              result['status'] == true ||
              result['success'] == '1' ||
              result['success'] == 1);

      if (isSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
              result['message']?.toString() ?? 'Application submitted successfully!',
              style: const TextStyle(fontFamily: 'serif'),
            ),
            backgroundColor: Colors.green,
          ));
          Navigator.pop(context, true);
        }
      } else {
        throw Exception(result['message']?.toString() ?? 'Failed to submit application');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e', style: const TextStyle(fontFamily: 'serif')),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
          'Add Job Application',
          style: TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold, fontFamily: 'serif', fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 40,
        titleSpacing: 0,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Personal Information ──────────────────────────
                      _sectionTitle('Personal Information'),
                      const SizedBox(height: 16),

                      _field('First Name', _firstNameCtrl, Icons.person_outline,
                          isRequired: true, validator: (v) => v!.isEmpty ? 'Required' : null),
                      _field('Middle Name', _middleNameCtrl, Icons.person_outline),
                      _field('Last Name', _lastNameCtrl, Icons.person_outline,
                          isRequired: true, validator: (v) => v!.isEmpty ? 'Required' : null),

                      _dropdown(
                        label: 'Gender',
                        value: _selectedGender,
                        items: _genderOptions,
                        onChanged: (v) => setState(() { _selectedGender = v; _genderError = null; }),
                        isRequired: true,
                        errorText: _genderError,
                      ),

                      _field('Email', _emailCtrl, Icons.email_outlined,
                          isRequired: true,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Required';
                            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) return 'Enter valid email';
                            return null;
                          }),

                      _field('Mobile No.', _mobileCtrl, Icons.phone_outlined,
                          isRequired: true,
                          keyboardType: TextInputType.phone,
                          maxLength: 10,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Required';
                            if (!RegExp(r'^\d{10}$').hasMatch(v)) return '10-digit number required';
                            return null;
                          }),

                      const SizedBox(height: 8),
                      _sectionTitle('Experience'),
                      const SizedBox(height: 16),

                      _field('Experience (Years)', _expYearsCtrl, Icons.work_history_outlined,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
                      _field('Experience (Months)', _expMonthsCtrl, Icons.work_history_outlined,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
                      _field('Current Salary', _currentSalaryCtrl, Icons.currency_rupee_outlined,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
                      _field('Expected Salary', _expectedSalaryCtrl, Icons.currency_rupee_outlined,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
                      _field('Available to Join (Days)', _joinDaysCtrl, Icons.calendar_today_outlined,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
                      _field('Current Location', _currentLocationCtrl, Icons.location_on_outlined),
                      _field('Experience Location', _expLocationCtrl, Icons.location_on_outlined),

                      const SizedBox(height: 8),
                      _sectionTitle('Job Details'),
                      const SizedBox(height: 16),

                      _field('Job Title', _jobTitleCtrl, Icons.work_outline,
                          isRequired: true, validator: (v) => v!.isEmpty ? 'Required' : null),
                      _field('Job Role', _jobRoleCtrl, Icons.business_center_outlined),
                      _field('Current Company', _currentCompanyCtrl, Icons.business_outlined),
                      _field('Company Name (Applying To)', _companyNameCtrl, Icons.apartment_outlined),
                      _field('LinkedIn URL', _linkedinCtrl, Icons.link_outlined,
                          keyboardType: TextInputType.url),

                      _dropdown(
                        label: 'Currently Working?',
                        value: _currentlyWorking,
                        items: _workingOptions,
                        onChanged: (v) => setState(() => _currentlyWorking = v),
                      ),

                      _dateField('Date of Joining', _dateOfJoiningCtrl),
                      _dateField('Date of Relieving', _dateOfRelievingCtrl),

                      // Resume upload
                      _resumeUpload(),
                    ],
                  ),
                ),
              ),

              // Buttons
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryText,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Submit Application',
                                style: TextStyle(fontFamily: 'serif', fontSize: 16)),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.grey[600],
                          side: BorderSide(color: Colors.grey[600]!, width: 2.0),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Cancel',
                            style: TextStyle(fontFamily: 'serif', fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title,
        style: const TextStyle(
            fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87, fontFamily: 'serif'));
  }

  Widget _field(
    String label,
    TextEditingController ctrl,
    IconData icon, {
    bool isRequired = false,
    TextInputType? keyboardType,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label,
                style: const TextStyle(
                    color: Colors.black, fontSize: 14, fontWeight: FontWeight.w500, fontFamily: 'serif')),
            if (isRequired)
              const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Text('*', style: TextStyle(color: Colors.red, fontSize: 14, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: ctrl,
          keyboardType: keyboardType,
          maxLength: maxLength,
          inputFormatters: inputFormatters,
          validator: validator,
          style: const TextStyle(color: Colors.black, fontFamily: 'serif'),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: AppColors.greyText, fontFamily: 'serif'),
            prefixIcon: Icon(icon, color: AppColors.greyText),
            hintText: 'Enter $label',
            hintStyle: TextStyle(color: AppColors.greyText, fontFamily: 'serif'),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.lightGrey)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.secondaryText)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.lightGrey)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.redAccent, width: 2)),
            focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.redAccent, width: 2)),
            counterText: '',
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _dateField(String label, TextEditingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.black, fontSize: 14, fontWeight: FontWeight.w500, fontFamily: 'serif')),
        const SizedBox(height: 4),
        TextFormField(
          controller: ctrl,
          readOnly: true,
          onTap: () => _selectDate(ctrl),
          style: const TextStyle(color: Colors.black, fontFamily: 'serif'),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: AppColors.greyText, fontFamily: 'serif'),
            prefixIcon: Icon(Icons.calendar_today, color: AppColors.greyText),
            hintText: 'yyyy-mm-dd',
            hintStyle: TextStyle(color: AppColors.greyText, fontFamily: 'serif'),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.lightGrey)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.secondaryText)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.lightGrey)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _dropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    bool isRequired = false,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label,
                style: const TextStyle(
                    color: Colors.black, fontSize: 14, fontWeight: FontWeight.w500, fontFamily: 'serif')),
            if (isRequired)
              const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Text('*', style: TextStyle(color: Colors.red, fontSize: 14, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: errorText != null ? Colors.red : AppColors.lightGrey),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            underline: const SizedBox(),
            dropdownColor: Colors.grey[200],
            style: const TextStyle(color: Colors.black, fontFamily: 'serif', fontSize: 16),
            hint: Text('Select $label', style: TextStyle(color: AppColors.greyText, fontFamily: 'serif')),
            items: items.map((s) => DropdownMenuItem(
              value: s,
              child: Text(s, style: const TextStyle(color: Colors.black, fontFamily: 'serif')),
            )).toList(),
            onChanged: onChanged,
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(errorText,
                style: const TextStyle(color: Colors.red, fontSize: 12, fontFamily: 'serif')),
          ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _resumeUpload() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Resume (PDF / DOC)',
            style: TextStyle(
                color: Colors.black, fontSize: 14, fontWeight: FontWeight.w500, fontFamily: 'serif')),
        const SizedBox(height: 4),
        InkWell(
          onTap: _pickResume,
          child: Container(
            width: double.infinity,
            height: 55,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: AppColors.lightGrey),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.upload_file, color: AppColors.greyText),
                SizedBox(width: 8),
                Text('Upload Resume', style: TextStyle(color: AppColors.greyText, fontFamily: 'serif')),
              ],
            ),
          ),
        ),
        if (_resumeFile != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.lightGrey),
              ),
              child: Row(
                children: [
                  Icon(
                    _resumeFile!.extension?.toLowerCase() == 'pdf'
                        ? Icons.picture_as_pdf
                        : Icons.description_outlined,
                    color: AppColors.primaryText, size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_resumeFile!.name,
                        style: const TextStyle(fontSize: 13, fontFamily: 'serif', color: Colors.black87),
                        overflow: TextOverflow.ellipsis),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _resumeFile = null),
                    child: const Icon(Icons.close, size: 18, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 10),
      ],
    );
  }
}
