import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:nlf/pages/delivery_memo_direct_add_screen.dart';
import 'package:nlf/pages/po_direct_add_screen.dart';
import 'package:nlf/utils/colors.dart';
import 'package:nlf/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AnnexureScreen extends StatefulWidget {
  const AnnexureScreen({super.key});

  @override
  _AnnexureScreenState createState() => _AnnexureScreenState();
}

class _AnnexureScreenState extends State<AnnexureScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();

  List<AnnexurePOItem> allItems = [];
  List<AnnexurePOItem> filteredItems = [];

  bool _isLoading = true;
  bool _showDebugInfo = false;
  DateTime? _fromDate;
  DateTime? _toDate;
  String? _apiErrorMessage;
  String? _rawApiResponse;

  @override
  void initState() {
    super.initState();
    _loadAnnexurePOData();
  }

  final String apiUrl = AppConstants.ANNEXTURE_PURCHASE_ORDER_LIST_API;

  // ✅ Sorting Logic: Descending order by ID (Latest on top)
  void _sortItemsById(List<AnnexurePOItem> itemsList) {
    itemsList.sort((a, b) {
      int idA = int.tryParse(a.id.isNotEmpty ? a.id : '0') ?? 0;
      int idB = int.tryParse(b.id.isNotEmpty ? b.id : '0') ?? 0;
      return idB.compareTo(idA); // Descending: Higher ID first
    });
  }

  static String? _safeGetString(Map<String, dynamic>? map, String key) {
    if (map == null) return null;
    try {
      final value = map[key];
      if (value == null) return null;
      if (value is String) return value.isEmpty ? null : value;
      return value.toString();
    } catch (e) {
      return null;
    }
  }

  static double _safeParseDouble(dynamic value) {
    try {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        final parsed = double.tryParse(value.trim());
        return parsed ?? 0.0;
      }
      return 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  Future<void> _loadAnnexurePOData() async {
    try {
      setState(() {
        _isLoading = true;
        _apiErrorMessage = null;
        _rawApiResponse = null;
        _showDebugInfo = false;
      });

      print('🔍 Fetching from: $apiUrl');

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({}),
      );

      _rawApiResponse = response.body;
      print('📡 Status: ${response.statusCode}');
      print('📦 Raw Response Length: ${response.body.length}');

      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> data = json.decode(response.body);
          print('📊 Decoded Data Keys: ${data.keys.toList()}');

          bool isSuccess = false;
          if (data['status'] == 'true' || data['status'] == true) {
            if (data.containsKey('success')) {
              isSuccess =
              (data['success'] == '1' ||
                  data['success'] == 1 ||
                  data['success'] == true);
            } else if (data.containsKey('count')) {
              isSuccess = true;
            } else {
              isSuccess = true;
            }
          }

          if (isSuccess) {
            dynamic dataContent = data['data'];
            List<dynamic> itemsData = [];

            if (dataContent is List) {
              itemsData = dataContent;
            } else if (dataContent is Map && dataContent['records'] is List) {
              itemsData = dataContent['records'];
            } else if (dataContent != null) {
              itemsData = [dataContent];
            }

            print('📋 Found ${itemsData.length} items in API response');

            if (itemsData.isEmpty) {
              print('⚠️ API returned empty data');
              setState(() {
                allItems = [];
                filteredItems = [];
                _isLoading = false;
              });
              return;
            }

            List<AnnexurePOItem> loadedItems = [];
            int skippedCount = 0;

            for (var item in itemsData) {
              try {
                if (item is! Map<String, dynamic>) {
                  skippedCount++;
                  continue;
                }
                final itemMap = item;

                String displayNumber =
                    _safeGetString(itemMap, 'annexure_no') ??
                        _safeGetString(itemMap, 'po_no') ??
                        '';

                // ✅ Extract row_type and po_approval
                String rowType = _safeGetString(itemMap, 'row_type') ?? '';
                String poApproval =
                    _safeGetString(itemMap, 'po_approval') ?? 'no';

                // ✅ Extract woNumber - if delivery_schedule is null/empty, set to "Direct DM"
                String? rawWoNumber = _safeGetString(itemMap, 'delivery_schedule') ??
                    _safeGetString(itemMap, 'wo_number') ??
                    _safeGetString(itemMap, 'wo_no');
                String woNumber = rawWoNumber?.isEmpty ?? true ? 'Direct DM' : rawWoNumber!;

                loadedItems.add(
                  AnnexurePOItem(
                    id:
                    _safeGetString(itemMap, 'annexure_id') ??
                        _safeGetString(itemMap, 'po_id') ??
                        _safeGetString(itemMap, 'id') ??
                        '',
                    poNumber: displayNumber,
                    projectName:
                    _safeGetString(itemMap, 'project_name') ??
                        _safeGetString(itemMap, 'project') ??
                        _safeGetString(itemMap, 'projectName') ??
                        'N/A',
                    clientName:
                    _safeGetString(itemMap, 'annexure_client_name') ??
                        _safeGetString(itemMap, 'client_name') ??
                        _safeGetString(itemMap, 'clientName') ??
                        _safeGetString(itemMap, 'company') ??
                        '',
                    woNumber: woNumber, // ✅ Use processed woNumber
                    date:
                    _safeGetString(itemMap, 'annexure_date') ??
                        _safeGetString(itemMap, 'date') ??
                        _safeGetString(itemMap, 'created_at') ??
                        '',
                    totalAmount: _safeParseDouble(
                      itemMap['annexure_total_amount'] ??
                          itemMap['total_bal'] ??
                          itemMap['total_amount'] ??
                          itemMap['total_amt'] ??
                          '0',
                    ),
                    dMemo:
                    _safeGetString(itemMap, 'd_memo') ??
                        _safeGetString(itemMap, 'delivery_memo') ??
                        '',
                    annexureStatus:
                    _safeGetString(itemMap, 'annexure_status') ??
                        _safeGetString(itemMap, 'status') ??
                        '',
                    annexureCount:
                    _safeGetString(itemMap, 'annexure_count') ??
                        _safeGetString(itemMap, 'annexureCount') ??
                        '0',
                    salesPersonId:
                    _safeGetString(itemMap, 'emp_id') ??
                        _safeGetString(itemMap, 'sales_person_id') ??
                        '',
                    salesPersonName:
                    _safeGetString(itemMap, 'sales_person_name') ?? '',
                    stage: _safeGetString(itemMap, 'stage') ?? '',
                    branch:
                    _safeGetString(itemMap, 'branch_name') ??
                        _safeGetString(itemMap, 'branch') ??
                        '',
                    rowType: rowType,
                    poApproval: poApproval,
                  ),
                );
              } catch (e) {
                print('❌ Error parsing item: $e');
                skippedCount++;
              }
            }

            print(
                '✅ Loaded ${loadedItems.length} items, skipped $skippedCount');

            // ✅ Sort immediately after loading
            _sortItemsById(loadedItems);

            setState(() {
              allItems = loadedItems;
              filteredItems = List.from(loadedItems);
              _isLoading = false;
            });

            print(
                '📋 Loaded Item IDs (First 5): ${loadedItems.take(5).map((i) => i.id).toList()}');
          } else {
            String errorMessage =
                data['message']?.toString() ??
                    data['error']?.toString() ??
                    'Unknown API error';

            print('❌ API Error: $errorMessage');

            setState(() {
              _apiErrorMessage = errorMessage;
              _isLoading = false;
              _showDebugInfo = true;
            });
          }
        } catch (e) {
          print('❌ JSON Parse Error: $e');
          print('❌ Stack trace: ${StackTrace.current}');
          setState(() {
            _apiErrorMessage = 'Invalid response format: $e';
            _isLoading = false;
            _showDebugInfo = true;
          });
        }
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        setState(() {
          _apiErrorMessage = 'HTTP ${response.statusCode}';
          _isLoading = false;
          _showDebugInfo = true;
        });
      }
    } catch (e) {
      print('❌ Network Exception: $e');
      setState(() {
        _apiErrorMessage = 'Network Error: $e';
        _isLoading = false;
        _showDebugInfo = true;
      });
    }
  }

  void _filterItems() {
    String query = _searchController.text.toLowerCase();

    List<AnnexurePOItem> tempFiltered = [...allItems];

    // Date filter only
    if (_fromDate != null || _toDate != null) {
      tempFiltered = tempFiltered.where((item) {
        List<String> dateParts = item.date.split('-');
        if (dateParts.length == 3) {
          int day = int.tryParse(dateParts[0]) ?? 0;
          int month = int.tryParse(dateParts[1]) ?? 0;
          int year = int.tryParse(dateParts[2]) ?? 0;
          if (year > 0 && month > 0 && day > 0) {
            DateTime itemDate = DateTime(year, month, day);
            bool afterFrom =
                _fromDate == null ||
                    itemDate.isAfter(_fromDate!.subtract(Duration(days: 1)));
            bool beforeTo =
                _toDate == null ||
                    itemDate.isBefore(_toDate!.add(Duration(days: 1)));
            return afterFrom && beforeTo;
          }
        }
        return false;
      }).toList();
    }

    // Search filter
    if (query.isNotEmpty) {
      tempFiltered = tempFiltered
          .where(
            (item) =>
        item.poNumber.toLowerCase().contains(query) ||
            item.projectName.toLowerCase().contains(query) ||
            item.clientName.toLowerCase().contains(query) ||
            item.woNumber.toLowerCase().contains(query),
      )
          .toList();
    }

    // ✅ Ensure sorted again after filtering
    _sortItemsById(tempFiltered);
    setState(() => filteredItems = tempFiltered);
  }

  String _formatCurrency(double amount) => '₹${amount.toStringAsFixed(2)}';

  String _formatDateForDisplay(String dateStr) {
    if (dateStr.isEmpty) return 'N/A';
    try {
      final parts = dateStr.split('-');
      if (parts.length == 3) return '${parts[2]}/${parts[1]}/${parts[0]}';
    } catch (e) {}
    return dateStr;
  }

  // ✅ Helper to get status text and color
  Map<String, dynamic> _getStatusConfig(String poApproval) {
    if (poApproval.toLowerCase() == 'yes' ||
        poApproval.toLowerCase() == 'approved' ||
        poApproval == '1') {
      return {
        'text': 'Approved',
        'color': Colors.green,
        'bgColor': Colors.green.withOpacity(0.1),
      };
    } else {
      return {
        'text': 'Pending',
        'color': Colors.orange,
        'bgColor': Colors.orange.withOpacity(0.1),
      };
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
        if (type == 'From')
          _fromDate = picked;
        else if (type == 'To') _toDate = picked;
        _filterItems();
      });
    }
  }

  Future<void> _onRefresh() async => await _loadAnnexurePOData();

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
          "Purchase Orders & Annexures",
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _loadAnnexurePOData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ✅ Filter Row 1: Search Bar (now at top)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: AppColors.primaryText,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 15),
                          const Icon(
                            Icons.search,
                            color: AppColors.primaryText,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: (_) => _filterItems(),
                              decoration: const InputDecoration(
                                hintText:
                                'Search by PO, Project, Client, or WO',
                                hintStyle: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                  fontFamily: 'serif',
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 15),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ✅ NEW: Action Buttons Row - Add Direct DM & Add Direct PO
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Row(
                children: [
                  // ✅ Add Direct DM Button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        print('Add Direct DM clicked');
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DeliveryMemoDirectAddScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.receipt_long, size: 18),
                      label: const Text(
                        'Add Direct DM',
                        style: TextStyle(fontFamily: 'serif', fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // ✅ Add Direct PO Button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        print('Add Direct PO clicked');
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PoDirectAddScreen(),

                          ),
                        );
                      },
                      icon: const Icon(Icons.add_circle, size: 18),
                      label: const Text(
                        'Add Direct PO',
                        style: TextStyle(fontFamily: 'serif', fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ✅ Filter Row 2: Date Range
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              height: 55,
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Text(
                    'Date',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                      fontFamily: 'serif',
                    ),
                  ),
                  const SizedBox(width: 10),
                  _buildDateTextField(context, 'From', _fromDate),
                  const SizedBox(width: 5),
                  _buildDateTextField(context, 'To', _toDate),
                  const Spacer(),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _fromDate = null;
                        _toDate = null;
                        _filterItems();
                      });
                    },
                    icon: const Icon(
                      Icons.close,
                      color: AppColors.primaryText,
                      size: 25,
                    ),
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                    splashRadius: 20,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Record count
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryText.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primaryText.withOpacity(0.3),
                ),
              ),
              child: Text(
                'Showing ${filteredItems.length} records',
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 12,
                  fontFamily: 'serif',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 10),
            // ✅ List with Debug Panel
            Expanded(
              child: _isLoading
                  ? Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryText,
                ),
              )
                  : _showDebugInfo && _rawApiResponse != null
                  ? _buildDebugPanel()
                  : _apiErrorMessage != null && allItems.isEmpty
                  ? _buildErrorState()
                  : RefreshIndicator(
                onRefresh: _onRefresh,
                child: ListView.builder(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) =>
                      _buildAnnexurePOCard(filteredItems[index]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebugPanel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            color: Colors.orange[50],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.orange),
                      const SizedBox(width: 8),
                      Text(
                        'Debug Mode - Raw API Response',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[800],
                          fontFamily: 'serif',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_apiErrorMessage != null) ...[
                    Text(
                      'Error: $_apiErrorMessage',
                      style: const TextStyle(
                        color: Colors.red,
                        fontFamily: 'serif',
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    'URL: $apiUrl',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Total Items: ${allItems.length}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Response Body:',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontFamily: 'serif',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: SelectableText(
                      _rawApiResponse ?? 'No response',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[800],
                        fontFamily: 'monospace',
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () => setState(() => _showDebugInfo = false),
                        icon: const Icon(Icons.close, size: 16),
                        label: const Text(
                          'Close Debug',
                          style: TextStyle(fontFamily: 'serif'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _loadAnnexurePOData,
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text(
                          'Retry API',
                          style: TextStyle(fontFamily: 'serif'),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryText,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (allItems.isNotEmpty) ...[
            const Text(
              'Loaded Items (Preview):',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'serif',
              ),
            ),
            const SizedBox(height: 8),
            ...allItems
                .take(3)
                .map(
                  (item) => Card(
                child: ListTile(
                  title: Text(
                    'PO #${item.poNumber}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontFamily: 'serif',
                    ),
                  ),
                  subtitle: Text(
                    'ID: ${item.id}\nProject: ${item.projectName}\nStatus: ${item.poApproval}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                      fontFamily: 'serif',
                    ),
                  ),
                  isThreeLine: true,
                ),
              ),
            ),
            if (allItems.length > 3)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '... and ${allItems.length - 3} more items',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic,
                    fontFamily: 'serif',
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.grey[600]),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              _apiErrorMessage ?? 'Failed to load data',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontFamily: 'serif',
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _loadAnnexurePOData,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text(
                  'Retry',
                  style: TextStyle(fontFamily: 'serif'),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryText,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              if (_rawApiResponse != null) ...[
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => setState(() => _showDebugInfo = true),
                  icon: const Icon(Icons.bug_report, size: 18),
                  label: const Text(
                    'Debug',
                    style: TextStyle(fontFamily: 'serif'),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
                    side: const BorderSide(color: Colors.orange),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateTextField(
      BuildContext context,
      String label,
      DateTime? selectedDate,
      ) {
    return SizedBox(
      width: 100,
      height: 40,
      child: TextFormField(
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontFamily: 'serif',
          ),
          hintText: 'Select $label',
          hintStyle: const TextStyle(
            color: Colors.grey,
            fontSize: 14,
            fontFamily: 'serif',
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.grey, width: 2.0),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 10,
          ),
        ),
        controller: TextEditingController(
          text: selectedDate != null
              ? '${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}'
              : '',
        ),
        onTap: () => _selectDate(context, label),
        style: const TextStyle(
          fontSize: 14,
          fontFamily: 'serif',
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildAnnexurePOCard(AnnexurePOItem item) {
    // Determine visibility based on row_type and po_approval
    bool isCommonPo = item.rowType == 'po_only' || item.rowType == 'common_po';
    bool isPoAnnexure = item.rowType == 'po_annexure';
    bool isApproved = item.poApproval.toLowerCase() == 'yes' ||
        item.poApproval.toLowerCase() == 'approved' ||
        item.poApproval == '1';

    // ✅ If po_approval is "no", hide ALL action buttons and icons
    bool showActions = isApproved;

    // Get status config for the chip
    final statusConfig = _getStatusConfig(item.poApproval);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(top: BorderSide(color: AppColors.primaryText, width: 2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PO #${item.poNumber}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                          fontFamily: 'serif',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.projectName.isNotEmpty
                            ? item.projectName
                            : 'No project',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontFamily: 'serif',
                        ),
                      ),
                    ],
                  ),
                ),
                // ✅ Status Chip: Pending or Approved
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: statusConfig['bgColor'],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusConfig['color'], width: 1),
                  ),
                  child: Text(
                    statusConfig['text'],
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: statusConfig['color'],
                      fontFamily: 'serif',
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(child: _buildInfoTile('Client', item.clientName)),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildInfoTile(
                    'WO No.',
                    item.woNumber, // ✅ Already processed: "Direct DM" or actual value
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildInfoTile(
                    'Date',
                    _formatDateForDisplay(item.date),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryText.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Amount',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                            fontFamily: 'serif',
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatCurrency(item.totalAmount),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryText,
                            fontFamily: 'serif',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // ✅ Action Buttons Row - Only show if approved
            if (showActions)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _buildSolidButton(
                        label: 'D. Memo',
                        icon: Icons.receipt_long,
                        color: Colors.blue,
                        onTap: () => print('D. Memo: ${item.poNumber}'),
                      ),
                      const SizedBox(width: 8),
                      // ✅ Show Add Annexure ONLY if row_type is 'common_po' AND approved
                      if (isCommonPo)
                        _buildSolidButton( 
                          label: 'Add Annexure',
                          icon: Icons.add_circle,
                          color: Colors.green,
                          onTap: () => print('Add Annexure: ${item.poNumber}'),
                        ),
                    ],
                  ),
                  Row(
                    children: [
                      _buildIconButton(
                        icon: Icons.visibility,
                        color: const Color(0xFF6366F1),
                        onTap: () => print('View: ${item.id}'),
                      ),
                      const SizedBox(width: 6),
                      // ✅ Show Edit Icon ONLY if row_type is 'po_annexure' AND approved
                      if (isPoAnnexure)
                        _buildIconButton(
                          icon: Icons.edit,
                          color: const Color(0xFFF59E0B),
                          onTap: () => print('Edit: ${item.id}'),
                        ),
                    ],
                  ),
                ],
              ),
            // ✅ Show "Pending Approval" message when po_approval is "no"
            if (!showActions)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.pending_actions,
                      size: 16,
                      color: Colors.orange[700],
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Awaiting Approval - Actions disabled',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange[800],
                        fontFamily: 'serif',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
              fontFamily: 'serif',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value.isNotEmpty ? value : 'N/A',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black,
              fontFamily: 'serif',
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSolidButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: Colors.white),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  fontFamily: 'serif',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required Color color,
    String? tooltip,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}

class AnnexurePOItem {
  final String id;
  final String poNumber;
  final String projectName;
  final String clientName;
  final String woNumber; // ✅ Now contains "Direct DM" when delivery_schedule is null
  final String date;
  final double totalAmount;
  final String dMemo;
  final String annexureStatus;
  final String annexureCount;
  final String salesPersonId;
  final String salesPersonName;
  final String stage;
  final String branch;
  final String rowType;
  final String poApproval;

  AnnexurePOItem({
    required this.id,
    required this.poNumber,
    required this.projectName,
    required this.clientName,
    required this.woNumber,
    required this.date,
    required this.totalAmount,
    required this.dMemo,
    required this.annexureStatus,
    required this.annexureCount,
    required this.salesPersonId,
    required this.salesPersonName,
    required this.stage,
    required this.branch,
    required this.rowType,
    required this.poApproval,
  });
}