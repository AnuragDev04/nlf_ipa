import 'package:flutter/material.dart';
import 'package:nlf/pages/add_tender_screen.dart';
import 'package:nlf/pages/quotation_details_screen.dart';
import 'package:nlf/utils/colors.dart';

class LeadItem {
  final String projectName;
  final String architect;
  final String contractor;
  final String department;
  final String stage;
  final String visitDate;

  LeadItem({
    required this.projectName,
    required this.architect,
    required this.contractor,
    required this.department,
    required this.stage,
    required this.visitDate,
  });
}

class LeadScreen extends StatefulWidget {
  const LeadScreen({super.key});

  @override
  _LeadScreenState createState() => _LeadScreenState();
}

class _LeadScreenState extends State<LeadScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _searchController = TextEditingController();

  List<LeadItem> leads = [
    LeadItem(
      projectName: 'Metro Station Complex',
      architect: 'John Architects',
      contractor: 'ABC Construction',
      department: 'Civil Engineering',
      stage: 'finalized',
      visitDate: '2025-01-15',
    ),
    LeadItem(
      projectName: 'Residential Tower',
      architect: 'Smith Design Studio',
      contractor: 'XYZ Builders',
      department: 'Structural',
      stage: 'civil',
      visitDate: '2025-01-20',
    ),
    LeadItem(
      projectName: 'Shopping Mall',
      architect: 'Modern Architects',
      contractor: 'Elite Construction',
      department: 'MEP',
      stage: 'quotation submission',
      visitDate: '2025-01-25',
    ),
    LeadItem(
      projectName: 'Office Complex',
      architect: 'Urban Planners',
      contractor: 'Prime Builders',
      department: 'Architecture',
      stage: 'finalized',
      visitDate: '2025-01-30',
    ),
    LeadItem(
      projectName: 'Hospital Building',
      architect: 'Healthcare Architects',
      contractor: 'Medical Construction',
      department: 'Civil Engineering',
      stage: 'civil',
      visitDate: '2025-02-05',
    ),
  ];

  List<LeadItem> filteredLeads = [];
  List<bool> _isDropdownOpenList = [];
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    filteredLeads = List.from(leads);
    _isDropdownOpenList = List.filled(leads.length, false);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterLeads(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredLeads = List.from(leads);
        _filterByDateRange();
      } else {
        filteredLeads = leads
            .where(
              (lead) =>
                  lead.projectName.toLowerCase().contains(
                    query.toLowerCase(),
                  ) ||
                  lead.architect.toLowerCase().contains(query.toLowerCase()) ||
                  lead.contractor.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
        _filterByDateRange();
      }

      // Update dropdown list length
      _isDropdownOpenList = List.filled(filteredLeads.length, false);
    });
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
        if (type == 'From') {
          _fromDate = picked;
        } else if (type == 'To') {
          _toDate = picked;
        }
        _filterByDateRange();
      });
    }
  }

  void _filterByDateRange() {
    setState(() {
      filteredLeads = leads.where((lead) {
        DateTime leadDate = DateTime.parse(lead.visitDate);
        bool afterFrom = _fromDate == null || !leadDate.isBefore(_fromDate!);
        bool beforeTo = _toDate == null || !leadDate.isAfter(_toDate!);
        return afterFrom && beforeTo;
      }).toList();

      final String query = _searchController.text;
      if (query.isNotEmpty) {
        filteredLeads = filteredLeads
            .where(
              (lead) =>
                  lead.projectName.toLowerCase().contains(
                    query.toLowerCase(),
                  ) ||
                  lead.architect.toLowerCase().contains(query.toLowerCase()) ||
                  lead.contractor.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }

      _isDropdownOpenList = List.filled(filteredLeads.length, false);
    });
  }

  Color _getStageColor(String stage) {
    switch (stage.toLowerCase()) {
      case 'finalized':
        return Colors.green;
      case 'civil':
        return Colors.blue;
      case 'quotation submission':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getStageIcon(String stage) {
    switch (stage.toLowerCase()) {
      case 'finalized':
        return Icons.check_circle;
      case 'civil':
        return Icons.construction;
      case 'quotation submission':
        return Icons.description;
      default:
        return Icons.work;
    }
  }

  void _updateLeadStage(int index, String newStage) {
    setState(() {
      // Update original list
      int originalIndex = leads.indexOf(filteredLeads[index]);
      leads[originalIndex] = LeadItem(
        projectName: leads[originalIndex].projectName,
        architect: leads[originalIndex].architect,
        contractor: leads[originalIndex].contractor,
        department: leads[originalIndex].department,
        stage: newStage,
        visitDate: leads[originalIndex].visitDate,
      );

      // Update filtered list
      filteredLeads[index] = LeadItem(
        projectName: filteredLeads[index].projectName,
        architect: filteredLeads[index].architect,
        contractor: filteredLeads[index].contractor,
        department: filteredLeads[index].department,
        stage: newStage,
        visitDate: filteredLeads[index].visitDate,
      );
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
          "LEAD GENERATION",
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
            SizedBox(height: 5),
            // Search Bar
            Container(
              margin: EdgeInsets.symmetric(horizontal: 10),
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: AppColors.primaryText, width: 1.5),
              ),
              child: Row(
                children: [
                  SizedBox(width: 15),
                  Icon(Icons.search, color: AppColors.primaryText, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: _filterLeads,
                      decoration: InputDecoration(
                        hintText:
                            'Search by Project name, Architect or Contractor',
                        hintStyle: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 14,
                          fontFamily: 'serif',
                        ),
                        border: InputBorder.none,
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
            // New Lead Button
            Container(
              margin: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddTenderScreen(),
                      ),
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
                        'New Lead',
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
            // Lead List
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 20),
                itemCount: filteredLeads.length,
                itemBuilder: (context, index) {
                  return _buildEnhancedLeadCard(filteredLeads[index], index);
                },
              ),
            ),
          ],
        ),
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
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey, width: 2.0),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        ),
        controller: TextEditingController(
          text: selectedDate != null
              ? '${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}'
              : '',
        ),
        onTap: () => _selectDate(context, label),
        style: TextStyle(
          fontSize: 14,
          fontFamily: 'serif',
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildEnhancedLeadCard(LeadItem lead, int index) {
    bool isDropdownOpen = _isDropdownOpenList[index];

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QuotationDetailsScreen(),
                ),
              );
            },
            child: Column(
              children: [
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getStageColor(lead.stage),
                        _getStageColor(lead.stage).withOpacity(0.6),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: _getStageColor(
                                lead.stage,
                              ).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _getStageIcon(lead.stage),
                              color: _getStageColor(lead.stage),
                              size: 22,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lead.projectName,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1E293B),
                                    fontFamily: 'serif',
                                  ),
                                ),
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today_rounded,
                                      size: 12,
                                      color: Color(0xFF94A3B8),
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      lead.visitDate,
                                      style: TextStyle(
                                        color: Color(0xFF64748B),
                                        fontSize: 12,
                                        fontFamily: 'serif',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _getStageColor(
                                lead.stage,
                              ).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              lead.stage.toUpperCase(),
                              style: TextStyle(
                                color: _getStageColor(lead.stage),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                fontFamily: 'serif',
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildInfoItem(
                                    Icons.architecture,
                                    'Architect',
                                    lead.architect,
                                    Color(0xFF3B82F6),
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 40,
                                  color: Color(0xFFE2E8F0),
                                ),
                                Expanded(
                                  child: _buildInfoItem(
                                    Icons.construction,
                                    'Contractor',
                                    lead.contractor,
                                    Color(0xFF10B981),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: _buildInfoItem(
                                Icons.business,
                                'Department',
                                lead.department,
                                Color(0xFF8B5CF6),
                              ),
                            ),
                            SizedBox(height: 12),
                            // Stage dropdown
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Stage',
                                  style: TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'serif',
                                  ),
                                ),
                                SizedBox(height: 4),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _isDropdownOpenList[index] =
                                          !_isDropdownOpenList[index];
                                    });
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.grey[300]!,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'Select new stage...',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 13,
                                              fontFamily: 'serif',
                                            ),
                                          ),
                                        ),
                                        Icon(
                                          isDropdownOpen
                                              ? Icons.arrow_drop_up
                                              : Icons.arrow_drop_down,
                                          color: Colors.grey,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (isDropdownOpen)
                                  Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.grey[300]!,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        ListTile(
                                          title: Text(
                                            'Civil',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontFamily: 'serif',
                                            ),
                                          ),
                                          onTap: () {
                                            _updateLeadStage(index, 'civil');
                                            setState(() {
                                              _isDropdownOpenList[index] =
                                                  false;
                                            });
                                          },
                                        ),
                                        Divider(
                                          height: 1,
                                          color: Colors.grey[300],
                                        ),
                                        ListTile(
                                          title: Text(
                                            'Finalizing',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontFamily: 'serif',
                                            ),
                                          ),
                                          onTap: () {
                                            _updateLeadStage(
                                              index,
                                              'finalized',
                                            );
                                            setState(() {
                                              _isDropdownOpenList[index] =
                                                  false;
                                            });
                                          },
                                        ),
                                        Divider(
                                          height: 1,
                                          color: Colors.grey[300],
                                        ),
                                        ListTile(
                                          title: Text(
                                            'Quotation Submission',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontFamily: 'serif',
                                            ),
                                          ),
                                          onTap: () {
                                            _updateLeadStage(
                                              index,
                                              'quotation submission',
                                            );
                                            setState(() {
                                              _isDropdownOpenList[index] =
                                                  false;
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: color),
              SizedBox(width: 4),
              Flexible(
                child: Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'serif',
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontFamily: 'serif',
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}
