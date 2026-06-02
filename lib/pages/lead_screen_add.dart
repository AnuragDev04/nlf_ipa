import 'package:flutter/material.dart';
import 'package:nlf/pages/add_department_screen.dart';
import 'package:nlf/pages/add_user_screen.dart';
import 'package:nlf/pages/lead_generation_screen.dart';
import 'package:nlf/utils/colors.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import '../utils/constants.dart';

class AddLeadScreen extends StatefulWidget {
  const AddLeadScreen({super.key});

  @override
  _AddLeadScreenState createState() => _AddLeadScreenState();
}

class _AddLeadScreenState extends State<AddLeadScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  bool _isUploading = false;

  final TextEditingController _projectNameController = TextEditingController();
  final TextEditingController _architectNameController =
  TextEditingController();
  final TextEditingController _clientNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _contractorController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  // ✅ NEW: Controllers for Area and Price
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  // ✅ Store NAME (string) for branch/stage/product/segment, ID for department/salesperson
  String? _selectedBranchName;
  String? _selectedDepartmentId;
  String? _selectedSalesPersonId; // ✅ Store emp_id as String
  String? _selectedStageName;
  String? _selectedProductTypeName;
  String? _selectedSegmentName;

  DateTime _visitDate = DateTime.now();
  DateTime _nextVisitDate = DateTime.now();

  // ✅ NEW: Error state variables for dropdown/date validation
  String? _branchError;
  String? _productTypeError;
  String? _salesPersonError;
  String? _stageError;
  String? _visitDateError;
  String? _nextVisitDateError;

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
    _loadBranches();
    _loadDepartments();
    _loadSalesPeople();
    _loadStages();
    _loadSegments();
    _loadProductTypes();
  }

  @override
  void dispose() {
    _projectNameController.dispose();
    _architectNameController.dispose();
    _clientNameController.dispose();
    _emailController.dispose();
    _contactController.dispose();
    _locationController.dispose();
    _contractorController.dispose();
    _remarksController.dispose();
    // ✅ NEW: Dispose new controllers
    _areaController.dispose();
    _priceController.dispose();
    super.dispose();
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

  // ✅ Load sales people - with DEBUG prints
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
          print('🔍 DEBUG: Raw salespeople  $rawData');

          setState(() {
            _salesPeople = rawData
                .map((item) {
              final empId = item['emp_id']?.toString()?.trim() ?? '';
              final name = item['name']?.toString()?.trim() ?? '';
              print(
                '🔍 DEBUG: Parsed salesperson - emp_id: "$empId", name: "$name"',
              );
              return SalesPersonItem(emp_id: empId, name: name);
            })
                .where(
                  (sp) => sp.emp_id.isNotEmpty,
            ) // ✅ Filter out empty emp_id
                .toList();
            _isLoadingSalesPeople = false;
          });
          print('✅ DEBUG: Loaded ${_salesPeople.length} salespeople');
        } else {
          setState(() => _isLoadingSalesPeople = false);
          String errorMessage = data['message']?.toString() ?? 'Unknown error';
          print('❌ Salesperson API Error: $errorMessage');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Failed to load salespeople: $errorMessage',
                  style: TextStyle(fontFamily: 'serif'),
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        setState(() => _isLoadingSalesPeople = false);
        print('❌ Failed to load salespeople: ${response.statusCode}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to load salespeople: HTTP ${response.statusCode}',
                style: TextStyle(fontFamily: 'serif'),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoadingSalesPeople = false);
      print('❌ Error loading salespeople: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error loading salespeople: $e',
              style: TextStyle(fontFamily: 'serif'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
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
        // ✅ Clear date errors when user selects a date
        if (type == 'Visit') {
          _visitDate = picked;
          _visitDateError = null;
        } else if (type == 'Next Visit') {
          _nextVisitDate = picked;
          _nextVisitDateError = null;
        }
      });
    }
  }

  // ✅ NEW: Validate all required dropdowns and dates before saving
  bool _validateRequiredFields() {
    bool isValid = true;

    // Branch validation
    if (_selectedBranchName == null || _selectedBranchName!.isEmpty) {
      _branchError = 'Required';
      isValid = false;
    } else {
      _branchError = null;
    }

    // Product Type validation
    if (_selectedProductTypeName == null || _selectedProductTypeName!.isEmpty) {
      _productTypeError = 'Required';
      isValid = false;
    } else {
      _productTypeError = null;
    }

    // Salesperson validation
    if (_selectedSalesPersonId == null || _selectedSalesPersonId!.isEmpty) {
      _salesPersonError = 'Required';
      isValid = false;
    } else {
      _salesPersonError = null;
    }

    // Stage validation
    if (_selectedStageName == null || _selectedStageName!.isEmpty) {
      _stageError = 'Required';
      isValid = false;
    } else {
      _stageError = null;
    }

    // Visit Date validation (must be today or future)
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final visitDate = DateTime(
      _visitDate.year,
      _visitDate.month,
      _visitDate.day,
    );
    if (visitDate.isBefore(today)) {
      _visitDateError = 'Cannot be in the past';
      isValid = false;
    } else {
      _visitDateError = null;
    }

    // Next Visit Date validation (must be >= Visit Date)
    final nextVisitDate = DateTime(
      _nextVisitDate.year,
      _nextVisitDate.month,
      _nextVisitDate.day,
    );
    if (nextVisitDate.isBefore(visitDate)) {
      _nextVisitDateError = 'Must be on or after Visit Date';
      isValid = false;
    } else {
      _nextVisitDateError = null;
    }

    return isValid;
  }

  // ✅ NEW: Helper function to convert price to lakhs
  String _convertToLakhs(String priceInput) {
    if (priceInput.isEmpty) return '';
    double? amount = double.tryParse(priceInput);
    if (amount == null) return priceInput;

    // If amount is large (likely in rupees), convert to lakhs
    // 1 Lakh = 100,000
    if (amount >= 100000) {
      return (amount / 100000).toStringAsFixed(2);
    }
    // If already small, assume it's already in lakhs
    return amount.toStringAsFixed(2);
  }

  Future<void> _saveLead() async {
    // ✅ NEW: Validate required dropdowns and dates first
    if (!_validateRequiredFields()) {
      setState(() {}); // Refresh UI to show error messages
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please fill all required fields',
              style: TextStyle(fontFamily: 'serif'),
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    if (_formKey.currentState!.validate()) {
      // 🔍 DEBUG: Print what we're sending
      //print('🔍 DEBUG: _selectedSalesPersonId = "${_selectedSalesPersonId}"');
      //print('🔍 DEBUG: _salesPeople count = ${_salesPeople.length}');

      setState(() => _isUploading = true);

      try {
        final String? salesPersonIdToSend = _selectedSalesPersonId?.trim();

        // ✅ Convert price to lakhs before sending
        final String priceInLakhs = _convertToLakhs(_priceController.text.trim());

        final requestBody = {
          'project_name': _projectNameController.text.trim(),
          'architech_name': _architectNameController.text.trim(),
          'client_name': _clientNameController.text.trim(),
          'email': _emailController.text.trim(),
          'product': _selectedProductTypeName ?? '',
          'contact': _contactController.text.trim(),
          'location': _locationController.text.trim(),
          'segment': _selectedSegmentName ?? '',
          'branch': _selectedBranchName ?? '',
          'contractor': _contractorController.text.trim(),
          'department': _selectedDepartmentId ?? '',
          //'sales_person': salesPersonIdToSend ?? '',
          'emp_id': salesPersonIdToSend ?? '',
          'stage': _selectedStageName ?? '',
          'remark': _remarksController.text.trim(),
          'area': _areaController.text.trim(),
          'amount': priceInLakhs, // ✅ Send converted value in lakhs
          'visiting_date':
          '${_visitDate.year}-${_visitDate.month.toString().padLeft(2, '0')}-${_visitDate.day.toString().padLeft(2, '0')}',
          'nxt_visit_date':
          '${_nextVisitDate.year}-${_nextVisitDate.month.toString().padLeft(2, '0')}-${_nextVisitDate.day.toString().padLeft(2, '0')}',
        };

        print('🔍 DEBUG: Request body: $requestBody');

        final response = await http.post(
          Uri.parse(AppConstants.ADD_LEAD_API),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(requestBody),
        );

        print('🔍 DEBUG: Response status: ${response.statusCode}');
        print('🔍 DEBUG: Response body: ${response.body}');

        if (response.statusCode == 200) {
          final result = json.decode(response.body);
          if (result['status'] == 'true' &&
              (result['success'] == '1' || result['success'] == 1)) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    result['message'] ?? 'Lead added successfully!',
                    style: TextStyle(fontFamily: 'serif'),
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            }

            // Clear form after successful submission
            _projectNameController.clear();
            _architectNameController.clear();
            _clientNameController.clear();
            _emailController.clear();
            _contactController.clear();
            _locationController.clear();
            _contractorController.clear();
            _remarksController.clear();
            // ✅ NEW: Clear new fields
            _areaController.clear();
            _priceController.clear();

            setState(() {
              _selectedBranchName = null;
              _selectedDepartmentId = null;
              _selectedSalesPersonId = null;
              _selectedStageName = null;
              _selectedProductTypeName = null;
              _selectedSegmentName = null;
              _visitDate = DateTime.now();
              _nextVisitDate = DateTime.now();
              // ✅ Clear errors
              _branchError = null;
              _productTypeError = null;
              _salesPersonError = null;
              _stageError = null;
              _visitDateError = null;
              _nextVisitDateError = null;
            });
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const LeadGenerationScreen(),
                ),
              );
            }
          } else {
            String errorMessage = result['message'] ?? 'Failed to add lead';
            throw Exception(errorMessage);
          }
        } else {
          throw Exception('Server error: ${response.statusCode}');
        }
      } catch (e) {
        print('❌ Save error: $e');
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
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "New Lead",
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
                      const SizedBox(height: 16),

                      // ✅ Reduced spacing after section title
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

                      _buildTextField(
                        'Email',
                        _emailController,
                        Icons.email,
                            (value) {
                          if (value!.isEmpty) return 'Required';
                          if (!RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                          ).hasMatch(value))
                            return 'Invalid email';
                          return null;
                        },
                        keyboardType: TextInputType.emailAddress,
                      ),

                      _buildTextField(
                        'Contact',
                        _contactController,
                        Icons.phone,
                            (value) {
                          if (value!.isEmpty) return 'Required';
                          if (value.length != 10)
                            return '10-digit number required';
                          return null;
                        },
                        keyboardType: TextInputType.number,
                        maxLength: 10,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),

                      _buildTextField(
                        'Location',
                        _locationController,
                        Icons.location_on,
                            (value) {
                          if (value!.isEmpty) return 'Required';
                          return null;
                        },
                        keyboardType: TextInputType.visiblePassword,
                      ),

                      // Segment dropdown
                      _buildDropdownField(
                        label: 'Segment',
                        isLoading: _isLoadingSegments,
                        items: _segments.map((s) => s.name).toList(),
                        displayNames: _segments.map((s) => s.name).toList(),
                        value: _selectedSegmentName,
                        onChanged: (String? newValue) {
                          setState(
                                () => _selectedSegmentName = newValue?.trim(),
                          );
                        },
                      ),

                      // Product Type dropdown ✅ REQUIRED with validation
                      _buildDropdownField(
                        label: 'Product Type',
                        isLoading: _isLoadingProductTypes,
                        items: _productTypes.map((p) => p.name).toList(),
                        displayNames: _productTypes.map((p) => p.name).toList(),
                        value: _selectedProductTypeName,
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedProductTypeName = newValue?.trim();
                            _productTypeError = null;
                          });
                        },
                        isRequired: true,
                        errorText: _productTypeError,
                      ),

                      // ✅ NEW: Area (in sqm) Field
                      _buildTextField(
                        'Area (in sqm)',
                        _areaController,
                        Icons.square_foot,
                            (value) {
                          if (value!.isEmpty) return 'Required';
                          if (!RegExp(r'^[0-9]+(\.[0-9]+)?$').hasMatch(value)) {
                            return 'Enter valid number';
                          }
                          double? area = double.tryParse(value);
                          if (area == null || area <= 0) {
                            return 'Area must be positive';
                          }
                          if (area > 1000000) {
                            return 'Area seems too large';
                          }
                          return null;
                        },
                        keyboardType: TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^[0-9]+(\.[0-9]{0,2})?'),
                          ),
                        ],
                      ),

                      // ✅ NEW: Price (in lakhs) Field - Auto-converts to lakhs
                      _buildTextField(
                        'Price (in lakhs)',
                        _priceController,
                        Icons.currency_rupee,
                            (value) {
                          if (value!.isEmpty) return 'Required';
                          if (!RegExp(r'^[0-9]+(\.[0-9]+)?$').hasMatch(value)) {
                            return 'Enter valid number';
                          }
                          double? price = double.tryParse(value);
                          if (price == null || price <= 0) {
                            return 'Price must be positive';
                          }
                          return null;
                        },
                        keyboardType: TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^[0-9]+(\.[0-9]{0,2})?'),
                          ),
                        ],
                      ),

                      // Branch dropdown ✅ REQUIRED with validation
                      _buildDropdownField(
                        label: 'Branch',
                        isLoading: _isLoadingBranches,
                        items: _branches.map((b) => b.name).toList(),
                        displayNames: _branches.map((b) => b.name).toList(),
                        value: _selectedBranchName,
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedBranchName = newValue?.trim();
                            _branchError = null;
                          });
                        },
                        isRequired: true,
                        errorText: _branchError,
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
                          setState(
                                () => _selectedDepartmentId = newValue?.trim(),
                          );
                        },
                      ),

                      // ✅ Salesperson dropdown - REQUIRED with validation
                      KeyedSubtree(
                        key: ValueKey(
                          'salesperson_dropdown_${_salesPeople.length}',
                        ),
                        child: _buildDropdownField(
                          label: 'Salesperson',
                          isLoading: _isLoadingSalesPeople,
                          items: _salesPeople
                              .where((sp) => sp.emp_id.isNotEmpty)
                              .map((sp) => sp.emp_id.trim())
                              .toList(),
                          displayNames: _salesPeople
                              .where((sp) => sp.emp_id.isNotEmpty)
                              .map((sp) => sp.name)
                              .toList(),
                          value: _selectedSalesPersonId?.trim(),
                          onChanged: (String? newValue) {
                            print(
                              '🔍 DEBUG: Salesperson selected: emp_id="$newValue"',
                            );
                            setState(() {
                              _selectedSalesPersonId = newValue?.trim();
                              _salesPersonError = null;
                            });
                          },
                          isRequired: true,
                          errorText: _salesPersonError,
                        ),
                      ),

                      // Stage dropdown ✅ REQUIRED with validation
                      _buildDropdownField(
                        label: 'Stage',
                        isLoading: _isLoadingStages,
                        items: _stages.map((s) => s.name).toList(),
                        displayNames: _stages.map((s) => s.name).toList(),
                        value: _selectedStageName,
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedStageName = newValue?.trim();
                            _stageError = null;
                          });
                        },
                        isRequired: true,
                        errorText: _stageError,
                      ),

                      _buildTextAreaField('Remarks', _remarksController),

                      // Visit Date ✅ REQUIRED with validation
                      _buildDateField(
                        'Visit Date',
                        _visitDate,
                            () => _selectDate(context, 'Visit'),
                        isRequired: true,
                        errorText: _visitDateError,
                      ),

                      // Next Visit Date ✅ REQUIRED with validation
                      _buildDateField(
                        'Next Visit',
                        _nextVisitDate,
                            () => _selectDate(context, 'Next Visit'),
                        isRequired: true,
                        errorText: _nextVisitDateError,
                      ),

                      // 🔍 DEBUG: Show selected value
                      /* if (_selectedSalesPersonId != null &&
                          _selectedSalesPersonId!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '✓ Selected Salesperson ID: "${_selectedSalesPersonId}"',
                            style: TextStyle(
                              color: Colors.green[700],
                              fontSize: 12,
                              fontFamily: 'serif',
                            ),
                          ),
                        ),*/
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
                          'Save Lead',
                          style: TextStyle(fontFamily: 'serif', fontSize: 16),
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
                          style: TextStyle(fontFamily: 'serif',  fontSize: 16),
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

  // ✅ UPDATED: Spacing moved AFTER the field for cleaner UI
  Widget _buildTextField(
      String label,
      TextEditingController controller,
      IconData icon,
      String? Function(String?) validator, {
        TextInputType? keyboardType,
        int? maxLength,
        List<TextInputFormatter>? inputFormatters,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✅ Label with minimal bottom margin
        Text(
          label,
          style: TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.w500,
            fontFamily: 'serif',
          ),
        ),
        const SizedBox(height: 4),
        // ✅ Reduced: Label closer to field
        TextFormField(
          controller: controller,
          style: TextStyle(color: Colors.black, fontFamily: 'serif'),
          keyboardType: keyboardType,
          maxLength: maxLength,
          inputFormatters: inputFormatters,
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
            counterText: "",
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          validator: validator,
        ),
        const SizedBox(height: 10),
        // ✅ NEW: Space AFTER field (before next label)
      ],
    );
  }

  // ✅ UPDATED: Spacing moved AFTER the field for cleaner UI
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
        const SizedBox(height: 4), // ✅ Reduced: Label closer to field
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
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
        const SizedBox(height: 10), // ✅ NEW: Space AFTER field
      ],
    );
  }

  // ✅ UPDATED: Date field with spacing AFTER and required indicator
  Widget _buildDateField(
      String label,
      DateTime date,
      VoidCallback onTap, {
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
              style: TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'serif',
              ),
            ),
            if (isRequired)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  '*',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'serif',
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4), // ✅ Reduced: Label closer to field
        InkWell(
          onTap: onTap,
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: errorText != null ? Colors.red : AppColors.lightGrey,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: errorText != null ? Colors.red : AppColors.greyText,
                ),
                SizedBox(width: 12),
                Text(
                  '${date.day}/${date.month}/${date.year}',
                  style: TextStyle(
                    color: errorText != null ? Colors.red : Colors.black,
                    fontFamily: 'serif',
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
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
                fontFamily: 'serif',
              ),
            ),
          ),
        const SizedBox(height: 10), // ✅ NEW: Space AFTER field
      ],
    );
  }

  // ✅ UPDATED: Dropdown builder with spacing AFTER and required indicator
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
    if (label == 'Salesperson') {
      print(
        '🔍 DEBUG: Dropdown "$label" - items count: ${items.length}, value: "$value"',
      );
    }

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
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  '*',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'serif',
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4), // ✅ Reduced: Label closer to field
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
              value: value != null && items.contains(value)
                  ? value
                  : null,
              isExpanded: true,
              underline: const SizedBox(),
              dropdownColor: Colors.grey[200],
              style: TextStyle(
                color: errorText != null ? Colors.red : Colors.black,
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
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              errorText,
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
                fontFamily: 'serif',
              ),
            ),
          ),
        const SizedBox(height: 10), // ✅ NEW: Space AFTER field
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