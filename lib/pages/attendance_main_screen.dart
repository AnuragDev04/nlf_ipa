import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:nlf/pages/annexure_screen.dart';
import 'package:nlf/pages/order_confirm_screen.dart';
import 'package:nlf/pages/po_approval_screen.dart';
import 'package:nlf/pages/product_screen.dart';
import 'package:nlf/pages/quotation.dart';
import 'package:nlf/pages/attendance_screen.dart';
import '../utils/colors.dart';

// Helper class for action items
class _ActionItem {
  final String label;
  final IconData icon;
  final Widget screen;
  final bool isSelected;
  final bool isEmpty; // If true, renders an invisible container of same size

  _ActionItem({
    required this.label,
    required this.icon,
    required this.screen,
    this.isSelected = false,
    this.isEmpty = false,
  });
}

class AttendanceMainScreen extends StatefulWidget {
  const AttendanceMainScreen({super.key});

  @override
  State<AttendanceMainScreen> createState() => _AttendanceMainScreenState();
}

class _AttendanceMainScreenState extends State<AttendanceMainScreen> {
  String userName = 'User';

  List<AttendanceRecord> attendanceList = [];
  List<AttendanceRecord> filteredAttendance = [];

  bool _isLoading = false;
  String? _errorMessage;
  String selectedMonth = DateFormat('MMMM').format(DateTime.now());
  String selectedYear = DateFormat('yyyy').format(DateTime.now());

  String totalRegularHr = "00:00";
  String totalOvertimeHr = "00:00";
  int apiPresentCount = 0;
  int apiHolidayCount = 0;
  int apiAbsentCount = 0;
  int apiLeaveCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _fetchAttendanceData();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString("name") ?? 'User';
    });
  }

  int getMonthNumber(String monthName) {
    switch (monthName.toLowerCase()) {
      case 'january': case 'jan': return 1;
      case 'february': case 'feb': return 2;
      case 'march': case 'mar': return 3;
      case 'april': case 'apr': return 4;
      case 'may': return 5;
      case 'june': case 'jun': return 6;
      case 'july': case 'jul': return 7;
      case 'august': case 'aug': return 8;
      case 'september': case 'sep': return 9;
      case 'october': case 'oct': return 10;
      case 'november': case 'nov': return 11;
      case 'december': case 'dec': return 12;
      default: return DateTime.now().month;
    }
  }

  String getFriendlyStatus(String apiStatus, int dayNum, int selectedMonthNum, int selectedYearNum) {
    if (apiStatus.isEmpty) {
      final now = DateTime.now();
      final cardDate = DateTime(selectedYearNum, selectedMonthNum, dayNum);
      if (cardDate.isAfter(now)) {
        return "Future";
      }
      return "Absent";
    }
    final upper = apiStatus.toUpperCase();
    if (upper == 'A') return "Absent";
    if (upper == 'WO' || upper == 'WO-I' || upper == 'OFF') return "Holiday";
    return apiStatus;
  }

  Future<void> _fetchAttendanceData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      // ── Step 1: Get user details robustly ──────────────────────────────────
      String empId = prefs.getString("id") ?? '';
      String empCode = '';
      String empName = '';

      final userDataStr = prefs.getString("userData");
      if (userDataStr != null) {
        try {
          final userData = json.decode(userDataStr) as Map<String, dynamic>;
          final dataMap = userData['data'] as Map<String, dynamic>?;
          if (dataMap != null) {
            empId = (dataMap['emp_id'] ?? dataMap['id'] ?? '').toString();
            empCode = (dataMap['emp_code'] ?? '').toString();
            empName = (dataMap['name'] ?? dataMap['emp_name'] ?? '').toString();
          }
        } catch (e) {
          debugPrint("[Attendance] Error parsing userData: $e");
        }
      }

      if (empId.isEmpty) {
        empId = prefs.getString("id") ?? '';
      }
      if (empCode.isEmpty) {
        empCode = empId;
      }
      if (empName.isEmpty) {
        empName = prefs.getString("name") ?? '';
      }

      if (empId.isEmpty) {
        throw 'Employee ID not found. Please log in again.';
      }

      // ── Step 2: Build request ─────────────────────────────────────────────
      final url = Uri.parse("https://nlfs.in/erp/index.php/Nlf_Erp/getAttendance");
      final body = jsonEncode({
        "emp_code": empCode,
        "Month": selectedMonth,
        "Year": selectedYear,
      });

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      ).timeout(const Duration(seconds: 20));

      // ── Step 3: Parse response ────────────────────────────────────────────
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        final dynamic statusRaw = jsonResponse['status'];
        final bool isSuccess = statusRaw == true ||
            statusRaw == 1 ||
            statusRaw?.toString().toLowerCase() == 'true';

        if (isSuccess && jsonResponse['data'] != null) {
          final List<dynamic> dataList = jsonResponse['data'] is List
              ? jsonResponse['data'] as List<dynamic>
              : [jsonResponse['data']];

          if (dataList.isNotEmpty) {
            Map<String, dynamic>? empData;

            // 1. Match by exact emp_code and month
            for (var item in dataList) {
              if (item is Map<String, dynamic>) {
                final apiEmpCode = item['emp_code']?.toString();
                final apiMonth = (item['month'] ?? item['Month'] ?? '').toString();
                if (apiEmpCode != null && apiEmpCode.isNotEmpty && apiEmpCode == empCode &&
                    apiMonth.toLowerCase().trim() == selectedMonth.toLowerCase().trim()) {
                  empData = item;
                  break;
                }
              }
            }

            // 2. Fallback: Match by name and month
            if (empData == null) {
              for (var item in dataList) {
                if (item is Map<String, dynamic>) {
                  final apiEmpName = item['emp_name']?.toString().toLowerCase().trim();
                  final localEmpName = empName.toLowerCase().trim();
                  final apiMonth = (item['month'] ?? item['Month'] ?? '').toString();
                  if (apiEmpName != null && apiEmpName.isNotEmpty && apiEmpName == localEmpName &&
                      apiMonth.toLowerCase().trim() == selectedMonth.toLowerCase().trim()) {
                    empData = item;
                    break;
                  }
                }
              }
            }

            // 3. Fallback: Match by database ID and month
            if (empData == null) {
              for (var item in dataList) {
                if (item is Map<String, dynamic>) {
                  final apiId = item['id']?.toString();
                  final apiMonth = (item['month'] ?? item['Month'] ?? '').toString();
                  if (apiId != null && apiId.isNotEmpty && apiId == empId &&
                      apiMonth.toLowerCase().trim() == selectedMonth.toLowerCase().trim()) {
                    empData = item;
                    break;
                  }
                }
              }
            }

            // 4. Fallback: Match by exact emp_code only
            if (empData == null) {
              for (var item in dataList) {
                if (item is Map<String, dynamic>) {
                  final apiEmpCode = item['emp_code']?.toString();
                  if (apiEmpCode != null && apiEmpCode.isNotEmpty && apiEmpCode == empCode) {
                    empData = item;
                    break;
                  }
                }
              }
            }

            // 5. Fallback: Match by name only
            if (empData == null) {
              for (var item in dataList) {
                if (item is Map<String, dynamic>) {
                  final apiEmpName = item['emp_name']?.toString().toLowerCase().trim();
                  final localEmpName = empName.toLowerCase().trim();
                  if (apiEmpName != null && apiEmpName.isNotEmpty && apiEmpName == localEmpName) {
                    empData = item;
                    break;
                  }
                }
              }
            }

            // 6. Fallback: Match by database ID only
            if (empData == null) {
              for (var item in dataList) {
                if (item is Map<String, dynamic>) {
                  final apiId = item['id']?.toString();
                  if (apiId != null && apiId.isNotEmpty && apiId == empId) {
                    empData = item;
                    break;
                  }
                }
              }
            }

            totalRegularHr = empData != null ? (empData['total_regular_hr']?.toString() ?? '00:00') : '00:00';
            totalOvertimeHr = empData != null ? (empData['total_overtime_hr']?.toString() ?? '00:00') : '00:00';

            final List<dynamic> daysList = empData != null ? (empData['days'] ?? []) : [];
            List<AttendanceRecord> fetchedRecords = [];

            int present = 0;
            int holidays = 0;
            int absents = 0;
            int leaves = 0;

            final int monthNum = getMonthNumber(selectedMonth);
            final int yearNum = int.tryParse(selectedYear) ?? DateTime.now().year;

            for (var dayObj in daysList) {
              final int dayNum = dayObj['day'] is int
                  ? dayObj['day'] as int
                  : int.tryParse(dayObj['day'].toString()) ?? 1;
              final String rawStatus = dayObj['status']?.toString() ?? '';
              final String friendlyStatus =
              getFriendlyStatus(rawStatus, dayNum, monthNum, yearNum);

              final lowerStatus = friendlyStatus.toLowerCase();
              if (lowerStatus == 'present' || lowerStatus == 'late') {
                present++;
              } else if (lowerStatus == 'holiday') {
                holidays++;
              } else if (lowerStatus == 'leave') {
                leaves++;
              } else if (lowerStatus == 'absent') {
                absents++;
              }

              final dateString =
                  "$yearNum-${monthNum.toString().padLeft(2, '0')}-${dayNum.toString().padLeft(2, '0')}";
              String calculatedDayName = 'Monday';
              try {
                calculatedDayName =
                    DateFormat('EEEE').format(DateTime(yearNum, monthNum, dayNum));
              } catch (_) {}

              String toStr(dynamic v) => v?.toString() ?? '';
              final checkInAdd = toStr(dayObj['checkInAdd']);
              final checkOutAdd = toStr(dayObj['checkOutAdd']);

              fetchedRecords.add(
                AttendanceRecord(
                  date: dateString,
                  day: calculatedDayName,
                  checkIn: toStr(dayObj['check_in']).isNotEmpty
                      ? toStr(dayObj['check_in'])
                      : '--',
                  checkOut: toStr(dayObj['check_out']).isNotEmpty
                      ? toStr(dayObj['check_out'])
                      : '--',
                  status: friendlyStatus,
                  location: checkInAdd.isNotEmpty
                      ? checkInAdd
                      : checkOutAdd.isNotEmpty
                      ? checkOutAdd
                      : 'N/A',
                  details: toStr(dayObj['raw_value']),
                  workedHr: toStr(dayObj['worked_hr']).isNotEmpty
                      ? toStr(dayObj['worked_hr'])
                      : '00:00',
                  regularHr: toStr(dayObj['regular_hr']).isNotEmpty
                      ? toStr(dayObj['regular_hr'])
                      : '00:00',
                  overtimeHr: toStr(dayObj['overtime_hr']).isNotEmpty
                      ? toStr(dayObj['overtime_hr'])
                      : '00:00',
                  checkInLat: toStr(dayObj['check_in_lat']),
                  checkInLong: toStr(dayObj['check_in_long']),
                  checkOutLat: toStr(dayObj['check_out_lat']),
                  checkOutLong: toStr(dayObj['check_out_long']),
                  checkInSelfie: toStr(dayObj['check_in_selfie']),
                  checkOutSelfie: toStr(dayObj['check_out_selfie']),
                  checkInAdd: checkInAdd,
                  checkOutAdd: checkOutAdd,
                ),
              );
            }

            fetchedRecords = fetchedRecords.reversed.toList();

            if (mounted) {
              setState(() {
                attendanceList = fetchedRecords;
                filteredAttendance = List.from(attendanceList);
                apiPresentCount = present;
                apiHolidayCount = holidays;
                apiAbsentCount = absents;
                apiLeaveCount = leaves;
                _isLoading = false;
              });
            }
          } else {
            if (mounted) {
              setState(() {
                attendanceList = [];
                filteredAttendance = [];
                apiPresentCount = 0;
                apiHolidayCount = 0;
                apiAbsentCount = 0;
                apiLeaveCount = 0;
                totalRegularHr = '00:00';
                totalOvertimeHr = '00:00';
                _isLoading = false;
              });
            }
          }
        } else {
          if (mounted) {
            setState(() {
              attendanceList = [];
              filteredAttendance = [];
              apiPresentCount = 0;
              apiHolidayCount = 0;
              apiAbsentCount = 0;
              apiLeaveCount = 0;
              totalRegularHr = '00:00';
              totalOvertimeHr = '00:00';
              _isLoading = false;
            });
          }
        }
      } else {
        throw 'Server error: ${response.statusCode}';
      }
    } catch (e) {
      debugPrint("[Attendance] Error: $e");
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().contains('timeout')
              ? 'Request timed out. Please check your connection.'
              : e.toString().contains('Employee ID')
              ? e.toString()
              : 'Failed to load attendance: $e';
          _isLoading = false;
        });
      }
    }
  }

  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  int get presentCount => attendanceList.where((r) => r.status == 'Present' || r.status == 'Late').length;

  double get attendanceRate {
    final totalWorkable = attendanceList.where((r) => r.status != 'Holiday').length;
    if (totalWorkable == 0) return 100.0;
    return (presentCount / totalWorkable) * 100;
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
        title: Text(
          "Attendance Dashboard",
          style: GoogleFonts.lora(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 50,
        titleSpacing: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryText,
                  ),
                ),
              )
            else if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Column(
                    children: [
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red, fontFamily: 'serif'),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _fetchAttendanceData,
                        icon: const Icon(Icons.refresh),
                        label: const Text("Retry", style: TextStyle(fontFamily: 'serif')),
                      )
                    ],
                  ),
                ),
              )
            else ...[
                _buildHeaderCards(),
              ],
            const SizedBox(height: 16),
            _buildSectionHeader("Quick Actions"),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildActionRow(context, [
                    // Card 1: Visible and Functional
                    _ActionItem(
                      label: "Add Attendance",
                      icon: Icons.fingerprint_rounded,
                      screen: const AttendanceScreen(),
                      isSelected: true,
                      isEmpty: false,
                    ),
                    // Card 2: Invisible Placeholder (Occupies Space)
                    _ActionItem(
                      label: "",
                      icon: Icons.hide_image, // Dummy icon
                      screen: const SizedBox(), // Dummy screen
                      isSelected: false,
                      isEmpty: true, // ✅ This makes it invisible but keeps size
                    ),
                    // Card 3: Invisible Placeholder (Occupies Space)
                    _ActionItem(
                      label: "",
                      icon: Icons.hide_image, // Dummy icon
                      screen: const SizedBox(), // Dummy screen
                      isSelected: false,
                      isEmpty: true, // ✅ This makes it invisible but keeps size
                    ),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthYearSelector() {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    final currentYear = DateTime.now().year;
    final years = List.generate(6, (index) => (currentYear - 3 + index).toString());

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.grey.withOpacity(0.12),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_month_rounded, color: Colors.blueAccent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedMonth,
                icon: const Icon(Icons.arrow_drop_down_rounded, color: Colors.grey),
                style: const TextStyle(
                  color: Color(0xFF1E293B),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'serif',
                ),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      selectedMonth = newValue;
                    });
                    _fetchAttendanceData();
                  }
                },
                items: months.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ),
          ),
          Container(
            width: 1,
            height: 24,
            color: Colors.grey.withOpacity(0.2),
            margin: const EdgeInsets.symmetric(horizontal: 12),
          ),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedYear,
                icon: const Icon(Icons.arrow_drop_down_rounded, color: Colors.grey),
                style: const TextStyle(
                  color: Color(0xFF1E293B),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'serif',
                ),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      selectedYear = newValue;
                    });
                    _fetchAttendanceData();
                  }
                },
                items: years.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCards() {
    final todayStr = DateFormat('EEE, d MMM yyyy').format(DateTime.now());

    String latestLocation = 'GPS Active';
    if (filteredAttendance.isNotEmpty) {
      for (var r in filteredAttendance) {
        if (r.checkInAdd.isNotEmpty) {
          latestLocation = r.checkInAdd;
          break;
        } else if (r.checkOutAdd.isNotEmpty) {
          latestLocation = r.checkOutAdd;
          break;
        }
      }
    }
    if (latestLocation.length > 20) {
      latestLocation = latestLocation.substring(0, 18) + "...";
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildHeaderCard(
                  title: getGreeting(),
                  value: userName,
                  subtitle: todayStr,
                  icon: Icons.wb_sunny_rounded,
                  color: const Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildHeaderCard(
                  title: 'Last Location',
                  value: latestLocation,
                  subtitle: 'GPS Active',
                  icon: Icons.location_on_rounded,
                  color: const Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildHeaderCard(
                  title: 'Days Summary',
                  value: '$apiPresentCount / ${attendanceList.length} Days',
                  subtitle: '$apiPresentCount Present, $apiHolidayCount Holiday',
                  icon: Icons.calendar_month_rounded,
                  color: const Color(0xFFFB923C),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildHeaderCard(
                  title: 'Attendance Rate',
                  value: '${attendanceRate.toStringAsFixed(1)}%',
                  subtitle: 'Target: 90.0%',
                  icon: Icons.trending_up_rounded,
                  color: const Color(0xFF8B5CF6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWorkHoursSummaryCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.work_history_rounded, color: Colors.amberAccent, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "MONTHLY WORK HOURS SUMMARY",
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                    fontFamily: 'serif',
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      "Regular: $totalRegularHr",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'serif',
                      ),
                    ),
                    const SizedBox(width: 24),
                    Text(
                      "Overtime: $totalOvertimeHr",
                      style: const TextStyle(
                        color: Colors.amberAccent,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'serif',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.grey.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'serif',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF1E293B),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'serif',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 10,
                    fontFamily: 'serif',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow(BuildContext context, List<_ActionItem> items) {
    List<Widget> children = [];
    for (int i = 0; i < items.length; i++) {
      children.add(
        Expanded(
          child: GestureDetector(
            onTap: () {
              // Only allow tap if it's not an empty placeholder
              if (!items[i].isEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => items[i].screen),
                ).then((_) {
                  // Refresh stats when returning to the dashboard
                  _fetchAttendanceData();
                });
              }
            },
            child: _buildRoutine(
              items[i].label,
              items[i].icon,
              items[i].isSelected,
              isEmpty: items[i].isEmpty,
            ),
          ),
        ),
      );
      if (i < items.length - 1) {
        children.add(const SizedBox(width: 15));
      }
    }
    return Row(children: children);
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Text(
        title,
        style: GoogleFonts.lora(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildRoutine(String label, IconData icon, bool selected, {bool isEmpty = false}) {
    // ✅ If isEmpty is true, return a transparent container of the same size
    if (isEmpty) {
      return Container(
        height: 100,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          // Optional: Add a very faint border if you want to see the grid structure during dev
          // border: Border.all(color: Colors.grey.withOpacity(0.1)),
        ),
      );
    }

    // ✅ Normal Card Rendering
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: selected ? AppColors.primaryText : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: selected ? Colors.white.withOpacity(0.2) : const Color(0xFFF8FAFC),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: selected ? Colors.white : AppColors.primaryText,
              size: 26,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.lora(
              color: selected ? Colors.white : Colors.black87,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// Assuming AttendanceRecord is defined elsewhere or imported.
// If not, here is a minimal definition to prevent errors if you copy-paste this file alone.
class AttendanceRecord {
  final String date;
  final String day;
  final String checkIn;
  final String checkOut;
  final String status;
  final String location;
  final String details;
  final String workedHr;
  final String regularHr;
  final String overtimeHr;
  final String checkInLat;
  final String checkInLong;
  final String checkOutLat;
  final String checkOutLong;
  final String checkInSelfie;
  final String checkOutSelfie;
  final String checkInAdd;
  final String checkOutAdd;

  const AttendanceRecord({
    required this.date,
    required this.day,
    required this.checkIn,
    required this.checkOut,
    required this.status,
    required this.location,
    required this.details,
    this.workedHr = '00:00',
    this.regularHr = '00:00',
    this.overtimeHr = '00:00',
    this.checkInLat = '',
    this.checkInLong = '',
    this.checkOutLat = '',
    this.checkOutLong = '',
    this.checkInSelfie = '',
    this.checkOutSelfie = '',
    this.checkInAdd = '',
    this.checkOutAdd = '',
  });
}