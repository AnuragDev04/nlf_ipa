import 'package:flutter/material.dart';
import 'package:nlf/utils/colors.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class AddAppointmentScreen extends StatefulWidget {
  const AddAppointmentScreen({super.key});

  @override
  State<AddAppointmentScreen> createState() => _AddAppointmentScreenState();
}

class _AddAppointmentScreenState extends State<AddAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  final _toController = TextEditingController();
  final _probationPeriodController = TextEditingController();
  final _payPackageController = TextEditingController();
  final _officeTimingController = TextEditingController();
  final _noticePeriodController = TextEditingController();

  DateTime? _appointmentDate;
  String? _appointmentDateError;

  @override
  void dispose() {
    _toController.dispose();
    _probationPeriodController.dispose();
    _payPackageController.dispose();
    _officeTimingController.dispose();
    _noticePeriodController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';

  String _displayDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _appointmentDate = picked;
        _appointmentDateError = null;
      });
    }
  }

  Future<void> _submit() async {
    bool valid = _formKey.currentState!.validate();
    if (_appointmentDate == null) {
      setState(() => _appointmentDateError = 'Required');
      valid = false;
    }
    if (!valid) return;

    setState(() => _isSubmitting = true);
    try {
      final response = await http.post(
        Uri.parse(AppConstants.ADD_APPOINTMENT_LETTER_API),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'to': _toController.text.trim(),
          'appointment_date': _formatDate(_appointmentDate!),
          'probation_period': _probationPeriodController.text.trim(),
          'pay_package': _payPackageController.text.trim(),
          'office_timing': _officeTimingController.text.trim(),
          'notice_period': _noticePeriodController.text.trim(),
          'appointment_approval': 'Pending',
        }),
      );

      if (!mounted) return;
      final data = json.decode(response.body);
      final success = data['status'] == 'true' || data['status'] == true;

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          data['message']?.toString() ??
              (success
                  ? 'Appointment letter generated!'
                  : 'Failed to generate'),
          style: const TextStyle(fontFamily: 'serif'),
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ));

      if (success) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text('Error: $e', style: const TextStyle(fontFamily: 'serif')),
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
          'Generate Appointment Letter',
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
                      const Text(
                        'Appointment Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                          fontFamily: 'serif',
                        ),
                      ),
                      const SizedBox(height: 16),

                      _buildTextField(
                        label: 'To',
                        controller: _toController,
                        icon: Icons.person_outline,
                        isRequired: true,
                      ),

                      _buildDateField(
                        label: 'Appointment Date',
                        date: _appointmentDate,
                        isRequired: true,
                        errorText: _appointmentDateError,
                        onTap: _pickDate,
                      ),

                      _buildTextField(
                        label: 'Probation Period',
                        controller: _probationPeriodController,
                        icon: Icons.schedule_outlined,
                        isRequired: true,
                      ),

                      _buildTextField(
                        label: 'Pay Package',
                        controller: _payPackageController,
                        icon: Icons.payments_outlined,
                        isRequired: true,
                      ),

                      _buildTextField(
                        label: 'Office Timing',
                        controller: _officeTimingController,
                        icon: Icons.access_time_outlined,
                        isRequired: false,
                      ),

                      _buildTextField(
                        label: 'Notice Period',
                        controller: _noticePeriodController,
                        icon: Icons.notification_important_outlined,
                        isRequired: false,
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
                        onPressed: _isSubmitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryText,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          disabledBackgroundColor:
                              AppColors.primaryText.withOpacity(0.4),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                                'Generate Appointment Letter',
                                style:
                                    TextStyle(fontFamily: 'serif', fontSize: 16),
                              ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey[600],
                          side:
                              BorderSide(color: Colors.grey[600]!, width: 2.0),
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

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required bool isRequired,
    int maxLines = 1,
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
              const Text(
                ' *',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'serif',
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.black, fontFamily: 'serif'),
          decoration: InputDecoration(
            labelText: label,
            labelStyle:
                TextStyle(color: AppColors.greyText, fontFamily: 'serif'),
            prefixIcon: Icon(icon, color: AppColors.greyText),
            hintText: 'Enter $label',
            hintStyle:
                TextStyle(color: AppColors.greyText, fontFamily: 'serif'),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.lightGrey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.lightGrey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.secondaryText),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          validator: isRequired
              ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null
              : null,
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required bool isRequired,
    required VoidCallback onTap,
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
              const Text(
                ' *',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'serif',
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: onTap,
          child: Container(
            height: 55,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: errorText != null
                    ? Colors.red
                    : date != null
                        ? AppColors.secondaryText
                        : AppColors.lightGrey,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: errorText != null ? Colors.red : AppColors.greyText,
                ),
                const SizedBox(width: 12),
                Text(
                  date != null ? _displayDate(date) : 'Select date',
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'serif',
                    color: date != null ? Colors.black87 : AppColors.greyText,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              errorText,
              style: const TextStyle(
                  color: Colors.red, fontSize: 12, fontFamily: 'serif'),
            ),
          ),
        const SizedBox(height: 10),
      ],
    );
  }
}
