import 'package:flutter/material.dart';
import 'package:nlf/pages/lead_generation_screen.dart';
import 'package:nlf/utils/colors.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/constants.dart';

class LeadScreenEdit extends StatefulWidget {
  final String leadId; // ✅ Added: Lead ID to fetch/edit

  const LeadScreenEdit({super.key, required this.leadId});

  @override
  _LeadScreenEditState createState() => _LeadScreenEditState();
}

class _LeadScreenEditState extends State<LeadScreenEdit>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  bool _isUploading = false;
  bool _isLoadingLeadData = true; // ✅ Added: Loading state for lead data

  final TextEditingController _projectNameController = TextEditingController();
  final TextEditingController _architectNameController =
  TextEditingController();
  final TextEditingController _clientNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _contractorController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  // ✅ Store NAME (string) for branch/stage/product/segment, ID for department/salesperson
  String? _selectedBranchName;
  String? _selectedDepartmentId;
  String? _selectedSalesPersonId;
  String? _selectedStageName;
  String? _selectedProductTypeName;
  String? _selectedSegmentName;

  DateTime _visitDate = DateTime.now();
  DateTime _nextVisitDate = DateTime.now();

  List<BranchItem> _branches = [];
  List<DepartmentItem> _departments = [];
  List<StageItem> _stages = [];
  List<SalesPersonItem> _salesPeople = [];
  List<SegmentItem> _segments = [];
  List<ProductTypeItem> _productTypes = [];

  bool _isLoadingBranches = true;
  bool _isLoadingDepartments = true;
  bool _isLoadingSalesPeople = true;
  bool _isLoadingStages = true;
  bool _isLoadingSegments = true;
  bool _isLoadingProductTypes = true;

  @override
  void initState() {
    super.initState();
    _loadAllDropdownData();
    _loadLeadData(); // ✅ Fetch lead data after dropdowns start loading
  }

  // ✅ Load all dropdown data in parallel
  Future<void> _loadAllDropdownData() async {
    await Future.wait([
      _loadBranches(),
      _loadDepartments(),
      _loadSalesPeople(),
      _loadStages(),
      _loadSegments(),
      _loadProductTypes(),
    ]);
  }

  // ✅ Fetch lead data from API and populate form
  Future<void> _loadLeadData() async {
    try {
      setState(() => _isLoadingLeadData = true);

      final response = await http.post(
        Uri.parse(AppConstants.FETCH_LEAD_API),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': widget.leadId}), // ✅ Send lead ID
      );

      print('🔍 DEBUG: Fetch Lead Response: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['status'] == 'true' && data['success'] == '1') {
          final lead = data['data'];

          setState(() {
            // ✅ Populate text fields
            _projectNameController.text = lead['project_name'] ?? '';
            _architectNameController.text = lead['architech_name'] ?? '';
            _clientNameController.text = lead['client_name'] ?? '';
            _emailController.text = lead['email'] ?? '';
            _contactController.text = lead['contact'] ?? '';
            _locationController.text = lead['location'] ?? '';
            _contractorController.text = lead['contractor'] ?? '';
            _remarksController.text = lead['remark'] ?? '';

            // ✅ Populate dropdown selections (using API values)
            _selectedBranchName = lead['branch']?.toString()?.trim();
            _selectedDepartmentId = lead['department_name']?.toString()?.trim();
            _selectedSalesPersonId = lead['employee_name']?.toString()?.trim();
            _selectedStageName = lead['stage']?.toString()?.trim();
            _selectedProductTypeName = lead['product']?.toString()?.trim();
            _selectedSegmentName = lead['segment']?.toString()?.trim();

            // ✅ Parse and set dates (API format: DD-MM-YYYY)
            if (lead['visiting_date'] != null &&
                lead['visiting_date'].toString().isNotEmpty) {
              _visitDate = _parseDate(lead['visiting_date'].toString());
            }
            if (lead['nxt_visit_date'] != null &&
                lead['nxt_visit_date'].toString().isNotEmpty) {
              _nextVisitDate = _parseDate(lead['nxt_visit_date'].toString());
            }

            _isLoadingLeadData = false;
          });

          print('✅ Lead data loaded successfully');
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch lead');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('❌ Error loading lead data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error loading lead: $e',
              style: TextStyle(fontFamily: 'serif'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isLoadingLeadData = false);
    }
  }

  // ✅ Helper: Parse DD-MM-YYYY to DateTime
  DateTime _parseDate(String dateString) {
    try {
      // Handle both "DD-MM-YYYY" and "YYYY-MM-DD" formats
      if (dateString.contains('-')) {
        final parts = dateString.split('-');
        if (parts.length == 3) {
          // If first part is 4 digits, it's YYYY-MM-DD
          if (parts[0].length == 4) {
            return DateTime(
              int.parse(parts[0]),
              int.parse(parts[1]),
              int.parse(parts[2]),
            );
          }
          // Otherwise assume DD-MM-YYYY
          return DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
        }
      }
      return DateTime.now();
    } catch (e) {
      print('⚠️ Date parse error for "$dateString": $e');
      return DateTime.now();
    }
  }

  // ✅ Load product types from API
  Future<void> _loadProductTypes() async {
    try {
      setState(() => _isLoadingProductTypes = true);
      final response = await http.get(
        Uri.parse(AppConstants.PRODUCT_TYPE_LIST_API),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'true' && data['data'] != null) {
          setState(() {
            _productTypes = (data['data'] as List)
                .map(
                  (item) => ProductTypeItem(
                id: item['prod_type_id']?.toString()?.trim() ?? '',
                name: item['product_type']?.toString()?.trim() ?? '',
              ),
            )
                .toList();
            _isLoadingProductTypes = false;
          });
        }
      }
    } catch (e) {
      print('Error loading product types: $e');
    } finally {
      setState(() => _isLoadingProductTypes = false);
    }
  }

  // ✅ Load segments from API
  Future<void> _loadSegments() async {
    try {
      setState(() => _isLoadingSegments = true);
      final response = await http.get(
        Uri.parse(AppConstants.SEGMENT_LIST_API),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'true' && data['data'] != null) {
          setState(() {
            _segments = (data['data'] as List)
                .map(
                  (item) => SegmentItem(
                id: item['id']?.toString()?.trim() ?? '',
                name: item['segment']?.toString()?.trim() ?? '',
              ),
            )
                .toList();
            _isLoadingSegments = false;
          });
        }
      }
    } catch (e) {
      print('Error loading segments: $e');
    } finally {
      setState(() => _isLoadingSegments = false);
    }
  }

  Future<void> _loadBranches() async {
    try {
      setState(() => _isLoadingBranches = true);
      final response = await http.get(
        Uri.parse(AppConstants.BRANCH_LIST_API),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'true' &&
            (data['success'] == '1' || data['success'] == 1)) {
          setState(() {
            _branches = (data['data'] as List)
                .map(
                  (item) => BranchItem(
                id: item['id']?.toString()?.trim() ?? '',
                name: item['branch_name']?.toString()?.trim() ?? '',
              ),
            )
                .toList();
            _isLoadingBranches = false;
          });
        }
      }
    } catch (e) {
      print('Error loading branches: $e');
    } finally {
      setState(() => _isLoadingBranches = false);
    }
  }

  Future<void> _loadDepartments() async {
    try {
      setState(() => _isLoadingDepartments = true);
      final response = await http.get(
        Uri.parse(AppConstants.DEPARTMENT_LIST_API),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'true' &&
            (data['success'] == '1' || data['success'] == 1)) {
          setState(() {
            _departments = (data['data'] as List)
                .map(
                  (item) => DepartmentItem(
                id: item['dpt_id']?.toString()?.trim() ?? '',
                name: item['department']?.toString()?.trim() ?? '',
              ),
            )
                .toList();
            _isLoadingDepartments = false;
          });
        }
      }
    } catch (e) {
      print('Error loading departments: $e');
    } finally {
      setState(() => _isLoadingDepartments = false);
    }
  }

  // ✅ Load sales people
  Future<void> _loadSalesPeople() async {
    try {
      setState(() => _isLoadingSalesPeople = true);

      final response = await http.post(
        Uri.parse(AppConstants.EMPLOYEE_LIST_API),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'role': 'sales'}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['status'] == true && data['success'] == '1') {
          final List<dynamic> rawData = data['data'] as List;

          setState(() {
            _salesPeople = rawData
                .map((item) {
              final empId = item['emp_id']?.toString()?.trim() ?? '';
              final name = item['name']?.toString()?.trim() ?? '';
              return SalesPersonItem(emp_id: empId, name: name);
            })
                .where((sp) => sp.emp_id.isNotEmpty)
                .toList();
            _isLoadingSalesPeople = false;
          });
        } else {
          setState(() => _isLoadingSalesPeople = false);
        }
      } else {
        setState(() => _isLoadingSalesPeople = false);
      }
    } catch (e) {
      setState(() => _isLoadingSalesPeople = false);
      print('Error loading salespeople: $e');
    }
  }

  Future<void> _loadStages() async {
    try {
      setState(() => _isLoadingStages = true);
      final response = await http.get(
        Uri.parse(AppConstants.STAGE_LIST_API),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'true' && data['success'] == '1') {
          setState(() {
            _stages = (data['data'] as List)
                .map(
                  (item) => StageItem(
                id: item['id']?.toString()?.trim() ?? '',
                name: item['name']?.toString()?.trim() ?? '',
              ),
            )
                .toList();
            _isLoadingStages = false;
          });
        }
      }
    } catch (e) {
      print('Error loading stages: $e');
    } finally {
      setState(() => _isLoadingStages = false);
    }
  }

  Future<void> _selectDate(BuildContext context, String type) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (type == 'Visit') {
          _visitDate = picked;
        } else if (type == 'Next Visit') {
          _nextVisitDate = picked;
        }
      });
    }
  }

  // ✅ UPDATE lead function - sends emp_id for sales_person + lead ID
  Future<void> _saveLead() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isUploading = true);

      try {
        final requestBody = {
          'id': widget.leadId, // ✅ CRITICAL: Include lead ID for update
          'project_name': _projectNameController.text.trim(),
          'product': _selectedProductTypeName ?? '',
          'architech_name': _architectNameController.text.trim(),
          'client_name': _clientNameController.text.trim(),
          'email': _emailController.text.trim(),
          'contact': _contactController.text.trim(),
          'location': _locationController.text.trim(),
          'segment': _selectedSegmentName ?? '',
          'branch': _selectedBranchName ?? '',
          'contractor': _contractorController.text.trim(),
          'department': _selectedDepartmentId ?? '',
          'sales_person': _selectedSalesPersonId?.trim() ?? '',
          'stage': _selectedStageName ?? '',
          'remark': _remarksController.text.trim(),
          'visiting_date':
          '${_visitDate.year}-${_visitDate.month.toString().padLeft(2, '0')}-${_visitDate.day.toString().padLeft(2, '0')}',
          'nxt_visit_date':
          '${_nextVisitDate.year}-${_nextVisitDate.month.toString().padLeft(2, '0')}-${_nextVisitDate.day.toString().padLeft(2, '0')}',
        };

        print('🔍 DEBUG: Update Request: $requestBody');

        // ✅ Use UPDATE_LEAD_API for editing (not ADD_LEAD_API)
        final response = await http.post(
          Uri.parse(AppConstants.UPDATE_LEAD_API),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(requestBody),
        );

        print('🔍 DEBUG: Update Response: ${response.statusCode} - ${response.body}');

        if (response.statusCode == 200) {
          final result = json.decode(response.body);
          if (result['status'] == 'true' &&
              (result['success'] == '1' || result['success'] == 1)) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    result['message'] ?? 'Lead updated successfully!',
                    style: TextStyle(fontFamily: 'serif'),
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            }
            if (mounted) {
              Navigator.pop(context, true);
            }
          } else {
            String errorMessage = result['message'] ?? 'Failed to update lead';
            throw Exception(errorMessage);
          }
        } else {
          throw Exception('Server error: ${response.statusCode}');
        }
      } catch (e) {
        print('❌ Update error: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e', style: TextStyle(fontFamily: 'serif')),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isUploading = false);
        }
      }
    }
  }

  void _cancelLead() => Navigator.pop(context);

  @override
  Widget build(BuildContext context) {
    // ✅ Show loading while fetching lead data
    if (_isLoadingLeadData) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            "Edit Lead",
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
        ),
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryText),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Edit Lead", // ✅ Changed from "New Lead"
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
                      _buildSectionTitle('Lead Details'),
                      const SizedBox(height: 20),

                      _buildTextField(
                        'Project Name',
                        _projectNameController,
                        Icons.work,
                            (value) {
                          if (value!.isEmpty) return 'Required';
                          return null;
                        },
                      ),

                      _buildTextField(
                        'Architect Name',
                        _architectNameController,
                        Icons.person,
                            (value) {
                          if (value!.isEmpty) return 'Required';
                          return null;
                        },
                      ),

                      _buildTextField(
                        'Client Name',
                        _clientNameController,
                        Icons.person_outline,
                            (value) {
                          if (value!.isEmpty) return 'Required';
                          return null;
                        },
                      ),

                      _buildTextField('Email', _emailController, Icons.email, (
                          value,
                          ) {
                        if (value!.isEmpty) return 'Required';
                        if (!RegExp(
                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                        ).hasMatch(value))
                          return 'Invalid email';
                        return null;
                      }),

                      /*_buildTextField(
                        'Contact',
                        _contactController,
                        Icons.phone,
                            (value) {
                          if (value!.isEmpty) return 'Required';
                          if (value.length != 10)
                            return '10-digit number required';
                          return null;
                        },
                      ),*/

                      _buildTextField(
                        'Location',
                        _locationController,
                        Icons.location_on,
                            (value) {
                          if (value!.isEmpty) return 'Required';
                          return null;
                        },
                      ),

                      // Segment dropdown
                      _buildDropdownField(
                        label: 'Segment',
                        isLoading: _isLoadingSegments,
                        items: _segments.map((s) => s.name).toList(),
                        displayNames: _segments.map((s) => s.name).toList(),
                        value: _selectedSegmentName,
                        onChanged: (String? newValue) {
                          setState(() => _selectedSegmentName = newValue);
                        },
                      ),

                      // Product Type dropdown
                      _buildDropdownField(
                        label: 'Product Type',
                        isLoading: _isLoadingProductTypes,
                        items: _productTypes.map((p) => p.name).toList(),
                        displayNames: _productTypes.map((p) => p.name).toList(),
                        value: _selectedProductTypeName,
                        onChanged: (String? newValue) {
                          setState(() => _selectedProductTypeName = newValue);
                        },
                      ),

                      // Branch dropdown
                      _buildDropdownField(
                        label: 'Branch',
                        isLoading: _isLoadingBranches,
                        items: _branches.map((b) => b.name).toList(),
                        displayNames: _branches.map((b) => b.name).toList(),
                        value: _selectedBranchName,
                        onChanged: (String? newValue) {
                          setState(() => _selectedBranchName = newValue);
                        },
                      ),

                      _buildTextField(
                        'Contractor',
                        _contractorController,
                        Icons.build,
                            (value) {
                          if (value!.isEmpty) return 'Required';
                          return null;
                        },
                      ),

                      // Department dropdown (uses ID)
                      _buildDropdownField(
                        label: 'Department',
                        isLoading: _isLoadingDepartments,
                        items: _departments.map((d) => d.id).toList(),
                        displayNames: _departments.map((d) => d.name).toList(),
                        value: _selectedDepartmentId,
                        onChanged: (String? newValue) {
                          setState(() => _selectedDepartmentId = newValue);
                        },
                      ),

                      // Salesperson dropdown
                      KeyedSubtree(
                        key: ValueKey(
                          'salesperson_dropdown_${_salesPeople.length}',
                        ),
                        child: _buildDropdownField(
                          label: 'Salesperson',
                          isLoading: _isLoadingSalesPeople,
                          items: _salesPeople
                              .where((sp) => sp.emp_id.isNotEmpty)
                              .map((sp) => sp.emp_id)
                              .toList(),
                          displayNames: _salesPeople
                              .where((sp) => sp.emp_id.isNotEmpty)
                              .map((sp) => sp.name)
                              .toList(),
                          value: _selectedSalesPersonId,
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedSalesPersonId = newValue?.trim();
                            });
                          },
                        ),
                      ),

                      // Stage dropdown
                      _buildDropdownField(
                        label: 'Stage',
                        isLoading: _isLoadingStages,
                        items: _stages.map((s) => s.name).toList(),
                        displayNames: _stages.map((s) => s.name).toList(),
                        value: _selectedStageName,
                        onChanged: (String? newValue) {
                          setState(() => _selectedStageName = newValue);
                        },
                      ),

                      _buildTextAreaField('Remarks', _remarksController),

                      _buildDateField(
                        'Visit Date',
                        _visitDate,
                            () => _selectDate(context, 'Visit'),
                      ),

                      _buildDateField(
                        'Next Visit',
                        _nextVisitDate,
                            () => _selectDate(context, 'Next Visit'),
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
                        onPressed: _isUploading ? null : _saveLead,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryText,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isUploading
                            ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                          ),
                        )
                            : Text(
                          'Update Lead', // ✅ Changed button text
                          style: TextStyle(fontFamily: 'serif'),
                        ),
                      ),
                    ),
                    SizedBox(width: 15),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isUploading ? null : _cancelLead,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.grey[600],
                          side: BorderSide(
                            color: Colors.grey[600]!,
                            width: 2.0,
                          ),
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(fontFamily: 'serif'),
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
      style: TextStyle(
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
      String? Function(String?) validator,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            fontFamily: 'serif',
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          style: TextStyle(color: Colors.black, fontFamily: 'serif'),
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
              borderSide: BorderSide(color: AppColors.secondaryText),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildTextAreaField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            fontFamily: 'serif',
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: 4,
          style: TextStyle(color: Colors.black, fontFamily: 'serif'),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(
              color: AppColors.greyText,
              fontFamily: 'serif',
            ),
            hintText: 'Enter $label',
            hintStyle: TextStyle(
              color: AppColors.greyText,
              fontFamily: 'serif',
            ),
            prefixIcon: Icon(Icons.note, color: AppColors.greyText),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.lightGrey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.secondaryText),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField(String label, DateTime date, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            fontFamily: 'serif',
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.lightGrey),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: AppColors.greyText),
                SizedBox(width: 12),
                Text(
                  '${date.day}/${date.month}/${date.year}',
                  style: TextStyle(color: Colors.black, fontFamily: 'serif'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ✅ Dropdown builder
  Widget _buildDropdownField({
    required String label,
    required bool isLoading,
    required List<String> items,
    required List<String> displayNames,
    required String? value,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isLoading ? Colors.grey : AppColors.lightGrey,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: isLoading
                ? Row(
              children: [
                Icon(Icons.hourglass_empty, color: AppColors.greyText),
                const SizedBox(width: 10),
                Text(
                  'Loading...',
                  style: TextStyle(
                    color: AppColors.greyText,
                    fontFamily: 'serif',
                  ),
                ),
              ],
            )
                : items.isEmpty
                ? DropdownButton<String>(
              isExpanded: true,
              underline: const SizedBox(),
              dropdownColor: Colors.grey[200],
              style: const TextStyle(
                color: Colors.black,
                fontFamily: 'serif',
              ),
              hint: Text(
                'No $label available',
                style: TextStyle(
                  color: AppColors.greyText,
                  fontFamily: 'serif',
                ),
              ),
              items: [],
              onChanged: null,
            )
                : DropdownButton<String>(
              value: items.contains(value) ? value : null,
              isExpanded: true,
              underline: const SizedBox(),
              dropdownColor: Colors.grey[200],
              style: const TextStyle(
                color: Colors.black,
                fontFamily: 'serif',
              ),
              hint: Text(
                'Select $label',
                style: TextStyle(
                  color: AppColors.greyText,
                  fontFamily: 'serif',
                ),
              ),
              items: List.generate(items.length, (index) {
                return DropdownMenuItem<String>(
                  value: items[index],
                  child: Text(
                    displayNames[index],
                    style: const TextStyle(
                      color: Colors.black,
                      fontFamily: 'serif',
                    ),
                  ),
                );
              }),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

// ✅ Model Classes

class ProductTypeItem {
  final String id;
  final String name;
  ProductTypeItem({required this.id, required this.name});
}

class SegmentItem {
  final String id;
  final String name;
  SegmentItem({required this.id, required this.name});
}

class BranchItem {
  final String id;
  final String name;
  BranchItem({required this.id, required this.name});
}

class DepartmentItem {
  final String id;
  final String name;
  DepartmentItem({required this.id, required this.name});
}

class StageItem {
  final String id;
  final String name;
  StageItem({required this.id, required this.name});
}

class SalesPersonItem {
  final String emp_id;
  final String name;
  SalesPersonItem({required this.emp_id, required this.name});
}