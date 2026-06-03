import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/colors.dart';

class AddQuotationScreen extends StatefulWidget {
  const AddQuotationScreen({super.key});

  @override
  State<AddQuotationScreen> createState() => AddQuotationScreenState();
}

class AddQuotationScreenState extends State<AddQuotationScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Radio Button States
  String _quoteType = 'New'; // Lead, New
  String _quotationCategory = 'Regular'; // Regular, Furniture

  // Controllers for New Quotation Section
  final _quoteNoController = TextEditingController();
  final _clientNameController = TextEditingController();
  final _cityController = TextEditingController();
  final _projectNameController = TextEditingController();
  final _kindAttentionController = TextEditingController();
  final _subjectController = TextEditingController();
  final _termsController = TextEditingController(text: """1. GST @18% extra

2. Payment Terms:

Supply Terms: 10% advance payment against readiness of material before dispatch.

Installation Terms: 80% on installation of material, 10% after handover on a pro-rata basis, 5% as retention to be released after 12 months against submission of a Bank Guarantee.

3. Transportation charges are included in the above rate.

4. The above rates does not include any MS/Aluminium substructure required.

5. Safe storage for the material to be provided by you at site with a locked room.

6. Providing & fixing of scaffolding shall be in your scope. In case scaffolding material is provided, labour charges will be applicable at ₹100/- per sqm.

7. All specifications of each product shall be approved by AAI before execution of the works.

8. Mode of Measurement: Measurements will be considered based on the surface area.

9. Suitable accommodation for site Engineer & hutment for labour to be provided by the client along with lodging & boarding.

10. Validity of Quotation: 30 days.""");

  // Dropdown Lists
  List<String> _branchesList = ['Select Branch'];
  List<String> _assignedByList = ['Select Employee'];
  List<String> _brandsList = ['Select Brand'];
  List<String> _unitsList = ['Select Unit'];
  
  String? _selectedBranch = 'Select Branch';
  String? _selectedAssignedBy = 'Select Employee';

  DateTime _selectedDate = DateTime.now();

  // Dynamic Item List
  List<QuotationItemRow> quotationItems = [QuotationItemRow()];
  List<dynamic> _allProductsList = [];

  bool _isUploading = false;
  String _empId = '';
  String _role = '';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _empId = prefs.getString('id') ?? prefs.getString('emp_id') ?? '1';
      String? userDataStr = prefs.getString('userData');
      if (userDataStr != null) {
        try {
          final data = json.decode(userDataStr);
          if (data['data'] != null) {
             _role = data['data']['roll']?.toString() ?? data['data']['role']?.toString() ?? '1';
          }
        } catch (e) {
          _role = '1';
        }
      } else {
        _role = '1';
      }
    });
    _fetchBranches();
    _fetchEmployees();
    _fetchNextQuoteNo();
    _fetchBrands();
    _fetchUnits();
  }

  Future<void> _fetchNextQuoteNo() async {
    try {
      String url = _quotationCategory == 'Furniture' 
          ? "https://nlfs.in/erp/index.php/Erp/get_next_furniture_no"
          : "https://nlfs.in/erp/index.php/Erp/get_next_quote_no";
          
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == "1" || data['success'] == 1) {
          String? nextNo = data['next_quote_no']?.toString() ?? data['next_furniture_no']?.toString();
          if (nextNo != null) {
            setState(() {
              _quoteNoController.text = nextNo;
            });
          }
        }
      }
    } catch (e) {
      print("Error fetching next quote no: $e");
    }
  }

  Future<void> _fetchBranches() async {
    try {
      final response = await http.get(Uri.parse("https://nlfs.in/erp/index.php/Erp/branch_list"));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == "1" || data['success'] == 1) {
          List<dynamic> list = data['data'];
          setState(() {
            _branchesList = ['Select Branch'];
            for (var item in list) {
              _branchesList.add(item['branch_name'].toString());
            }
          });
        }
      }
    } catch (e) {
      print("Error fetching branches: $e");
    }
  }

  Future<void> _fetchEmployees() async {
    try {
      final response = await http.get(Uri.parse("https://nlfs.in/erp/index.php/Erp/list_emp_admin_sales"));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == "1" || data['success'] == 1) {
          List<dynamic> list = data['data'];
          setState(() {
            _assignedByList = ['Select Employee'];
            for (var item in list) {
              _assignedByList.add(item['name'].toString());
            }
          });
        }
      }
    } catch (e) {
      print("Error fetching employees: $e");
    }
  }

  Future<void> _fetchBrands() async {
    try {
      final response = await http.get(Uri.parse("https://nlfs.in/erp/index.php/Api/list_mst_sub_product"));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == "1" || data['success'] == 1) {
          List<dynamic> list = data['data'];
          Set<String> uniqueBrands = {'Select Brand'};
          for (var item in list) {
            if (item['brand'] != null && item['brand'].toString().isNotEmpty) {
              uniqueBrands.add(item['brand'].toString());
            }
          }
          setState(() {
            _allProductsList = list;
            _brandsList = uniqueBrands.toList();
          });
        }
      }
    } catch (e) {
      print("Error fetching brands: $e");
    }
  }

  Future<void> _fetchUnits() async {
    try {
      final response = await http.get(Uri.parse("https://nlfs.in/erp/index.php/Erp/unit_list"));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == "1" || data['success'] == 1) {
          List<dynamic> list = data['data'];
          setState(() {
            _unitsList = ['Select Unit'];
            for (var item in list) {
              if (item['unit'] != null && item['unit'].toString().isNotEmpty) {
                _unitsList.add(item['unit'].toString());
              }
            }
          });
        }
      }
    } catch (e) {
      print("Error fetching units: $e");
    }
  }

  @override
  void dispose() {
    _quoteNoController.dispose();
    _clientNameController.dispose();
    _cityController.dispose();
    _projectNameController.dispose();
    _kindAttentionController.dispose();
    _subjectController.dispose();
    _termsController.dispose();
    for (var item in quotationItems) {
      item.dispose();
    }
    super.dispose();
  }

  List<String> _getProductsForBrand(String brand) {
    if (brand == 'Select Brand') return ['Select Product'];
    Set<String> products = {'Select Product'};
    for (var item in _allProductsList) {
      if (item['brand'] == brand && item['g3_category'] != null && item['g3_category'].toString().isNotEmpty) {
        products.add(item['g3_category'].toString());
      }
    }
    return products.toList();
  }

  List<String> _getSubProductsForProduct(String brand, String product) {
    if (product == 'Select Product') return ['Select Sub Product'];
    Set<String> subProducts = {'Select Sub Product'};
    for (var item in _allProductsList) {
      if (item['brand'] == brand && item['g3_category'] == product && item['item_name'] != null && item['item_name'].toString().isNotEmpty) {
        subProducts.add(item['item_name'].toString());
      }
    }
    return subProducts.toList();
  }

  String _wrapTermsWithHtml(String terms) {
    if (terms.isEmpty) return "";
    final lines = terms.split('\n');
    final formattedLines = lines.map((line) => '<div>${line.trim()}</div>').join('\n');
    
    return """
<div class=\"nlf-terms-wrapper\" style=\"font-family: Arial,Helvetica,sans-serif; font-size:12px; line-height:1.2; color:#111;\">
<div style=\"border:2px solid #000; padding:10px 12px; margin-bottom:8px;\">
<div style=\"margin-left:6px;\">
$formattedLines
</div>
</div>
</div>
""";
  }

  void _addItem() {
    setState(() {
      quotationItems.add(QuotationItemRow());
    });
  }

  void _removeItem(int index) {
    if (quotationItems.length > 1) {
      setState(() {
        quotationItems[index].dispose();
        quotationItems.removeAt(index);
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveQuotation() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isUploading = true;
      });

      try {
        List<Map<String, dynamic>> itemsList = [];
        double grandTotal = 0;

        for (var item in quotationItems) {
          double qty = double.tryParse(item.quantityController.text) ?? 0;
          double rate = double.tryParse(item.rateController.text) ?? 0;
          double amt = qty * rate;
          
          double instQty = double.tryParse(item.installQtyController.text) ?? 0;
          double instRate = double.tryParse(item.installRateController.text) ?? 0;
          double instAmt = instQty * instRate;

          double itemTotal = amt + instAmt;
          grandTotal += itemTotal;

          itemsList.add({
            'brand': item.brand == 'Select Brand' ? '' : item.brand,
            'product': item.product == 'Select Product' ? '' : item.product,
            'sub_product': item.subProduct == 'Select Sub Product' ? '' : item.subProduct,
            'desc': item.descriptionController.text,
            'spec_image': [],
            'unit': item.unit == 'Select Unit' ? '' : item.unit,
            'qty': item.quantityController.text,
            'rate': item.rateController.text,
            'amt': amt.toStringAsFixed(2),
            'inst_unit': item.installUnit == 'Select Unit' ? '' : item.installUnit,
            'inst_qty': item.installQtyController.text,
            'inst_rate': item.installRateController.text,
            'inst_amt': instAmt.toStringAsFixed(2),
            'total': itemTotal.toStringAsFixed(2),
          });
        }

        final Map<String, dynamic> requestData = {
          "quote_id": "",
          "quote_no": _quoteNoController.text.trim(),
          "name": _clientNameController.text.trim(),
          "project": _projectNameController.text.trim(),
          "date": "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}",
          "city": _cityController.text.trim(),
          "branch": _selectedBranch == 'Select Branch' ? '' : _selectedBranch,
          "status": "draft",
          "type": _quotationCategory.toLowerCase(),
          "revise": "No",
          "admin_approval": "No",
          "rate_approval": _role.toLowerCase().contains('admin') ? 'Yes' : 'No',
          "items": itemsList,
          "total": grandTotal.toStringAsFixed(2),
          "role": _role,
          "emp": _empId,
          "subject": _subjectController.text.trim(),
          "kind_attention": _kindAttentionController.text.trim(),
          "type_of_quote": _quoteType,
          "assigned_by": _selectedAssignedBy == 'Select Employee' ? '' : _selectedAssignedBy,
          "terms": _wrapTermsWithHtml(_termsController.text.trim()),
          "image": null,
          "work_order_id": null,
          "emp_approval": null,
          "work_id": "",
        };

        final response = await http.post(
          Uri.parse("https://nlfs.in/erp/index.php/Nlf_Erp/add_quotation"),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(requestData),
        );

        if (response.statusCode == 200) {
          final Map<String, dynamic> result = json.decode(response.body);
          if (result['status'] == true || result['status'] == 'true' || result['success'] == '1' || result['success'] == 1) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(result['message'] ?? 'Quotation inserted successfully'), backgroundColor: Colors.green),
            );
            Navigator.pop(context);
          } else {
            throw Exception(result['message'] ?? 'Failed to add quotation');
          }
        } else {
          throw Exception('Server error: ${response.statusCode}');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      } finally {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Create Quotation",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontFamily: 'serif',
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 50,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Quote Type & Category Selection
              _buildSelectionSection(),
              const SizedBox(height: 24),

              // New Quotation Section
              _buildSectionHeader('Quotation Details'),
              const SizedBox(height: 16),
              _buildQuotationDetailsForm(),
              const SizedBox(height: 32),

              // Quotation Items Section
              _buildSectionHeader('Quotation Items'),
              const SizedBox(height: 16),
              ...quotationItems.asMap().entries.map((entry) {
                return _buildItemCard(entry.value, entry.key);
              }),

              const SizedBox(height: 16),
              _buildAddItemButton(),
              const SizedBox(height: 32),

              // Terms & Conditions Section
              _buildSectionHeader('Terms & Conditions'),
              const SizedBox(height: 16),
              _buildInputField(_termsController, 'Terms & Conditions', 'Enter terms and conditions', Icons.gavel_outlined, maxLines: 10),
              const SizedBox(height: 40),

              // Footer Actions
              _buildFooterActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quote Type',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'serif'),
          ),
          Row(
            children: [
              _buildRadioOption('Lead', _quoteType, (val) => setState(() => _quoteType = val!)),
              _buildRadioOption('New', _quoteType, (val) => setState(() => _quoteType = val!)),
            ],
          ),
          const Divider(height: 24),
          const Text(
            'Quotation Category',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'serif'),
          ),
          Row(
            children: [
              _buildRadioOption('Regular', _quotationCategory, (val) {
                setState(() => _quotationCategory = val!);
                _fetchNextQuoteNo();
              }),
              _buildRadioOption('Furniture', _quotationCategory, (val) {
                setState(() => _quotationCategory = val!);
                _fetchNextQuoteNo();
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRadioOption(String value, String groupValue, ValueChanged<String?> onChanged) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Radio<String>(
          value: value,
          groupValue: groupValue,
          onChanged: onChanged,
          activeColor: AppColors.primaryText,
        ),
        Text(value, style: const TextStyle(fontFamily: 'serif')),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildQuotationDetailsForm() {
    return Column(
      children: [
        _buildInputField(_quoteNoController, 'Quote No.', 'Enter quote number', Icons.tag),
        const SizedBox(height: 16),
        _buildDateField(),
        const SizedBox(height: 16),
        _buildInputField(_clientNameController, 'Client Name*', 'Enter client name', Icons.person_outline, required: true),
        const SizedBox(height: 16),
        _buildInputField(_cityController, 'City*', 'Enter city', Icons.location_city, required: true),
        const SizedBox(height: 16),
        _buildInputField(_projectNameController, 'Project Name*', 'Enter project name', Icons.business, required: true),
        const SizedBox(height: 16),
        _buildDropdownField('Branch*', _branchesList, (val) => setState(() => _selectedBranch = val), value: _selectedBranch),
        const SizedBox(height: 16),
        _buildDropdownField('Assigned By', _assignedByList, (val) => setState(() => _selectedAssignedBy = val), value: _selectedAssignedBy),
        const SizedBox(height: 16),
        _buildInputField(_kindAttentionController, 'Kind Attention', 'Enter name', Icons.contact_mail_outlined),
        const SizedBox(height: 16),
        _buildInputField(_subjectController, 'Subject*', 'Enter subject', Icons.subject, required: true),
      ],
    );
  }

  Widget _buildItemCard(QuotationItemRow item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Item #${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
              if (quotationItems.length > 1)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  onPressed: () => _removeItem(index),
                ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Dropdowns Row
          _buildDropdownField('Brand*', _brandsList, (val) {
            setState(() {
              item.brand = val!;
              item.product = 'Select Product';
              item.subProduct = 'Select Sub Product';
              item.descriptionController.clear();
            });
          }, value: item.brand),
          const SizedBox(height: 16),
          _buildDropdownField('Product*', _getProductsForBrand(item.brand), (val) {
            setState(() {
              item.product = val!;
              item.subProduct = 'Select Sub Product';
              item.descriptionController.clear();
            });
          }, value: item.product),
          const SizedBox(height: 16),
          _buildDropdownField('Sub Product*', _getSubProductsForProduct(item.brand, item.product), (val) {
            setState(() {
              item.subProduct = val!;
              if (val != 'Select Sub Product') {
                final subProdData = _allProductsList.firstWhere(
                  (p) => p['brand'] == item.brand && 
                         p['g3_category'] == item.product && 
                         p['item_name'] == val,
                  orElse: () => null,
                );
                if (subProdData != null) {
                  item.descriptionController.text = subProdData['specification'] ?? subProdData['description'] ?? "";
                  
                  // Auto-populate Rate
                  if (subProdData['rate'] != null && subProdData['rate'].toString().isNotEmpty) {
                    item.rateController.text = subProdData['rate'].toString();
                  }
                }
              } else {
                item.descriptionController.clear();
                item.rateController.clear();
              }
            });
          }, value: item.subProduct),
          
          const SizedBox(height: 16),
          _buildInputField(item.descriptionController, 'Description*', 'Enter description', Icons.description_outlined, maxLines: 3, required: true),
          
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildDropdownField('Unit*', _unitsList, (val) {
                setState(() {
                  item.unit = val!;
                  item.installUnit = val; // Sync with Installation Unit
                });
              }, value: item.unit)),
              const SizedBox(width: 12),
              Expanded(child: _buildInputField(item.quantityController, 'Quantity*', '0', Icons.numbers, keyboardType: TextInputType.number, required: true)),
            ],
          ),
          
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildInputField(item.rateController, 'Rate*', '0.00', Icons.currency_rupee, keyboardType: TextInputType.number, required: true)),
              const SizedBox(width: 12),
              Expanded(child: _buildInputField(item.amountController, 'Amount*', '0.00', Icons.payments_outlined, keyboardType: TextInputType.number, required: true, readOnly: true)),
            ],
          ),

          // Installation Section (Only if Regular)
          if (_quotationCategory == 'Regular') ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(),
            ),
            const Text(
              'Installation Details',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.orange, fontFamily: 'serif'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildDropdownField('Unit', _unitsList, (val) => setState(() => item.installUnit = val!), value: item.installUnit)),
                const SizedBox(width: 12),
                Expanded(child: _buildInputField(item.installQtyController, 'Quantity', '0', Icons.numbers, keyboardType: TextInputType.number)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildInputField(item.installRateController, 'Rate', '0.00', Icons.currency_rupee, keyboardType: TextInputType.number)),
                const SizedBox(width: 12),
                Expanded(child: _buildInputField(item.installAmountController, 'Amount', '0.00', Icons.payments_outlined, keyboardType: TextInputType.number, readOnly: true)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputField(
    TextEditingController controller,
    String label,
    String placeholder,
    IconData icon, {
    bool required = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          readOnly: readOnly,
          style: const TextStyle(fontSize: 14, color: Colors.black, fontFamily: 'serif'),
          decoration: InputDecoration(
            labelText: label.replaceAll('*', ''),
            labelStyle: const TextStyle(color: AppColors.greyText, fontSize: 13, fontFamily: 'serif'),
            floatingLabelBehavior: FloatingLabelBehavior.auto,
            hintText: placeholder,
            hintStyle: const TextStyle(color: AppColors.greyText, fontSize: 14, fontFamily: 'serif', fontWeight: FontWeight.normal),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.lightGrey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.lightGrey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.secondaryText),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          validator: required ? (value) => (value == null || value.isEmpty) ? 'Field required' : null : null,
        ),
      ],
    );
  }

  Widget _buildDropdownField(String label, List<String> items, ValueChanged<String?> onChanged, {String? value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 14, fontFamily: 'serif')))).toList(),
          onChanged: onChanged,
          value: value ?? (items.isNotEmpty ? items.first : null),
          decoration: InputDecoration(
            labelText: label.replaceAll('*', ''),
            labelStyle: const TextStyle(color: AppColors.greyText, fontSize: 13, fontFamily: 'serif'),
            floatingLabelBehavior: FloatingLabelBehavior.auto,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.lightGrey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.lightGrey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.secondaryText),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          validator: (val) => (label.contains('*') && (val == null || val.contains('Select'))) ? 'Please select $label' : null,
        ),
      ],
    );
  }

  Widget _buildDateField() {
    return GestureDetector(
      onTap: () => _selectDate(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Date', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black, fontFamily: 'serif')),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.lightGrey),
            ),
            child: Row(
              children: [
                Text(
                  "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
                  style: const TextStyle(fontSize: 14, fontFamily: 'serif'),
                ),
                const Spacer(),
                const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.greyText),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(width: 4, height: 16, color: Colors.blue),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'serif'),
        ),
      ],
    );
  }

  Widget _buildAddItemButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _addItem,
        icon: const Icon(Icons.add, size: 18),
        label: const Text('Add Item', style: TextStyle(fontFamily: 'serif')),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.blue,
          side: const BorderSide(color: Colors.blue),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildFooterActions() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _isUploading ? null : _saveQuotation,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryText,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: _isUploading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Save Quotation', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'serif')),
          ),
        ),
      ],
    );
  }
}

class QuotationItemRow {
  String brand = 'Select Brand';
  String product = 'Select Product';
  String subProduct = 'Select Sub Product';
  String unit = 'Select Unit';
  String installUnit = 'Select Unit';
  
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController rateController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  
  final TextEditingController installQtyController = TextEditingController();
  final TextEditingController installRateController = TextEditingController();
  final TextEditingController installAmountController = TextEditingController();

  QuotationItemRow() {
    quantityController.addListener(_onQuantityChanged);
    rateController.addListener(_calculateAmount);
    installQtyController.addListener(_calculateInstallationAmount);
    installRateController.addListener(_calculateInstallationAmount);
  }

  void _onQuantityChanged() {
    // Sync main quantity to installation quantity
    if (installQtyController.text != quantityController.text) {
      installQtyController.text = quantityController.text;
    }
    _calculateAmount();
  }

  void _calculateAmount() {
    double qty = double.tryParse(quantityController.text) ?? 0;
    double rate = double.tryParse(rateController.text) ?? 0;
    String result = (qty * rate).toStringAsFixed(2);
    if (amountController.text != result) {
      amountController.text = result;
    }
  }

  void _calculateInstallationAmount() {
    double qty = double.tryParse(installQtyController.text) ?? 0;
    double rate = double.tryParse(installRateController.text) ?? 0;
    String result = (qty * rate).toStringAsFixed(2);
    if (installAmountController.text != result) {
      installAmountController.text = result;
    }
  }

  void dispose() {
    descriptionController.dispose();
    quantityController.dispose();
    rateController.dispose();
    amountController.dispose();
    installQtyController.dispose();
    installRateController.dispose();
    installAmountController.dispose();
  }
}
