import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:nlf/pages/delivery_memo_direct_add_screen.dart';
import 'package:nlf/utils/colors.dart';
import 'package:nlf/utils/constants.dart';

class DmScreen extends StatefulWidget {
  const DmScreen({super.key});

  @override
  _DmScreenState createState() => _DmScreenState();
}

class _DmScreenState extends State<DmScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();

  List<DeliveryMemoItem> allItems = [];
  List<DeliveryMemoItem> filteredItems = [];

  bool _isLoading = true;
  bool _showDebugInfo = false;
  DateTime? _fromDate;
  DateTime? _toDate;
  String? _apiErrorMessage;
  String? _rawApiResponse;

  @override
  void initState() {
    super.initState();
    _loadDeliveryMemos();
  }

  // ✅ Updated API URL
  final String apiUrl = AppConstants.DM_LIST_API;

  // ✅ Sorting Logic: Descending order by dm_id (Latest on top)
  void _sortItemsById(List<DeliveryMemoItem> itemsList) {
    itemsList.sort((a, b) {
      int idA = int.tryParse(a.dmId.isNotEmpty ? a.dmId : '0') ?? 0;
      int idB = int.tryParse(b.dmId.isNotEmpty ? b.dmId : '0') ?? 0;
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

  // ✅ Fetch Delivery Memos from DM_LIST_API
  Future<void> _loadDeliveryMemos() async {
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

            List<DeliveryMemoItem> loadedItems = [];
            int skippedCount = 0;

            for (var item in itemsData) {
              try {
                if (item is! Map<String, dynamic>) {
                  skippedCount++;
                  continue;
                }
                final itemMap = item;

                loadedItems.add(
                  DeliveryMemoItem(
                    dmId: _safeGetString(itemMap, 'dm_id') ?? '',
                    dmNo: _safeGetString(itemMap, 'dm_no') ?? '',
                    deliveryChallanNo:
                    _safeGetString(itemMap, 'delivery_challan_no') ?? '',
                    poNo: _safeGetString(itemMap, 'po_id')?.isNotEmpty == true
                        ? _safeGetString(itemMap, 'po_id')!
                        : '-',
                    annexureNo:
                    _safeGetString(itemMap, 'annexure_no')?.isNotEmpty ==
                        true
                        ? _safeGetString(itemMap, 'annexure_no')!
                        : '-',
                    branch: _safeGetString(itemMap, 'branch') ?? '-',
                    supervisor: _safeGetString(itemMap, 'supervisor') ?? '-',
                    date: _safeGetString(itemMap, 'date') ?? '',
                    projectName: _safeGetString(itemMap, 'project_name') ?? '-',
                    totalAmount: _safeParseDouble(itemMap['total'] ?? '0'),
                    status: _safeGetString(itemMap, 'status') ?? 'Pending',
                    type: _safeGetString(itemMap, 'type') ?? 'direct-dm',
                    remark: _safeGetString(itemMap, 'remark'),
                    modeDispatch: _safeGetString(itemMap, 'mode_dispatch'),
                    vehicleNo: _safeGetString(itemMap, 'vehicle_no'),
                    destination: _safeGetString(itemMap, 'destination'),
                    lrNo: _safeGetString(itemMap, 'lr_no'),
                    gst: _safeGetString(itemMap, 'gst'),
                    termsOfDelivery:
                    _safeGetString(itemMap, 'terms_of_delivery'),
                    createdAt: _safeGetString(itemMap, 'created_at'),
                    totalItemsQty:
                    int.tryParse(
                        _safeGetString(itemMap, 'total_items_qty') ??
                            '0') ??
                        0,
                    items: (itemMap['items'] is List)
                        ? (itemMap['items'] as List)
                        .where((i) => i is Map<String, dynamic>)
                        .map((i) => i as Map<String, dynamic>)
                        .toList()
                        : [],
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
                '📋 Loaded DM IDs (First 5): ${loadedItems.take(5).map((i) => i.dmNo).toList()}');
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

    List<DeliveryMemoItem> tempFiltered = [...allItems];

    // Date filter
    if (_fromDate != null || _toDate != null) {
      tempFiltered = tempFiltered.where((item) {
        try {
          // Handle date format: "2026-05-04" or "04/05/2026"
          DateTime itemDate;
          if (item.date.contains('-')) {
            final parts = item.date.split('-');
            if (parts.length == 3) {
              itemDate = DateTime(
                int.parse(parts[0]),
                int.parse(parts[1]),
                int.parse(parts[2]),
              );
            } else {
              return false;
            }
          } else if (item.date.contains('/')) {
            final parts = item.date.split('/');
            if (parts.length == 3) {
              itemDate = DateTime(
                int.parse(parts[2]),
                int.parse(parts[1]),
                int.parse(parts[0]),
              );
            } else {
              return false;
            }
          } else {
            return false;
          }

          bool afterFrom =
              _fromDate == null ||
                  itemDate.isAfter(_fromDate!.subtract(Duration(days: 1)));
          bool beforeTo =
              _toDate == null ||
                  itemDate.isBefore(_toDate!.add(Duration(days: 1)));
          return afterFrom && beforeTo;
        } catch (e) {
          return false;
        }
      }).toList();
    }

    // Search filter
    if (query.isNotEmpty) {
      tempFiltered = tempFiltered
          .where(
            (item) =>
        item.dmNo.toLowerCase().contains(query) ||
            item.poNo.toLowerCase().contains(query) ||
            item.annexureNo.toLowerCase().contains(query) ||
            item.projectName.toLowerCase().contains(query) ||
            item.branch.toLowerCase().contains(query) ||
            item.supervisor.toLowerCase().contains(query),
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
      // Handle "2026-05-04" format
      if (dateStr.contains('-')) {
        final parts = dateStr.split('-');
        if (parts.length == 3) {
          return '${parts[2]}/${parts[1]}/${parts[0]}';
        }
      }
      // Handle "04/05/2026" format
      if (dateStr.contains('/')) {
        final parts = dateStr.split('/');
        if (parts.length == 3) {
          return '${parts[0]}/${parts[1]}/${parts[2]}';
        }
      }
    } catch (e) {}
    return dateStr;
  }

  // ✅ Helper to get status text and color
  Map<String, dynamic> _getStatusConfig(String status) {
    final lowerStatus = status.toLowerCase();
    if (lowerStatus == 'completed' ||
        lowerStatus == 'delivered' ||
        lowerStatus == 'approved' ||
        lowerStatus == 'closed') {
      return {
        'text': 'Completed',
        'color': Colors.green,
        'bgColor': Colors.green.withOpacity(0.1),
      };
    } else if (lowerStatus == 'pending' || lowerStatus == 'processing') {
      return {
        'text': 'Pending',
        'color': Colors.orange,
        'bgColor': Colors.orange.withOpacity(0.1),
      };
    } else if (lowerStatus == 'cancelled' || lowerStatus == 'rejected') {
      return {
        'text': 'Cancelled',
        'color': Colors.red,
        'bgColor': Colors.red.withOpacity(0.1),
      };
    } else {
      return {
        'text': status,
        'color': Colors.grey,
        'bgColor': Colors.grey.withOpacity(0.1),
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

  Future<void> _onRefresh() async => await _loadDeliveryMemos();

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
          "Delivery Memo",
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
            onPressed: _loadDeliveryMemos,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ✅ Filter Row 1: Search Bar
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
                                'Search by DM No, PO, Project, Branch...',
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

            // ✅ Action Buttons Row
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Row(
                children: [
                  // ✅ Add Direct DM Button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                            const DeliveryMemoDirectAddScreen(),
                          ),
                        ).then((result) {
                          if (result == true) {
                            _loadDeliveryMemos(); // Refresh list after adding
                          }
                        });
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
                      _buildDMCard(filteredItems[index]),
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
                        onPressed: () =>
                            setState(() => _showDebugInfo = false),
                        icon: const Icon(Icons.close, size: 16),
                        label: const Text(
                          'Close Debug',
                          style: TextStyle(fontFamily: 'serif'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _loadDeliveryMemos,
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
                    'DM #${item.dmNo}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontFamily: 'serif',
                    ),
                  ),
                  subtitle: Text(
                    'ID: ${item.dmId}\nProject: ${item.projectName}\nStatus: ${item.status}',
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
                onPressed: _loadDeliveryMemos,
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

  // ✅ NEW: Build DM Card with requested fields
  Widget _buildDMCard(DeliveryMemoItem item) {
    final statusConfig = _getStatusConfig(item.status);

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
            // Header: DM No + Status
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DM #${item.dmNo}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                          fontFamily: 'serif',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.projectName,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontFamily: 'serif',
                        ),
                      ),
                    ],
                  ),
                ),
                // Status Chip
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
            const SizedBox(height: 12),

            // Row 1: PO No | Annexure No
            Row(
              children: [
                Expanded(
                  child: _buildInfoTile('PO No.', item.poNo),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildInfoTile('Annexure No.', item.annexureNo),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Row 2: Branch | Supervisor
            Row(
              children: [
                Expanded(
                  child: _buildInfoTile('Branch', item.branch),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildInfoTile('Supervisor', item.supervisor),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Row 3: Date | Total Amount
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

            // Action Buttons: View | Edit
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildIconButton(
                  icon: Icons.visibility,
                  color: const Color(0xFF6366F1),
                  tooltip: 'View Details',
                  onTap: () => _viewDeliveryMemo(item),
                ),
                const SizedBox(width: 8),
                _buildIconButton(
                  icon: Icons.edit,
                  color: const Color(0xFFF59E0B),
                  tooltip: 'Edit',
                  onTap: () => _editDeliveryMemo(item),
                ),
              ],
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
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
      ),
    );
  }

  // ✅ Action Handlers
  void _viewDeliveryMemo(DeliveryMemoItem item) {
    print('👁️ View DM: ${item.dmNo}');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Viewing DM #${item.dmNo}'),
        duration: const Duration(seconds: 2),
      ),
    );
    // TODO: Navigate to DM Detail Screen
    // Navigator.push(context, MaterialPageRoute(builder: (_) => DMDetailScreen(dmId: item.dmId)));
  }

  void _editDeliveryMemo(DeliveryMemoItem item) {
    print('✏️ Edit DM: ${item.dmNo}');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Editing DM #${item.dmNo}'),
        duration: const Duration(seconds: 2),
      ),
    );
    // TODO: Navigate to DM Edit Screen
    // Navigator.push(context, MaterialPageRoute(builder: (_) => DMEditScreen(dmId: item.dmId)));
  }
}

// ✅ NEW: Model class for Delivery Memo List API response
class DeliveryMemoItem {
  final String dmId;
  final String dmNo;
  final String deliveryChallanNo;
  final String poNo;
  final String annexureNo;
  final String branch;
  final String supervisor;
  final String date;
  final String projectName;
  final double totalAmount;
  final String status;
  final String type;
  final String? remark;
  final String? modeDispatch;
  final String? vehicleNo;
  final String? destination;
  final String? lrNo;
  final String? gst;
  final String? termsOfDelivery;
  final String? createdAt;
  final int totalItemsQty;
  final List<Map<String, dynamic>> items;

  DeliveryMemoItem({
    required this.dmId,
    required this.dmNo,
    required this.deliveryChallanNo,
    required this.poNo,
    required this.annexureNo,
    required this.branch,
    required this.supervisor,
    required this.date,
    required this.projectName,
    required this.totalAmount,
    required this.status,
    required this.type,
    this.remark,
    this.modeDispatch,
    this.vehicleNo,
    this.destination,
    this.lrNo,
    this.gst,
    this.termsOfDelivery,
    this.createdAt,
    required this.totalItemsQty,
    required this.items,
  });
}