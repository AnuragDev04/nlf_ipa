import 'package:flutter/material.dart';
import 'package:nlf/pages/add_order_screen.dart';
import 'package:nlf/utils/colors.dart';

class OrderConfirmScreen extends StatefulWidget {
  const OrderConfirmScreen({super.key});

  @override
  _OrderConfirmScreenState createState() => _OrderConfirmScreenState();
}

class _OrderConfirmScreenState extends State<OrderConfirmScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _searchController = TextEditingController();
  List<TenderItem> tenders = [
    TenderItem(
      customerName: 'ABC Construction Ltd.',
      tenderAmount: 25000,
      tenderNumber: 'QTR-2024-001',
      date: '2024-01-15',
      status: 'Pending',
      emdAmount: 'ORD-2024-001',
      isApproved: false,
    ),
    TenderItem(
      customerName: 'XYZ Infrastructure Pvt. Ltd.',
      tenderAmount: 45000,
      tenderNumber: 'QTR-2024-002',
      date: '2024-01-10',
      status: 'Pending',
      emdAmount: 'ORD-2024-002',
      isApproved: false,
    ),
    TenderItem(
      customerName: 'Metro Building Solutions',
      tenderAmount: 15000,
      tenderNumber: 'QTR-2024-003',
      date: '2024-01-08',
      status: 'Pending',
      emdAmount: 'ORD-2024-003',
      isApproved: false,
    ),
    TenderItem(
      customerName: 'City Development Authority',
      tenderAmount: 75000,
      tenderNumber: 'QTR-2024-004',
      date: '2024-01-05',
      status: 'Pending',
      emdAmount: 'ORD-2024-004',
      isApproved: true,
    ),
    TenderItem(
      customerName: 'Green Tech Solutions',
      tenderAmount: 32000,
      tenderNumber: 'TDR-2024-005',
      date: '2024-01-03',
      status: 'Pending',
      emdAmount: 'ORD-2024-005',
      isApproved: false,
    ),
  ];

  List<TenderItem> filteredTenders = [];
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    filteredTenders = tenders;
  }

  void _filterTenders(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredTenders = tenders;
        _filterByDateRange(); // Re-apply date filter
      } else {
        filteredTenders = tenders
            .where(
              (tender) =>
                  tender.customerName.toLowerCase().contains(
                    query.toLowerCase(),
                  ) ||
                  tender.tenderNumber.toLowerCase().contains(
                    query.toLowerCase(),
                  ),
            )
            .toList();
        _filterByDateRange(); // Apply date filter to search results
      }
    });
  }

  Future<void> _selectDate(BuildContext context, String type) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.blue,
            colorScheme: ColorScheme.light(primary: Colors.blue),
            buttonTheme: ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (type == 'From') {
          _fromDate = picked;
        } else if (type == 'To') {
          _toDate = picked;
        }

        // Filter after selecting date
        _filterByDateRange();
      });
    }
  }

  void _filterByDateRange() {
    setState(() {
      filteredTenders = tenders.where((tender) {
        DateTime tenderDate = DateTime.parse(
          tender.date,
        ); // Ensure date is in 'yyyy-MM-dd' format

        bool afterFrom =
            _fromDate == null ||
            tenderDate.isAfter(_fromDate!.subtract(Duration(days: 1)));
        bool beforeTo =
            _toDate == null ||
            tenderDate.isBefore(_toDate!.add(Duration(days: 1)));

        return afterFrom && beforeTo;
      }).toList();

      // Re-apply search filter if needed
      final String query = _searchController.text;
      if (query.isNotEmpty) {
        filteredTenders = filteredTenders
            .where(
              (tender) =>
                  tender.customerName.toLowerCase().contains(
                    query.toLowerCase(),
                  ) ||
                  tender.tenderNumber.toLowerCase().contains(
                    query.toLowerCase(),
                  ),
            )
            .toList();
      }
    });
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'Requisitioned':
        return Colors.green;
      default:
        return Colors.orange; // Default to pending color
    }
  }

  String _getDisplayStatus(TenderItem tender) {
    if (tender.isApproved) {
      return 'Requisitioned';
    } else {
      return 'Pending';
    }
  }

  void _toggleApproval(int index) {
    setState(() {
      filteredTenders[index].isApproved = !filteredTenders[index].isApproved;
      // Also update the original list
      int originalIndex = tenders.indexWhere(
        (tender) => tender.tenderNumber == filteredTenders[index].tenderNumber,
      );
      if (originalIndex != -1) {
        tenders[originalIndex].isApproved = filteredTenders[index].isApproved;
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
          "ALL ORDERS",
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
        child: Column(
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
                      onChanged: _filterTenders,
                      decoration: InputDecoration(
                        hintText: 'Search by Client name or Quotation number',
                        hintStyle: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 14,
                          fontFamily: 'serif',
                        ),
                        border: InputBorder.none,
                        // Remove content padding from TextField to fit within the container
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                    ),
                  ),
                  SizedBox(width: 15),
                ],
              ),
            ),

            SizedBox(height: 20),

            // Filter Section
            Container(
              margin: EdgeInsets.symmetric(horizontal: 10),
              height: 55,
              padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Text(
                    'Date',
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontSize: 14,
                      fontFamily: 'serif',
                    ),
                  ),
                  SizedBox(width: 10),
                  _buildDateTextField(context, 'From', _fromDate),
                  SizedBox(width: 5),
                  _buildDateTextField(context, 'To', _toDate),
                  Spacer(),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _fromDate = null;
                        _toDate = null;
                        _filterByDateRange();
                      });
                    },
                    icon: Icon(Icons.close, color: Colors.red, size: 25),
                    padding: EdgeInsets.all(8),
                    constraints: BoxConstraints(),
                    splashRadius: 20,
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // New Quotation Button
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AddOrderScreen()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black87,
                    backgroundColor: Colors.transparent,
                    side: BorderSide(color: Colors.black87, width: 2.0),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: AppColors.primaryText,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.add, color: Colors.white, size: 14),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'New Order',
                        style: TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'serif',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 20),

            // Quotation List
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 20),
                itemCount: filteredTenders.length,
                itemBuilder: (context, index) {
                  return _buildTenderCard(filteredTenders[index], index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateButton(String label) {
    DateTime? selectedDate;

    if (label == 'From') {
      selectedDate = _fromDate;
    } else if (label == 'To') {
      selectedDate = _toDate;
    }

    return GestureDetector(
      onTap: () => _selectDate(context, label),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
            SizedBox(width: 5),
            Text(
              selectedDate != null
                  ? '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'
                  : label,
              style: TextStyle(
                color: selectedDate != null ? Colors.black87 : Colors.grey[700],
                fontSize: 12,
                fontFamily: 'serif',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTenderCard(TenderItem tender, int index) {
    String displayStatus = _getDisplayStatus(tender);

    return Container(
      margin: EdgeInsets.only(bottom: 15),
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey[200]!,
            blurRadius: 5,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Row
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _getStatusColor(displayStatus),
                  // Now returns green for accepted
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  tender.customerName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[600],
                    fontFamily: 'serif',
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(displayStatus).withOpacity(0.1),
                  // Now returns green for accepted
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  displayStatus,
                  style: TextStyle(
                    color: _getStatusColor(displayStatus),
                    // Now returns green for accepted
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'serif',
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 10),

          // Date Row
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]),
              SizedBox(width: 5),
              Text(
                tender.date,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                  fontFamily: 'serif',
                ),
              ),
            ],
          ),

          SizedBox(height: 15),

          // Amount and Tender Number Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Amount',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontFamily: 'serif',
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '₹${tender.tenderAmount.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        fontFamily: 'serif',
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Order No.',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontFamily: 'serif',
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      tender.emdAmount.toString(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[600],
                        fontFamily: 'serif',
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Quote No. #',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontFamily: 'serif',
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      tender.tenderNumber,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[600],
                        fontFamily: 'serif',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 20),

          // Action Buttons Row
          Row(
            children: [
              _buildActionButton(Icons.visibility, 'View', Colors.grey[600]!),
              SizedBox(width: 20),
              _buildActionButton(Icons.print, 'Print', Colors.grey[600]!),
              SizedBox(width: 20),
              _buildActionButton(Icons.edit, 'Edit', Colors.grey[600]!),
              SizedBox(width: 20),
              _buildActionButton(Icons.delete, 'Delete', Colors.red[400]!),
              SizedBox(width: 20),
              // Approve Checkbox
              GestureDetector(
                onTap: () => _toggleApproval(index),
                child: Column(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: tender.isApproved
                            ? Colors.green
                            : Colors.transparent,
                        border: Border.all(
                          color: tender.isApproved
                              ? Colors.green
                              : Colors.grey[600]!,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: tender.isApproved
                          ? Icon(Icons.check, color: Colors.white, size: 16)
                          : null,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Requisition',
                      style: TextStyle(
                        color: tender.isApproved
                            ? Colors.green
                            : Colors.grey[600]!,
                        fontSize: 10,
                        fontFamily: 'serif',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: color, fontSize: 10, fontFamily: 'serif'),
        ),
      ],
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
          labelStyle: TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontFamily: 'serif',
          ),
          hintText: 'Select $label date',
          hintStyle: TextStyle(
            color: Colors.grey[400],
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
            borderSide: BorderSide(color: Colors.grey, width: 2.0),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          constraints: const BoxConstraints(minHeight: 55, maxHeight: 55),
        ),
        controller: TextEditingController(
          text: selectedDate != null
              ? '${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}'
              : '',
        ),
        onTap: () => _selectDate(context, label),
        style: TextStyle(color: Colors.black, fontFamily: 'serif'),
      ),
    );
  }
}

class TenderItem {
  final String customerName;
  final double tenderAmount;
  final String tenderNumber;
  final String date;
  final String status;
  final String emdAmount;
  bool isApproved;

  TenderItem({
    required this.customerName,
    required this.tenderAmount,
    required this.tenderNumber,
    required this.date,
    required this.status,
    required this.emdAmount,
    this.isApproved = false,
  });
}
