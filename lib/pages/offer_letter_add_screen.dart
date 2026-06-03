import 'package:flutter/material.dart';
import 'package:nlf/utils/colors.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class AddOfferLetterScreen extends StatefulWidget {
  const AddOfferLetterScreen({super.key});

  @override
  State<AddOfferLetterScreen> createState() => _AddOfferLetterScreenState();
}

class _AddOfferLetterScreenState extends State<AddOfferLetterScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  final _toController = TextEditingController();
  final _subjectController = TextEditingController();
  final _roleController = TextEditingController();
  final _placeController = TextEditingController();
  final _bestRegardsController = TextEditingController();

  DateTime? _startDate;
  DateTime? _returnDate;
  String? _startDateError;

  @override
  void dispose() {
    _toController.dispose();
    _subjectController.dispose();
    _roleController.dispose();
    _placeController.dispose();
    _bestRegardsController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';

  String _displayDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          _startDateError = null;
          if (_returnDate != null && _returnDate!.isBefore(_startDate!)) {
            _returnDate = null;
          }
        } else {
          _returnDate = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    bool valid = _formKey.currentState!.validate();
    if (_startDate == null) {
      setState(() => _startDateError = 'Required');
      valid = false;
    }
    if (!valid) return;

    setState(() => _isSubmitting = true);
    try {
      final response = await http.post(
        Uri.parse(AppConstants.ADD_OFFER_LETTER_API),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'to': _toController.text.trim(),
          'subject': _subjectController.text.trim(),
          'role': _roleController.text.trim(),
          'place': _placeController.text.trim(),
          'start_date': _formatDate(_startDate!),
          'return_date': _returnDate != null ? _formatDate(_returnDate!) : '',
          'best_regards': _bestRegardsController.text.trim(),
          'offer_approval': 'Pending',
          'signature': '',
        },
      );

      if (!mounted) return;
      
      // Debug: Print response
      debugPrint('Response Status: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');
      
      // Check if response is valid JSON
      Map<String, dynamic> data;
      try {
        data = json.decode(response.body);
      } catch (e) {
        // If not valid JSON, show raw response
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Server Error: ${response.body}', 
              style: const TextStyle(fontFamily: 'serif')),
          backgroundColor: Colors.red,
        ));
        return;
      }
      
      final success = data['status'] == 'true' || data['status'] == true;

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          data['message']?.toString() ??
              (success ? 'Offer letter generated!' : 'Failed to generate'),
          style: const TextStyle(fontFamily: 'serif'),
        ),
        backgroundColor: success ? Colors.green : Colors.red,
      ));

      if (success) Navigator.pop(context, true);
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
          'Generate Offer Letter',
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
                        'Letter Details',
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

                      _buildTextField(
                        label: 'Subject',
                        controller: _subjectController,
                        icon: Icons.subject,
                        isRequired: true,
                      ),

                      _buildTextField(
                        label: 'Role',
                        controller: _roleController,
                        icon: Icons.badge_outlined,
                        isRequired: true,
                      ),

                      _buildTextField(
                        label: 'Place',
                        controller: _placeController,
                        icon: Icons.location_on_outlined,
                        isRequired: true,
                      ),

                      // Start Date *
                      _buildDateField(
                        label: 'Start Date',
                        date: _startDate,
                        isRequired: true,
                        errorText: _startDateError,
                        onTap: () => _pickDate(true),
                      ),

                      // Return Date
                      _buildDateField(
                        label: 'Return Date',
                        date: _returnDate,
                        isRequired: false,
                        onTap: () => _pickDate(false),
                      ),

                      _buildTextField(
                        label: 'Best Regards',
                        controller: _bestRegardsController,
                        icon: Icons.note,
                        isRequired: false,
                        maxLines: 4,
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
                                'Generate Offer Letter',
                                style: TextStyle(
                                    fontFamily: 'serif', fontSize: 16),
                              ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            _isSubmitting ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey[600],
                          side: BorderSide(color: Colors.grey[600]!, width: 2.0),
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
            labelStyle: TextStyle(color: AppColors.greyText, fontFamily: 'serif'),
            prefixIcon: Icon(icon, color: AppColors.greyText),
            hintText: 'Enter $label',
            hintStyle: TextStyle(color: AppColors.greyText, fontFamily: 'serif'),
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
              const Text(' *',
                  style: TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'serif')),
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
        const SizedBox(height: 12),
      ],
    );
  }
}
