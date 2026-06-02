import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> with TickerProviderStateMixin {
  int _currentStep = 1;
  bool _isLoadingBrands = false;
  bool _isLoadingUnits = false;
  bool _isLoadingSubProducts = false;
  bool _isSavingProduct = false;
  String? _imagePath;
  XFile? _pickedFile;

  final TextEditingController _brandNameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _subProductNameController = TextEditingController();
  final TextEditingController _rateController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String? _selectedUnit;
  String? _selectedUnitId;
  String _selectedBrand = "";

  late TabController _step1TabController;
  late TabController _step2TabController;

  List<String> _allBrands = [];
  List<String> _filteredBrands = [];
  Map<String, String> _brandNameToId = {};
  List<Map<String, String>> _units = [];
  List<dynamic> _allSubProducts = [];

  @override
  void initState() {
    super.initState();
    _step1TabController = TabController(length: 2, vsync: this);
    _step2TabController = TabController(length: 2, vsync: this);

    // ✅ Listen to tab changes to refresh existing products list
    _step2TabController.addListener(_onStep2TabChanged);
    _step1TabController.addListener(() {
      if (!_step1TabController.indexIsChanging && mounted) {
        setState(() {});
      }
    });

    _fetchBrands();
    _fetchUnits();
    _fetchSubProducts();
    _searchController.addListener(_onSearchChanged);
  }

  // ✅ New: Refresh sub-products when switching to "Use Existing Product" tab
  void _onStep2TabChanged() {
    if (_step2TabController.indexIsChanging) return; // Only act on final tab change

    if (_step2TabController.index == 1 && _selectedBrand.isNotEmpty && mounted) {
      // User switched to "Use Existing Product" tab - refresh the list
      _fetchSubProducts();
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _step2TabController.removeListener(_onStep2TabChanged);
    _step1TabController.dispose();
    _step2TabController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _brandNameController.dispose();
    _productNameController.dispose();
    _subProductNameController.dispose();
    _rateController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _filteredBrands = _allBrands
          .where((brand) => brand.toLowerCase().contains(_searchController.text.toLowerCase()))
          .toList();
    });
  }

  Future<void> _fetchBrands() async {
    setState(() => _isLoadingBrands = true);
    try {
      final response = await http.get(Uri.parse(AppConstants.SUB_PRODUCT_LIST_API));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data[AppConstants.SUCCESS] == "1") {
          final List<dynamic> brandData = data[AppConstants.DATA];
          final Map<String, String> brandMap = {};
          for (final item in brandData) {
            final String brandName = (item['brand'] ?? '').toString().trim();
            final String brandId = (item['id'] ?? '').toString().trim();
            if (brandName.isNotEmpty && !brandMap.containsKey(brandName)) {
              brandMap[brandName] = brandId;
            }
          }
          setState(() {
            _brandNameToId = brandMap;
            _allBrands = brandMap.keys.toList()..sort();
            _filteredBrands = _allBrands;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching brands: $e");
    } finally {
      if (mounted) setState(() => _isLoadingBrands = false);
    }
  }

  Future<void> _fetchUnits() async {
    setState(() => _isLoadingUnits = true);
    try {
      final response = await http.get(Uri.parse(AppConstants.UNIT_LIST_API));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data[AppConstants.SUCCESS] == "1") {
          final List<dynamic> unitData = data[AppConstants.DATA];
          final Map<String, String> uniqueUnits = {};
          for (var item in unitData) {
            String name = (item['unit'] ?? '').toString().trim();
            String id = (item['unit_id'] ?? '').toString();
            if (name.isNotEmpty && !uniqueUnits.containsKey(name)) {
              uniqueUnits[name] = id;
            }
          }
          setState(() {
            _units = uniqueUnits.entries
                .map((e) => {'id': e.value, 'name': e.key})
                .toList()
              ..sort((a, b) => a['name']!.compareTo(b['name']!));
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching units: $e");
    } finally {
      if (mounted) setState(() => _isLoadingUnits = false);
    }
  }

  Future<void> _fetchSubProducts() async {
    // Only fetch if we have a selected brand
    if (_selectedBrand.isEmpty) return;

    setState(() => _isLoadingSubProducts = true);
    try {
      final response = await http.get(Uri.parse(AppConstants.SUB_PRODUCT_LIST_API));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data[AppConstants.SUCCESS] == "1") {
          setState(() => _allSubProducts = data[AppConstants.DATA] ?? []);
        }
      }
    } catch (e) {
      debugPrint("Error fetching sub-products: $e");
    } finally {
      if (mounted) setState(() => _isLoadingSubProducts = false);
    }
  }

  Future<void> _deleteBrand(String brandName, String id) async {
    bool confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete', style: TextStyle(fontFamily: 'serif', fontWeight: FontWeight.w600)),
        content: const Text('Are you sure you want to delete this brand?', style: TextStyle(fontFamily: 'serif')),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(fontFamily: 'serif', color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryText,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete', style: TextStyle(fontFamily: 'serif')),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    try {
      final response = await http.post(
        Uri.parse(AppConstants.DELETE_SUB_PRODUCT_API),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': id}),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data[AppConstants.SUCCESS] == "1") {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data[AppConstants.MESSAGE] ?? 'Deleted successfully', style: const TextStyle(fontFamily: 'serif')),
              backgroundColor: Colors.green,
            ),
          );
          if (_selectedBrand == brandName) setState(() => _selectedBrand = "");
          _fetchBrands();
          // Also refresh sub-products if we're on step 2
          if (_currentStep == 2) _fetchSubProducts();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data[AppConstants.MESSAGE] ?? 'Failed to delete', style: const TextStyle(fontFamily: 'serif')),
              backgroundColor: AppColors.primaryText,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Error deleting brand: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e', style: const TextStyle(fontFamily: 'serif')), backgroundColor: AppColors.primaryText),
      );
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _pickedFile = image;
        _imagePath = image.path;
      });
    }
  }

  void _proceedToStep2() {
    String brand = _step1TabController.index == 0 ? _brandNameController.text.trim() : _selectedBrand;
    if (brand.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select or enter a brand name")));
      return;
    }
    setState(() {
      _selectedBrand = brand;
      _currentStep = 2;
    });
    // ✅ Fetch sub-products when entering Step 2 with a selected brand
    _fetchSubProducts();
  }

  Future<void> _addProduct() async {
    if (_productNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter product name')));
      return;
    }
    if (_rateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter rate'), backgroundColor: AppColors.primaryText));
      return;
    }
    if (_selectedUnit == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a unit'), backgroundColor: AppColors.primaryText));
      return;
    }
   /* if (_imagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a sub-product image', style: TextStyle(fontFamily: 'serif')), backgroundColor: AppColors.primaryText),
      );
      return;
    }*/

    setState(() => _isSavingProduct = true);

    try {
      var request = http.MultipartRequest('POST', Uri.parse(AppConstants.ADD_PRODUCT_MST_API));
      
      // Use exact fields from lib_old
      request.fields['brand'] = _selectedBrand;
      request.fields['g3_category'] = _productNameController.text.trim();
      request.fields['g4_sub_category'] = _subProductNameController.text.trim();
      request.fields['qty'] = "1";
      request.fields['uom'] = _selectedUnit ?? "";
      request.fields['rate'] = _rateController.text.trim();
      request.fields['specification'] = _descriptionController.text.trim();
      request.fields['gst'] = "";
      request.fields['hsn_code'] = "";
      request.fields['is_deleted'] = "";
      request.fields['unit'] = _selectedUnit ?? "";

      if (_pickedFile != null && _imagePath != null) {
        if (kIsWeb) {
          var bytes = await _pickedFile!.readAsBytes();
          request.files.add(http.MultipartFile.fromBytes('image[]', bytes, filename: _pickedFile!.name));
        } else {
          request.files.add(await http.MultipartFile.fromPath('image[]', _imagePath!));
        }
      }

      var streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      var response = await http.Response.fromStream(streamedResponse);
      var responseData = response.body;

      debugPrint("Status Code: ${response.statusCode}");
      debugPrint("API Response: $responseData");

      if (responseData.isEmpty) {
        if (response.statusCode == 200) {
           // Some servers return empty body on success
           _handleSuccess();
           return;
        }
        throw Exception("Server returned an empty response (Status: ${response.statusCode})");
      }

      dynamic result;
      try {
        result = json.decode(responseData);
      } catch (e) {
        debugPrint("JSON Decode Error: $e");
        // If status is 200, maybe it's not JSON but worked? 
        // But usually it should be JSON.
        if (response.statusCode == 200) {
           _handleSuccess();
           return;
        }
        throw Exception("Invalid server response format. Status: ${response.statusCode}");
      }

      if (response.statusCode == 200 && (result['status'] == true || result['status'] == 'true' || result['success'] == '1' || result['success'] == 1)) {
        _handleSuccess();
      } else {
        String errorMessage = result['message'] ?? 'Failed to add product';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage, style: const TextStyle(fontFamily: 'serif')), backgroundColor: AppColors.primaryText),
        );
      }
    } catch (e) {
      debugPrint("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding product: $e', style: const TextStyle(fontFamily: 'serif')), backgroundColor: AppColors.primaryText),
      );
    } finally {
      if (mounted) setState(() => _isSavingProduct = false);
    }
  }

  void _handleSuccess() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Product added successfully!', style: TextStyle(fontFamily: 'serif')),
        backgroundColor: Colors.green,
      ),
    );

    _productNameController.clear();
    _subProductNameController.clear();
    _rateController.clear();
    _descriptionController.clear();
    setState(() {
      _pickedFile = null;
      _imagePath = null;
      _selectedUnit = null;
      _selectedUnitId = null;
    });

    // Redirect to "Use Existing Product" tab and refresh list
    if (_step2TabController.index != 1) {
      _step2TabController.animateTo(1, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
    _fetchBrands();
    _fetchSubProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            if (_currentStep == 2) {
              setState(() => _currentStep = 1);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text('Products', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontFamily: 'serif', fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 40,
        titleSpacing: 0,
      ),
      body: SafeArea(child: _currentStep == 1 ? _buildStep1() : _buildStep2()),
    );
  }

  Widget _buildStep1() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          _buildStep1Toggle(),
          const SizedBox(height: 10),
          if (_step1TabController.index == 1) ...[
            _buildSearchField(),
            const SizedBox(height: 24),
          ] else const SizedBox(height: 14),
          Expanded(
            child: _step1TabController.index == 0
                ? _buildCreateBrandView()
                : _isLoadingBrands
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryText))
                : _buildExistingBrandListView(),
          ),
          const SizedBox(height: 16),
          _buildActionButton("Save and Proceed", _proceedToStep2),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Step 2: Products & Sub-Products', style: TextStyle(fontFamily: 'serif', fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w400)),
          const SizedBox(height: 24),
          Row(
            children: [
              const Text('Brand: ', style: TextStyle(fontFamily: 'serif', fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20)),
                child: Text(_selectedBrand, style: const TextStyle(fontFamily: 'serif', fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildStep2Toggle(),
          const SizedBox(height: 32),
          if (_step2TabController.index == 0) ...[
            _buildInputField("Product Name", "Enter product name", _productNameController),
            const SizedBox(height: 20),
            _buildInputField("Sub-Product Name", "Enter sub-product name", _subProductNameController),
            const SizedBox(height: 20),
            _buildImagePickerField(),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _buildInputField("Rate", "Rate", _rateController)),
                const SizedBox(width: 16),
                Expanded(child: _buildDropdownField("Unit", "Select Unit")),
              ],
            ),
            const SizedBox(height: 20),
            _buildInputField("Description", "Description", _descriptionController, maxLines: 4),
            const SizedBox(height: 32),
            _buildSaveAllButton(),
          ] else
            _buildExistingSubProductsList(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      height: 50,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: AppColors.primaryText, width: 1.5)),
      child: Row(
        children: [
          const SizedBox(width: 15),
          const Icon(Icons.search, color: AppColors.primaryText, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(fontFamily: 'serif', fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search brands...',
                hintStyle: const TextStyle(fontFamily: 'serif', color: Colors.grey, fontSize: 14),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 15),
        ],
      ),
    );
  }

  Widget _buildStep1Toggle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey[300]!, width: 1)),
      child: TabBar(
        controller: _step1TabController,
        indicator: BoxDecoration(color: AppColors.primaryText, borderRadius: BorderRadius.circular(10)),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[800],
        tabs: const [Tab(text: 'Create New Brand'), Tab(text: 'Use Existing Brand')],
        labelStyle: const TextStyle(fontFamily: 'serif', fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontFamily: 'serif'),
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildStep2Toggle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey[300]!, width: 1)),
      child: TabBar(
        controller: _step2TabController,
        indicator: BoxDecoration(color: AppColors.primaryText, borderRadius: BorderRadius.circular(10)),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[800],
        tabs: const [Tab(text: 'Create New Products'), Tab(text: 'Use Existing Product')],
        labelStyle: const TextStyle(fontFamily: 'serif', fontWeight: FontWeight.bold),
        unselectedLabelStyle: const TextStyle(fontFamily: 'serif'),
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildCreateBrandView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const Text('Brand Name', style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w500, fontFamily: 'serif')),
        const SizedBox(height: 4),
        TextFormField(
          controller: _brandNameController,
          style: const TextStyle(color: Colors.black, fontFamily: 'serif'),
          decoration: InputDecoration(
            labelText: 'Brand Name',
            labelStyle: const TextStyle(color: AppColors.greyText, fontFamily: 'serif'),
            prefixIcon: const Icon(Icons.business, color: AppColors.greyText),
            hintText: 'Enter Brand Name',
            hintStyle: const TextStyle(color: AppColors.greyText, fontFamily: 'serif'),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightGrey)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.secondaryText)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildExistingBrandListView() {
    if (_filteredBrands.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text('No brands found', style: TextStyle(fontFamily: 'serif', color: Color(0xFF94A3B8), fontSize: 16)),
          ],
        ),
      );
    }
    return ListView.separated(
      itemCount: _filteredBrands.length,
      padding: const EdgeInsets.only(bottom: 20),
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final String brand = _filteredBrands[index];
        bool isSelected = _selectedBrand == brand;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryText.withOpacity(0.04) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isSelected ? AppColors.primaryText : const Color(0xFFF1F5F9), width: isSelected ? 2 : 1),
            boxShadow: [BoxShadow(color: isSelected ? AppColors.primaryText.withOpacity(0.1) : Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => setState(() => _selectedBrand = brand),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        brand,
                        style: TextStyle(fontFamily: 'serif', fontSize: 16, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600, color: isSelected ? AppColors.primaryText : const Color(0xFF0F172A)),
                      ),
                    ),
                    if (isSelected)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: AppColors.primaryText, shape: BoxShape.circle),
                        child: const Icon(Icons.check, color: Colors.white, size: 16),
                      )
                    else
                      IconButton(
                        icon: const Icon(Icons.delete, color:Colors.red, size: 24),
                        onPressed: () {
                          final brandId = _brandNameToId[brand];
                          if (brandId != null && brandId.isNotEmpty) {
                            _deleteBrand(brand, brandId);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cannot delete: Missing ID'), backgroundColor: Colors.red));
                          }
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildExistingSubProductsList() {
    // ✅ Show loading only when actually fetching (not just empty list)
    if (_isLoadingSubProducts && _allSubProducts.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(color: AppColors.primaryText),
        ),
      );
    }

    // Filter products by selected brand
    final brandSubProducts = _allSubProducts
        .where((p) => (p['brand'] ?? '').toString().toLowerCase() == _selectedBrand.toLowerCase())
        .toList();

    if (brandSubProducts.isEmpty) {
      return Center(
        child: Column(
          children: [
            const SizedBox(height: 40),
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text(
              'No existing products found for this brand',
              style: TextStyle(fontFamily: 'serif', color: Color(0xFF94A3B8), fontSize: 15),
            ),
            // ✅ Add a refresh button for manual reload
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _fetchSubProducts,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Refresh List', style: TextStyle(fontFamily: 'serif')),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryText,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: brandSubProducts.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final product = brandSubProducts[index];
        final String prodName = product['g3_category']?.toString() ?? '';
        final String subProdName = product['g4_sub_category']?.toString() ?? '';
        final String uom = product['uom']?.toString() ?? '';
        final String rate = product['rate']?.toString() ?? '';
        final String spec = product['specification']?.toString() ?? '';

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.inventory_2, color: Colors.brown, size: 25),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prodName.isEmpty ? 'Unknown Product' : prodName,
                        style: const TextStyle(fontFamily: 'serif', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                      ),
                      if (subProdName.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subProdName,
                          style: TextStyle(fontFamily: 'serif', fontSize: 14, color: Colors.grey[800]),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (rate.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Rate: ₹$rate',
                                style:  TextStyle(fontFamily: 'serif', fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey[600]),
                              ),
                            ),
                          if (rate.isNotEmpty && uom.isNotEmpty) const SizedBox(width: 8),
                          if (uom.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primaryText.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Unit: $uom',
                                style: const TextStyle(fontFamily: 'serif', fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.primaryText),
                              ),
                            ),
                        ],
                      ),
                      if (spec.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          spec,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontFamily: 'serif', fontSize: 13, color: Colors.grey[800], height: 1.4),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputField(String label, String hint, TextEditingController controller, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w500, fontFamily: 'serif')),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.black, fontFamily: 'serif'),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: AppColors.greyText, fontFamily: 'serif'),
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.greyText, fontFamily: 'serif'),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightGrey)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.secondaryText)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePickerField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Sub-Product Image", style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w500, fontFamily: 'serif')),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          height: 100,
          decoration: BoxDecoration(color: Colors.transparent, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.lightGrey)),
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Container(
                margin: const EdgeInsets.only(right: 12),
                child: ElevatedButton(
                  onPressed: _pickImage,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[200], foregroundColor: Colors.black, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  child: const Text("Choose File", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'serif')),
                ),
              ),
              Expanded(
                child: _imagePath != null
                    ? Row(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: kIsWeb ? NetworkImage(_imagePath!) as ImageProvider : FileImage(File(_imagePath!)),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _imagePath!.split('/').last,
                        style: const TextStyle(color: Colors.black, fontSize: 13, fontFamily: 'serif'),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                )
                    : const Text("No file chosen", style: TextStyle(color: AppColors.greyText, fontSize: 13, fontFamily: 'serif')),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(String label, String hint, {String? value, ValueChanged<String?>? onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w500, fontFamily: 'serif')),
        const SizedBox(height: 4),
        _isLoadingUnits
            ? Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.lightGrey)),
          child: const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryText)),
        )
            : DropdownButtonFormField<String>(
          value: _selectedUnitId,
          hint: Text(hint, style: const TextStyle(color: AppColors.greyText, fontFamily: 'serif')),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.greyText),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: AppColors.greyText, fontFamily: 'serif'),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightGrey)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.secondaryText)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          items: _units.map((unit) {
            return DropdownMenuItem<String>(value: unit['id'], child: Text(unit['name']!, style: const TextStyle(color: Colors.black, fontFamily: 'serif')));
          }).toList(),
          onChanged: (val) {
            setState(() {
              _selectedUnitId = val;
              _selectedUnit = _units.firstWhere((u) => u['id'] == val)['name'];
            });
          },
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, VoidCallback onPressed) {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(2)),
      child: ElevatedButton(onPressed: onPressed, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryText, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)), elevation: 0), child: Text(label, style: const TextStyle(fontFamily: 'serif', fontSize: 16, fontWeight: FontWeight.bold))),
    );
  }

  Widget _buildSaveAllButton() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _isSavingProduct ? null : _addProduct,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryText, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
              child: _isSavingProduct
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                  : const Text("Save", style: TextStyle(fontFamily: 'serif', fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 1,
          child: SizedBox(
            height: 48,
            child: OutlinedButton(
              onPressed: () {
                if (_currentStep == 2) {
                  setState(() => _currentStep = 1);
                } else {
                  Navigator.pop(context);
                }
              },
              style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF64748B), side: const BorderSide(color: Color(0xFF64748B), width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text("Cancel", style: TextStyle(fontFamily: 'serif', fontSize: 16, fontWeight: FontWeight.w500)),
            ),
          ),
        ),
      ],
    );
  }
}