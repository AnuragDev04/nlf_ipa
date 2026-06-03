import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  final _fullNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _dobController = TextEditingController();
  final _locationController = TextEditingController();
  final _bloodGroupController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  final _designationController = TextEditingController();
  final _experienceController = TextEditingController();
  final _joiningDateController = TextEditingController();
  final _salaryController = TextEditingController();

  final List<PlatformFile> _selectedFiles = <PlatformFile>[];

  String? _selectedGender;
  String? _selectedStatus;
  String? _selectedRollId;
  String? _selectedWorkType;

  // Dropdown error states
  String? _genderError;
  String? _roleError;
  String? _workTypeError;

  final _genderOptions = ['Male', 'Female', 'Other'];
  final _statusOptions = ['Active', 'Inactive'];
  final _workTypeOptions = ['Office Work', 'On Site Work'];

  List<Map<String, String>> _roleList = [];
  bool _isLoadingRoles = false;

  @override
  void initState() {
    super.initState();
    _fetchRoles();
  }

  Future<void> _fetchRoles() async {
    setState(() => _isLoadingRoles = true);
    try {
      final response = await http.get(
        Uri.parse(AppConstants.ROLE_LIST_API),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'true' &&
            (data['success'] == '1' || data['success'] == 1)) {
          final List<dynamic> roleData = data['data'];
          setState(() {
            _roleList = roleData
                .map(
                  (item) => {
                    'roll_id': item['roll_id']?.toString() ?? '',
                    'roll': item['roll']?.toString() ?? '',
                  },
                )
                .toList();
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching roles: $e');
    } finally {
      setState(() => _isLoadingRoles = false);
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    _locationController.dispose();
    _bloodGroupController.dispose();
    _emergencyContactController.dispose();
    _designationController.dispose();
    _experienceController.dispose();
    _joiningDateController.dispose();
    _salaryController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(
    BuildContext context,
    TextEditingController controller,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        controller.text =
            "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      });
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
    if (_selectedRollId == null) {
      _roleError = 'Required';
      valid = false;
    } else {
      _roleError = null;
    }
    if (_selectedWorkType == null) {
      _workTypeError = 'Required';
      valid = false;
    } else {
      _workTypeError = null;
    }
    return valid;
  }

  String _formatDateForApi(String displayDate) {
    // converts dd/mm/yyyy -> yyyy-mm-dd
    if (displayDate.isEmpty) return '';
    final parts = displayDate.split('/');
    if (parts.length != 3) return displayDate;
    return '${parts[2]}-${parts[1].padLeft(2, '0')}-${parts[0].padLeft(2, '0')}';
  }

  Future<void> _submitForm() async {
    final dropdownsValid = _validateDropdowns();
    setState(() {});
    if (!_formKey.currentState!.validate() || !dropdownsValid) return;

    setState(() => _isSubmitting = true);
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(AppConstants.ADD_EMPLOYEE_API),
      );

      // Text fields
      request.fields['name'] = _fullNameController.text.trim();
      request.fields['gender'] = _selectedGender ?? '';
      request.fields['email'] = _emailController.text.trim();
      request.fields['mob'] = _mobileController.text.trim();
      request.fields['location'] = _locationController.text.trim();
      request.fields['status'] = _selectedStatus ?? '';
      request.fields['dob'] = _formatDateForApi(_dobController.text.trim());
      request.fields['designation'] = _designationController.text.trim();
      request.fields['experience'] = _experienceController.text.trim();
      request.fields['joining_date'] = _formatDateForApi(
        _joiningDateController.text.trim(),
      );
      request.fields['role'] = _selectedRollId ?? '';
      debugPrint('Sending role (roll_id): $_selectedRollId');
      request.fields['salary'] = _salaryController.text.trim();
      request.fields['blood_group'] = _bloodGroupController.text.trim();
      request.fields['emergency_contact_no'] = _emergencyContactController.text
          .trim();
      request.fields['type'] = _selectedWorkType ?? '';

      // Document files — doc[]
      for (final file in _selectedFiles) {
        if (file.bytes != null) {
          request.files.add(
            http.MultipartFile.fromBytes(
              'doc[]',
              file.bytes!,
              filename: file.name,
            ),
          );
        } else if (file.path != null) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'doc[]',
              file.path!,
              filename: file.name,
            ),
          );
        }
      }

      debugPrint('ADD_EMPLOYEE fields: ${request.fields}');
      debugPrint(
        'ADD_EMPLOYEE files: ${request.files.map((f) => f.filename).toList()}',
      );

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      debugPrint(
        'ADD_EMPLOYEE response [${response.statusCode}]: $responseData',
      );

      if (responseData.isEmpty) {
        // HTTP 500 empty body — server error
        throw Exception('Server error (HTTP ${response.statusCode})');
      }

      Map<String, dynamic> data;
      try {
        data = json.decode(responseData);
      } catch (_) {
        throw Exception('Invalid server response: $responseData');
      }

      final isSuccess =
          response.statusCode == 200 &&
          (data['status'] == 'true' ||
              data['status'] == true ||
              data['success'] == '1' ||
              data['success'] == 1);

      if (isSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                data['message']?.toString() ?? 'Employee added successfully!',
                style: const TextStyle(fontFamily: 'serif'),
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        throw Exception(
          data['message']?.toString() ?? 'Failed to add employee',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: $e',
              style: const TextStyle(fontFamily: 'serif'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _cancel() => Navigator.pop(context);

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
          'New Employee',
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
                      _buildSectionTitle('Employee Details'),
                      const SizedBox(height: 16),

                      // Full Name *
                      _buildTextField(
                        'Full Name',
                        _fullNameController,
                        Icons.person_outline,
                        (v) => v!.isEmpty ? 'Required' : null,
                        isRequired: true,
                      ),

                      // Mobile No. *
                      _buildTextField(
                        'Mobile No.',
                        _mobileController,
                        Icons.phone_outlined,
                        (v) {
                          if (v!.isEmpty) return 'Required';
                          if (!RegExp(r'^\d{10}$').hasMatch(v)) {
                            return '10-digit number required';
                          }
                          return null;
                        },
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        isRequired: true,
                      ),

                      // Email
                      _buildTextField(
                        'Email',
                        _emailController,
                        Icons.email_outlined,
                        (v) {
                          if (v != null &&
                              v.isNotEmpty &&
                              !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                        keyboardType: TextInputType.emailAddress,
                      ),

                      // Date of Birth *
                      _buildDateField(
                        'Date of Birth',
                        _dobController,
                        () => _selectDate(context, _dobController),
                        isRequired: true,
                      ),

                      // Gender *
                      _buildDropdownField(
                        label: 'Gender',
                        isLoading: false,
                        items: _genderOptions,
                        displayNames: _genderOptions,
                        value: _selectedGender,
                        onChanged: (v) => setState(() {
                          _selectedGender = v;
                          _genderError = null;
                        }),
                        isRequired: true,
                        errorText: _genderError,
                      ),

                      // Location *
                      _buildTextField(
                        'Location',
                        _locationController,
                        Icons.location_on_outlined,
                        (v) => v!.isEmpty ? 'Required' : null,
                        isRequired: true,
                      ),

                      // Blood Group
                      _buildTextField(
                        'Blood Group',
                        _bloodGroupController,
                        Icons.bloodtype_outlined,
                        (v) => null,
                      ),

                      // Emergency Contact Number
                      _buildTextField(
                        'Emergency Contact Number',
                        _emergencyContactController,
                        Icons.contact_phone_outlined,
                        (v) => null,
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),

                      // Designation *
                      _buildTextField(
                        'Designation',
                        _designationController,
                        Icons.work_outline,
                        (v) => v!.isEmpty ? 'Required' : null,
                        isRequired: true,
                      ),

                      // Experience
                      _buildTextField(
                        'Experience',
                        _experienceController,
                        Icons.work_history_outlined,
                        (v) => null,
                      ),

                      // Joining Date *
                      _buildDateField(
                        'Joining Date',
                        _joiningDateController,
                        () => _selectDate(context, _joiningDateController),
                        isRequired: true,
                      ),

                      // Status
                      _buildDropdownField(
                        label: 'Status',
                        isLoading: false,
                        items: _statusOptions,
                        displayNames: _statusOptions,
                        value: _selectedStatus,
                        onChanged: (v) => setState(() => _selectedStatus = v),
                      ),

                      // Role *
                      _buildDropdownField(
                        label: 'Role',
                        isLoading: _isLoadingRoles,
                        items: _roleList.map((r) => r['roll_id']!).toList(),
                        displayNames: _roleList.map((r) => r['roll']!).toList(),
                        value: _selectedRollId,
                        onChanged: (v) {
                          // v is roll_id — find matching roll_id from list to confirm
                          final matched = _roleList.firstWhere(
                            (r) => r['roll_id'] == v,
                            orElse: () => {},
                          );
                          setState(() {
                            _selectedRollId = matched['roll_id'];
                            _roleError = null;
                          });
                        },
                        isRequired: true,
                        errorText: _roleError,
                      ),

                      // Documents
                      _buildDocumentUpload(),

                      // Salary
                      _buildTextField(
                        'Salary',
                        _salaryController,
                        Icons.currency_rupee_outlined,
                        (v) => null,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),

                      // Employee Work Type *
                      _buildDropdownField(
                        label: 'Employee Work Type',
                        isLoading: false,
                        items: _workTypeOptions,
                        displayNames: _workTypeOptions,
                        value: _selectedWorkType,
                        onChanged: (v) => setState(() {
                          _selectedWorkType = v;
                          _workTypeError = null;
                        }),
                        isRequired: true,
                        errorText: _workTypeError,
                      ),
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
                        onPressed: _isSubmitting ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryText,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Add Employee',
                                style: TextStyle(
                                  fontFamily: 'serif',
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSubmitting ? null : _cancel,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.grey[600],
                          side: BorderSide(
                            color: Colors.grey[600]!,
                            width: 2.0,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(fontFamily: 'serif', fontSize: 16),
                        ),
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
        fontFamily: 'serif',
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon,
    String? Function(String?) validator, {
    TextInputType? keyboardType,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'serif',
              ),
            ),
            if (isRequired)
              const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Text(
                  '*',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLength: maxLength,
          inputFormatters: inputFormatters,
          validator: validator,
          style: const TextStyle(color: Colors.black, fontFamily: 'serif'),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(
              color: AppColors.greyText,
              fontFamily: 'serif',
            ),
            prefixIcon: Icon(icon, color: AppColors.greyText),
            hintText: 'Enter $label',
            hintStyle: TextStyle(
              color: AppColors.greyText,
              fontFamily: 'serif',
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.lightGrey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.secondaryText),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.lightGrey),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent, width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent, width: 2),
            ),
            counterText: '',
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildDateField(
    String label,
    TextEditingController controller,
    VoidCallback onTap, {
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'serif',
              ),
            ),
            if (isRequired)
              const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Text(
                  '*',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          readOnly: true,
          onTap: onTap,
          validator: (v) =>
              isRequired && (v == null || v.isEmpty) ? 'Required' : null,
          style: const TextStyle(color: Colors.black, fontFamily: 'serif'),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(
              color: AppColors.greyText,
              fontFamily: 'serif',
            ),
            prefixIcon: Icon(Icons.calendar_today, color: AppColors.greyText),
            hintText: 'dd/mm/yyyy',
            hintStyle: TextStyle(
              color: AppColors.greyText,
              fontFamily: 'serif',
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.lightGrey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.secondaryText),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.lightGrey),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent, width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required bool isLoading,
    required List<String> items,
    required List<String> displayNames,
    required String? value,
    required void Function(String?) onChanged,
    bool isRequired = false,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'serif',
              ),
            ),
            if (isRequired)
              const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Text(
                  '*',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: errorText != null
                  ? Colors.red
                  : isLoading
                  ? Colors.grey
                  : AppColors.lightGrey,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: isLoading
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Loading...',
                        style: TextStyle(
                          color: AppColors.greyText,
                          fontFamily: 'serif',
                        ),
                      ),
                    ],
                  ),
                )
              : DropdownButton<String>(
                  value: value != null && items.contains(value) ? value : null,
                  isExpanded: true,
                  underline: const SizedBox(),
                  dropdownColor: Colors.grey[200],
                  style: const TextStyle(
                    color: Colors.black,
                    fontFamily: 'serif',
                    fontSize: 16,
                  ),
                  hint: Text(
                    'Select $label',
                    style: TextStyle(
                      color: AppColors.greyText,
                      fontFamily: 'serif',
                    ),
                  ),
                  items: List.generate(
                    items.length,
                    (i) => DropdownMenuItem<String>(
                      value: items[i],
                      child: Text(
                        displayNames[i],
                        style: const TextStyle(
                          color: Colors.black,
                          fontFamily: 'serif',
                        ),
                      ),
                    ),
                  ),
                  onChanged: onChanged,
                ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              errorText,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 12,
                fontFamily: 'serif',
              ),
            ),
          ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildDocumentUpload() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Documents',
          style: TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            fontFamily: 'serif',
          ),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: _pickDocuments,
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
                Text(
                  'Upload Documents',
                  style: TextStyle(
                    color: AppColors.greyText,
                    fontFamily: 'serif',
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Upload AADHAR CARD and PAN (PDF, JPG, PNG)',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontFamily: 'serif',
          ),
        ),
        if (_selectedFiles.isNotEmpty)
          ..._selectedFiles.map(
            (file) => Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.lightGrey),
                ),
                child: Row(
                  children: [
                    Icon(
                      _fileIcon(file.extension),
                      color: AppColors.primaryText,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        file.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontFamily: 'serif',
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _selectedFiles.remove(file)),
                      child: const Icon(
                        Icons.close,
                        size: 18,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 10),
      ],
    );
  }

  Future<void> _pickDocuments() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result != null) {
      setState(() {
        final existing = _selectedFiles.map((f) => f.name).toSet();
        final newFiles = result.files.where((f) => !existing.contains(f.name));
        _selectedFiles.addAll(newFiles);
      });
    }
  }

  IconData _fileIcon(String? ext) {
    switch (ext?.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }
}
