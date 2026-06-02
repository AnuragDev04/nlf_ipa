import 'package:flutter/material.dart';
import 'package:nlf/utils/colors.dart';

class MaterialScreen extends StatefulWidget {
  const MaterialScreen({super.key});

  @override
  _MaterialScreenState createState() => _MaterialScreenState();
}

class _MaterialScreenState extends State<MaterialScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<MaterialItem> _materials = [
    MaterialItem(
      name: 'Concrete Mix',
      quantity: 500,
      status: StockStatus.inStock,
    ),
    MaterialItem(
      name: 'Steel Rebar',
      quantity: 100,
      status: StockStatus.lowStock,
    ),
    MaterialItem(name: 'Bricks', quantity: 2000, status: StockStatus.inStock),
    MaterialItem(
      name: 'Cement Bags',
      quantity: 50,
      status: StockStatus.lowStock,
    ),
    MaterialItem(name: 'Sand', quantity: 1000, status: StockStatus.inStock),
    MaterialItem(name: 'Gravel', quantity: 20, status: StockStatus.outOfStock),
  ];

  List<MaterialItem> _filteredMaterials = [];

  @override
  void initState() {
    super.initState();
    _filteredMaterials = _materials;
  }

  void _showAddMaterialBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          AddMaterialBottomSheet(
            onAddMaterial: (name, quantity, unit) {
              setState(() {
                _materials.add(
                  MaterialItem(
                    name: name,
                    quantity: quantity,
                    status: quantity > 100
                        ? StockStatus.inStock
                        : quantity > 50
                        ? StockStatus.lowStock
                        : StockStatus.outOfStock,
                  ),
                );
                _filteredMaterials = _materials; // Update filtered list
              });
            },
          ),
    );
  }

  void _filterMaterials(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredMaterials = _materials;
      } else {
        _filteredMaterials = _materials
            .where(
              (material) =>
              material.name.toLowerCase().contains(query.toLowerCase()),
        )
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          "ALL MATERIALS",
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
      body: Column(
        children: [
          // Header
          SizedBox(height: 5),
          // Search Bar
          Container(
            margin: EdgeInsets.symmetric(horizontal: 10),
            // Set fixed height
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: AppColors.primaryText, width: 1.5),
            ),
            child: Row(
              children: [
                SizedBox(width: 15), // Add some left padding
                Icon(Icons.search, color: AppColors.primaryText, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: _filterMaterials,
                    decoration: InputDecoration(
                      hintText: 'Search by Material name',
                      hintStyle: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 14,
                        fontFamily: 'serif',
                      ),
                      border: InputBorder.none,
                      // Remove content padding from TextField to fit within the container
                      contentPadding: EdgeInsets.zero,
                      isDense: true, // Reduces default padding
                    ),
                  ),
                ),
                SizedBox(width: 15), // Add some right padding
              ],
            ),
          ),

          SizedBox(height: 20),

          // Materials List
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 20),
              itemCount: _filteredMaterials.length,
              itemBuilder: (context, index) {
                return _buildMaterialCard(_filteredMaterials[index], index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialCard(MaterialItem material, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 15), // Reduced margin
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        // ✅ IMPROVED SHADOW - Multiple layers for better visibility
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3), // Darker shadow
            blurRadius: 12, // Increased blur
            offset: Offset(0, 6), // Larger offset
          ),
          BoxShadow(
            color: Colors.grey.withOpacity(0.15), // Additional shadow layer
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
          BoxShadow(
            color: Colors.grey.withOpacity(0.05), // Soft outer shadow
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Material Info - Reduced padding
          Padding(
            padding: EdgeInsets.all(12), // Reduced from 16 to 12
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        material.name,
                        style: TextStyle(
                          fontSize: 16, // Reduced from 18 to 16
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          fontFamily: 'serif',
                        ),
                      ),
                      SizedBox(height: 2), // Reduced spacing
                      Text(
                        'Quantity: ${material.quantity}',
                        style: TextStyle(
                          fontSize: 14, // Reduced from 16 to 14
                          color: Colors.grey[600],
                          fontFamily: 'serif',
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: material.status.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    material.status.label,
                    style: TextStyle(
                      color: material.status.color,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'serif',
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Divider(height: 1, color: Colors.grey[300]),

          // Add Button Row - Reduced padding
          Container(
            padding: EdgeInsets.all(8), // Reduced from 12 to 8
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () {
                    _showAddQuantityDialog(context, material, index);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryText,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    // Reduced padding
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    minimumSize: Size(0, 35), // Reduced button height
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 14), // Reduced icon size
                      SizedBox(width: 4), // Reduced spacing
                      Text(
                        'Add Material',
                        style: TextStyle(
                          fontSize: 12, // Reduced font size
                          fontWeight: FontWeight.bold,
                          fontFamily: 'serif',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddQuantityDialog(BuildContext context,
      MaterialItem material,
      int index,) {
    TextEditingController quantityController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Add Quantity to ${material.name}',
            style: TextStyle(
              fontSize: 16, // Reduced fonts size
              fontWeight: FontWeight.bold,
              fontFamily: 'serif',
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current Quantity: ${material.quantity}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12, // Reduced font size
                  fontFamily: 'serif',
                ),
              ),
              SizedBox(height: 16), // ✅ Increased spacing
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Enter quantity to add',
                  labelStyle: TextStyle(
                    color: Colors.black, // ✅ Black label text
                    fontFamily: 'serif',
                    fontSize: 12, // Reduced font size
                  ),
                  hintText: 'e.g., 100',
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    fontFamily: 'serif',
                    fontSize: 12, // Reduced font size
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Colors.grey, // ✅ Grey focus border
                      width: 2.0,
                    ),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  // Reduced padding
                  constraints: const BoxConstraints(
                    minHeight: 55,
                    maxHeight: 55,
                  ), // ✅ Fixed height
                ),
                style: TextStyle(
                  color: Colors.black, // ✅ Black text
                  fontFamily: 'serif',
                  fontSize: 12, // Reduced font size
                ),
              ),
            ],
          ),
          // ✅ REORDERED ACTIONS - Add Quantity FIRST, then Cancel
          actions: [
            ElevatedButton(
              onPressed: () {
                if (quantityController.text.isNotEmpty) {
                  int addedQuantity =
                      int.tryParse(quantityController.text) ?? 0;
                  if (addedQuantity > 0) {
                    setState(() {
                      // Update the material quantity
                      int originalIndex = _materials.indexWhere(
                            (m) => m.name == material.name,
                      );
                      if (originalIndex != -1) {
                        _materials[originalIndex] = MaterialItem(
                          name: material.name,
                          quantity: material.quantity + addedQuantity,
                          status: material.status,
                        );
                        _filteredMaterials = List.from(
                          _materials,
                        ); // Update filtered list
                      }
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '$addedQuantity added to ${material
                              .name}. New quantity: ${material.quantity +
                              addedQuantity}',
                          style: TextStyle(fontFamily: 'serif'),
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryText,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Add Quantity',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14, // Reduced font size
                  fontWeight: FontWeight.bold,
                  fontFamily: 'serif',
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontFamily: 'serif',
                  fontSize: 14, // Reduced font size
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class AddMaterialBottomSheet extends StatefulWidget {
  final Function(String name, int quantity, String unit) onAddMaterial;

  const AddMaterialBottomSheet({super.key, required this.onAddMaterial});

  @override
  State<AddMaterialBottomSheet> createState() => _AddMaterialBottomSheetState();
}

class _AddMaterialBottomSheetState extends State<AddMaterialBottomSheet> {
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  String _selectedUnit = 'sqm';

  final List<String> _units = ['sqm', 'kg', 'tons', 'pcs', 'bags', 'cubic m'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery
            .of(context)
            .viewInsets
            .bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'Add Material',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            // Form
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Material Description',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'e.g., Concrete Blocks',
                      labelStyle: TextStyle(
                        color: Colors.black, // ✅ Black label text
                        fontFamily: 'serif',
                      ),
                      hintText: 'Enter material description',
                      hintStyle: TextStyle(
                        color: Colors.grey[400],
                        fontFamily: 'serif',
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.grey, // ✅ Grey focus border
                          width: 2.0,
                        ),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      constraints: const BoxConstraints(
                        minHeight: 55,
                        maxHeight: 55,
                      ), // ✅ Fixed height
                    ),
                    style: TextStyle(
                      color: Colors.black, // ✅ Black text
                      fontFamily: 'serif',
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Unit dropdown
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Unit',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _selectedUnit,
                                  isExpanded: true,
                                  icon: const Icon(Icons.keyboard_arrow_down),
                                  items: _units.map((String unit) {
                                    return DropdownMenuItem<String>(
                                      value: unit,
                                      child: Text(
                                        unit,
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      _selectedUnit = newValue!;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Quantity field
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Quantity',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _quantityController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Enter quantity',
                                labelStyle: TextStyle(
                                  color: Colors.black, // ✅ Black label text
                                  fontFamily: 'serif',
                                ),
                                hintText: '0',
                                hintStyle: TextStyle(
                                  color: Colors.grey[400],
                                  fontFamily: 'serif',
                                ),
                                filled: true,
                                fillColor: Colors.grey[100],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey[300]!,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Colors.grey, // ✅ Grey focus border
                                    width: 2.0,
                                  ),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                                constraints: const BoxConstraints(
                                  minHeight: 55,
                                  maxHeight: 55,
                                ), // ✅ Fixed height
                              ),
                              style: TextStyle(
                                color: Colors.black, // ✅ Black text
                                fontFamily: 'serif',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Add Material Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_descriptionController.text.isNotEmpty &&
                            _quantityController.text.isNotEmpty) {
                          widget.onAddMaterial(
                            _descriptionController.text,
                            int.tryParse(_quantityController.text) ?? 0,
                            _selectedUnit,
                          );
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0BA7E8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Add Material',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _quantityController.dispose();
    super.dispose();
  }
}

class MaterialItem {
  final String name;
  final int quantity;
  final StockStatus status;

  MaterialItem({
    required this.name,
    required this.quantity,
    required this.status,
  });
}

enum StockStatus { inStock, lowStock, outOfStock }

extension StockStatusExtension on StockStatus {
  String get label {
    switch (this) {
      case StockStatus.inStock:
        return 'In Stock';
      case StockStatus.lowStock:
        return 'Low Stock';
      case StockStatus.outOfStock:
        return 'Out of Stock';
    }
  }

  Color get color {
    switch (this) {
      case StockStatus.inStock:
        return Colors.green;
      case StockStatus.lowStock:
        return Colors.orange;
      case StockStatus.outOfStock:
        return Colors.red;
    }
  }
}
