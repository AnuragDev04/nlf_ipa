import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nlf/utils/colors.dart';
import 'package:intl/intl.dart';
import 'package:nlf/pages/check_in_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();
class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  _AttendanceScreenState createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> with RouteAware {
  String userName = 'User';

  List<AttendanceRecord> attendanceList = [];
  List<AttendanceRecord> filteredAttendance = [];

  bool _isLoading = false;
  String? _errorMessage;
  String selectedMonth = DateFormat('MMMM').format(DateTime.now());
  String selectedYear = DateFormat('yyyy').format(DateTime.now());

  // ✅ NEW: Track selected tab index and admin status
  int _selectedTabIndex = 1; // Default to Monthly for non-admin; admin overrides to 0 after load
  bool _isAdmin = false;

  // ✅ Admin-only: raw per-employee data from the API
  List<Map<String, dynamic>> _allEmployeeRecords = [];
  List<Map<String, dynamic>> _filteredEmployeeRecords = [];
  final TextEditingController _searchController = TextEditingController();

  String totalRegularHr = "00:00";
  String totalOvertimeHr = "00:00";
  int apiPresentCount = 0;
  int apiHolidayCount = 0;
  int apiAbsentCount = 0;
  int apiLeaveCount = 0;

  // ✅ NEW: Track which dates have checkout clicked
  Set<String> _checkoutCompletedDates = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    _fetchAttendanceData();
  }

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _loadUserName();
    await _fetchAttendanceData();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    String empId = '';
    String empCode = '';
    
    final userDataStr = prefs.getString("userData");
    if (userDataStr != null) {
      try {
        final userData = json.decode(userDataStr) as Map<String, dynamic>;
        final dataMap = userData['data'] as Map<String, dynamic>?;
        if (dataMap != null) {
          empId = (dataMap['emp_id'] ?? dataMap['id'] ?? '').toString();
          empCode = (dataMap['emp_code'] ?? '').toString();
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
    
    final role = prefs.getString("role") ?? '';
    final name = prefs.getString("name") ?? 'User';
    final isAdminUser = (empCode == "1" || role.toLowerCase().trim() == "admin");

    // Update state synchronously before fetch
    userName = name;
    _isAdmin = isAdminUser;
    if (isAdminUser) {
      _selectedTabIndex = 0; // Admin defaults to Today tab
    }
    // Non-admin keeps _selectedTabIndex = 1 (Monthly) set as default
    if (mounted) setState(() {});
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
        return "Pending";
      }
      return "Absent";
    }
    final upper = apiStatus.toUpperCase();
    if (upper == 'A') return "Absent";
    if (upper == 'WO' || upper == 'WO-I' || upper == 'OFF') return "Holiday";
    return apiStatus;
  }

  Future<void> _fetchAttendanceData() async {
    // Admin: fetch all employees instead
    if (_isAdmin) {
      await _fetchAdminAttendanceData();
      return;
    }
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

      debugPrint("[Attendance] empId='$empId' empCode='$empCode' name='$empName'");

      if (empId.isEmpty) {
        throw 'Employee ID not found. Please log in again.';
      }

      // ── Step 2: Build request ─────────────────────────────────────────────
      final url = Uri.parse("https://nlfs.in/erp/index.php/Nlf_Erp/getAttendance");
      Map<String, dynamic> requestBody;
      final now = DateTime.now();
      final currentDay = DateFormat('d').format(now);
      final currentMonthName = DateFormat('MMMM').format(now);
      final currentYear = DateFormat('yyyy').format(now);

      if (_selectedTabIndex == 0) {
        requestBody = {
          "emp_code": empCode,
          "day": currentDay,
          "Month": currentMonthName,
          "Year": currentYear,
        };
      } else if (_selectedTabIndex == 1) {
        requestBody = {
          "emp_code": empCode,
          "Month": selectedMonth,
          "Year": selectedYear,
        };
      } else if (_selectedTabIndex == 2) {
        requestBody = {
          "emp_code": empCode,
          "day": currentDay,
          "Month": currentMonthName,
          "Year": currentYear,
          "type": "on_site",
        };
      } else {
        requestBody = {
          "emp_code": empCode,
          "Month": selectedMonth,
          "Year": selectedYear,
        };
      }

      final body = jsonEncode(requestBody);

      debugPrint("[Attendance] POST $url | Body: $body");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      ).timeout(const Duration(seconds: 20));

      debugPrint("[Attendance] Status: ${response.statusCode}");
      debugPrint("[Attendance] Response: ${response.body}");

      // ── Step 3: Parse response ────────────────────────────────────────────
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        // Accept status: true OR status: "true" OR status: 1
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

            final targetMonth = (_selectedTabIndex == 1) ? selectedMonth : currentMonthName;

            // 1. Match by exact emp_code and month
            for (var item in dataList) {
              if (item is Map<String, dynamic>) {
                final apiEmpCode = item['emp_code']?.toString();
                final apiMonth = (item['month'] ?? item['Month'] ?? '').toString();
                if (apiEmpCode != null && apiEmpCode.isNotEmpty && apiEmpCode == empCode &&
                    apiMonth.toLowerCase().trim() == targetMonth.toLowerCase().trim()) {
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
                      apiMonth.toLowerCase().trim() == targetMonth.toLowerCase().trim()) {
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
                      apiMonth.toLowerCase().trim() == targetMonth.toLowerCase().trim()) {
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

            // 7. If no match found, empData remains null
            if (empData == null) {
              debugPrint("[Attendance] No attendance record found for logged in user: empCode='$empCode', empName='$empName', empId='$empId'");
            }

            totalRegularHr = empData != null ? (empData['total_regular_hr']?.toString() ?? '00:00') : '00:00';
            totalOvertimeHr = empData != null ? (empData['total_overtime_hr']?.toString() ?? '00:00') : '00:00';

            final List<dynamic> daysList = empData != null ? (empData['days'] ?? []) : [];
            List<AttendanceRecord> fetchedRecords = [];

            int present = 0;
            int holidays = 0;
            int absents = 0;
            int leaves = 0;

            // Compute month/year numbers for date building and status logic
            // For Today/OnSite tabs, we use current month/year. For Monthly, we use selected.
            final int monthNum = _selectedTabIndex == 1 ? getMonthNumber(selectedMonth) : now.month;
            final int yearNum = _selectedTabIndex == 1 ? (int.tryParse(selectedYear) ?? now.year) : now.year;

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

            // Newest days first
            fetchedRecords = fetchedRecords.reversed.toList();

            // Filter out future dates (only show today and past)
            final today = DateTime.now();
            final todayDate = DateTime(today.year, today.month, today.day);
            fetchedRecords = fetchedRecords.where((r) {
              try {
                final recordDate = DateTime.parse(r.date);
                return !recordDate.isAfter(todayDate);
              } catch (_) {
                return true;
              }
            }).toList();

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
            // data list is empty — show empty state (not an error)
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
          // status false → show empty state
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

  // ════════════════════════════════════════════════════════════════════
  // ADMIN FETCH: Load ALL employees attendance
  // ════════════════════════════════════════════════════════════════════
  Future<void> _fetchAdminAttendanceData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _allEmployeeRecords = [];
    });

    try {
      final now = DateTime.now();
      final currentDay = DateFormat('d').format(now);
      final currentMonthName = DateFormat('MMMM').format(now);
      final currentYear = DateFormat('yyyy').format(now);

      Map<String, dynamic> requestBody;
      if (_selectedTabIndex == 0) {
        // Today – fetch all employees for today
        requestBody = {
          "day": currentDay,
          "Month": currentMonthName,
          "Year": currentYear,
        };
      } else {
        // Monthly – fetch all employees for selected month
        requestBody = {
          "Month": selectedMonth,
          "Year": selectedYear,
        };
      }

      final url = Uri.parse("https://nlfs.in/erp/index.php/Nlf_Erp/getAttendance");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 20));

      debugPrint("[Admin Attendance] Status: ${response.statusCode}");
      debugPrint("[Admin Attendance] Body: ${response.body}");

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body) as Map<String, dynamic>;
        final dynamic statusRaw = jsonResponse['status'];
        final bool isSuccess = statusRaw == true ||
            statusRaw == 1 ||
            statusRaw?.toString().toLowerCase() == 'true';

        if (isSuccess && jsonResponse['data'] != null) {
          final List<dynamic> dataList = jsonResponse['data'] is List
              ? jsonResponse['data'] as List<dynamic>
              : [jsonResponse['data']];

          final List<Map<String, dynamic>> records = [];
          for (final item in dataList) {
            if (item is Map<String, dynamic>) {
              records.add(item);
            }
          }

          if (mounted) {
            setState(() {
              _allEmployeeRecords = records;
              _filteredEmployeeRecords = records;
              _searchController.clear();
              _isLoading = false;
            });
          }
        } else {
          if (mounted) setState(() { _allEmployeeRecords = []; _filteredEmployeeRecords = []; _isLoading = false; });
        }
      } else {
        throw 'Server error: ${response.statusCode}';
      }
    } catch (e) {
      debugPrint("[Admin Attendance] Error: $e");
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().contains('timeout')
              ? 'Request timed out. Please check your connection.'
              : 'Failed to load attendance: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _onSearch(String query) {
    final q = query.toLowerCase().trim();
    setState(() {
      if (q.isEmpty) {
        _filteredEmployeeRecords = List.from(_allEmployeeRecords);
      } else {
        _filteredEmployeeRecords = _allEmployeeRecords.where((emp) {
          final name = (emp['emp_name'] ?? '').toString().toLowerCase();
          final mobile = (emp['mobile'] ?? emp['phone'] ?? emp['contact'] ?? '').toString().toLowerCase();
          final email = (emp['email'] ?? '').toString().toLowerCase();
          final empCode = (emp['emp_code'] ?? '').toString().toLowerCase();
          return name.contains(q) || mobile.contains(q) || email.contains(q) || empCode.contains(q);
        }).toList();
      }
    });
  }

  Widget _buildSearchBox() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3)),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.12)),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearch,
        style: const TextStyle(fontSize: 14, fontFamily: 'serif', color: Color(0xFF1E293B)),
        decoration: InputDecoration(
          hintText: 'Search by name, mobile or email...',
          hintStyle: TextStyle(fontSize: 13, fontFamily: 'serif', color: Colors.grey[400]),
          prefixIcon: const Icon(Icons.search_rounded, color: Colors.grey, size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    _onSearch('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return Colors.green;
      case 'late':
        return Colors.orange;
      case 'leave':
        return Colors.blue;
      case 'absent':
        return Colors.red;
      case 'holiday':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'present':
        return Icons.check_circle_rounded;
      case 'late':
        return Icons.watch_later_rounded;
      case 'leave':
        return Icons.beach_access_rounded;
      case 'absent':
        return Icons.cancel_rounded;
      case 'holiday':
        return Icons.event_note_rounded;
      default:
        return Icons.fingerprint_rounded;
    }
  }

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
          "ATTENDANCE",
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
            // ✅ Tab Bar – only for admin
            if (_isAdmin) _buildCustomTabBar(),

            // Month/Year selector for Monthly tab
            if (_selectedTabIndex == 1) _buildMonthYearSelector(),

            // Header Cards & Work Hours Summary (for regular employees only)
            if (!_isAdmin) _buildHeaderCards(),
            if (!_isAdmin) _buildWorkHoursSummaryCard(),

            // Admin stats summary banner
            if (_isAdmin) _buildAdminStatsBanner(),

            // Search box for admin
            if (_isAdmin) _buildSearchBox(),

            const SizedBox(height: 8),

            // Check-In / Check-Out button for ALL users
            if (true)
              Builder(
                builder: (context) {
                  final now = DateTime.now();
                  final todayFormatted = DateFormat('yyyy-MM-dd').format(now);
                  bool alreadyCheckedIn = attendanceList.any((r) => r.date == todayFormatted && r.checkIn != '--');
                  bool alreadyCheckedOut = attendanceList.any((r) => r.date == todayFormatted && r.checkOut != '--');

                  if (_isAdmin) {
                    for (final emp in _allEmployeeRecords) {
                      if (emp['emp_code']?.toString() == '1') {
                        final days = emp['days'] as List<dynamic>? ?? [];
                        for (final d in days) {
                          final dayNum = d['day'] is int ? d['day'] as int : int.tryParse(d['day'].toString()) ?? -1;
                          if (dayNum == now.day) {
                            alreadyCheckedIn = (d['check_in']?.toString() ?? '').isNotEmpty;
                            alreadyCheckedOut = (d['check_out']?.toString() ?? '').isNotEmpty;
                          }
                        }
                        break;
                      }
                    }
                  }

                  final actionText = (alreadyCheckedIn && !alreadyCheckedOut) ? 'Punch-Out' : 'Punch-In';

                  if (actionText == 'Punch-Out') return const SizedBox.shrink();

                  return Container(
                    margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton(
                        onPressed: () async {
                          if (alreadyCheckedIn && alreadyCheckedOut) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('You have already completed punch-in and punch-out for today!', style: TextStyle(fontFamily: 'serif')),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            return;
                          }
                          AttendanceRecord? todayRecord;
                          if (_isAdmin) {
                            for (final emp in _allEmployeeRecords) {
                              if (emp['emp_code']?.toString() == '1') {
                                final days = emp['days'] as List<dynamic>? ?? [];
                                for (final d in days) {
                                  final dayNum = d['day'] is int ? d['day'] as int : int.tryParse(d['day'].toString()) ?? -1;
                                  if (dayNum == now.day) {
                                    todayRecord = AttendanceRecord(
                                      date: todayFormatted,
                                      day: DateFormat('EEEE').format(now),
                                      checkIn: (d['check_in']?.toString() ?? '').isNotEmpty ? d['check_in'].toString() : '--',
                                      checkOut: (d['check_out']?.toString() ?? '').isNotEmpty ? d['check_out'].toString() : '--',
                                      status: 'Present', location: '', details: '',
                                      checkInLat: d['check_in_lat']?.toString() ?? '',
                                      checkInLong: d['check_in_long']?.toString() ?? '',
                                      checkInAdd: d['checkInAdd']?.toString() ?? '',
                                      checkOutLat: d['check_out_lat']?.toString() ?? '',
                                      checkOutLong: d['check_out_long']?.toString() ?? '',
                                      checkOutAdd: d['checkOutAdd']?.toString() ?? '',
                                    );
                                  }
                                }
                                break;
                              }
                            }
                          } else {
                            todayRecord = attendanceList.firstWhere(
                              (r) => r.date == todayFormatted,
                              orElse: () => AttendanceRecord(
                                date: todayFormatted,
                                day: DateFormat('EEEE').format(now),
                                checkIn: '--', checkOut: '--',
                                status: '', location: '', details: '',
                              ),
                            );
                          }
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CheckInScreen(
                                isCheckOut: alreadyCheckedIn,
                                existingRecord: alreadyCheckedIn ? todayRecord : null,
                              ),
                            ),
                          );
                          _fetchAttendanceData();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black87,
                          backgroundColor: Colors.transparent,
                          side: const BorderSide(color: Colors.black87, width: 2.0),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 20, height: 20,
                              decoration: const BoxDecoration(
                                color: AppColors.primaryText, shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.add, color: Colors.white, size: 14),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isAdmin ? 'My $actionText' : actionText,
                              style: TextStyle(
                                color: AppColors.secondaryText,
                                fontSize: 16, fontWeight: FontWeight.w500, fontFamily: 'serif',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

            // ─── CONTENT AREA ───────────────────────────────────────────────
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: AppColors.primaryText),
                          SizedBox(height: 16),
                          Text("Retrieving logs securely...",
                            style: TextStyle(fontFamily: 'serif', fontSize: 14, color: Colors.grey)),
                        ],
                      ),
                    )
                  : _errorMessage != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cloud_off_rounded, size: 64, color: Colors.redAccent.withOpacity(0.8)),
                            const SizedBox(height: 16),
                            const Text("Connection Problem",
                              style: TextStyle(fontFamily: 'serif', fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                            const SizedBox(height: 8),
                            Text(_errorMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontFamily: 'serif', fontSize: 13, color: Colors.grey)),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: _fetchAttendanceData,
                              icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 18),
                              label: const Text("Try Again",
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'serif')),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primaryText,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  // Admin views
                  : _isAdmin && _selectedTabIndex == 0
                  ? _buildAdminTodayList()
                  : _isAdmin && _selectedTabIndex == 1
                  ? _buildAdminMonthlyList()
                  : _isAdmin && _selectedTabIndex == 2
                  ? _buildAdminTodayList() // On Site uses same list for now
                  // Regular employee view
                  : filteredAttendance.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.fingerprint_rounded, size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 12),
                          Text('No Attendance Records Found',
                            style: TextStyle(color: Colors.grey[500], fontFamily: 'serif', fontSize: 16)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: filteredAttendance.length,
                      itemBuilder: (context, index) =>
                          _buildEnhancedAttendanceCard(filteredAttendance[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ NEW: Custom Tab Bar Widget
  Widget _buildCustomTabBar() {
    final List<String> tabTitles = [
      "Today",
      "Monthly",
      "On Site"
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      height: 45, // Fixed height for tabs
      decoration: BoxDecoration(
        color: Colors.grey[200], // Background for unselected tabs container
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: List.generate(tabTitles.length, (index) {
          final isSelected = _selectedTabIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTabIndex = index;
                });
                _fetchAttendanceData(); // ✅ Call fetch on tab click
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryText : Colors.transparent, // Red if selected, transparent if not
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  tabTitles[index],
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[700], // White if selected, Dark Grey if not
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    fontFamily: 'serif',
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // 🌟 MONTH & YEAR SELECTOR
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

  // 🌟 WORK HOURS SUMMARY CARD
  Widget _buildWorkHoursSummaryCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A), // Premium Dark Slate
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

  // 🌟 TOP HEADER CARDS (Greeting & Date, Location, Days of Month, Attendance Rate)
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
    // Simplify display location if it's too long
    if (latestLocation.length > 20) {
      latestLocation = latestLocation.substring(0, 18) + "...";
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        children: [
          // You can add specific header cards here if needed, currently empty as per original code structure
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

   // 🌟 ENHANCED ATTENDANCE CARD (SAME STRUCTURE AS CLIENT CARD)
   Widget _buildEnhancedAttendanceCard(AttendanceRecord record) {
     final parsedDate = DateFormat('yyyy-MM-dd').parse(record.date);
     final formattedDate = DateFormat('d MMMM yyyy').format(parsedDate);
     final isWorkRecord = record.status.toLowerCase() != 'holiday' && record.status.toLowerCase() != 'future';
     final isPendingCheckOut = record.checkOut == '--' && record.checkIn != '--';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // Status Top Bar
            Container(
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _getStatusColor(record.status),
                    _getStatusColor(record.status).withOpacity(0.6),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: _getStatusColor(record.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getStatusIcon(record.status),
                          color: _getStatusColor(record.status),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              formattedDate,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E293B),
                                fontFamily: 'serif',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today_rounded,
                                  size: 12,
                                  color: Color(0xFF94A3B8),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  record.day,
                                  style: const TextStyle(
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(record.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          record.status.toUpperCase(),
                          style: TextStyle(
                            color: _getStatusColor(record.status),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            fontFamily: 'serif',
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  if (isWorkRecord) ...[
                    // Info Grid (Check-In & Check-Out times + address)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.login_rounded, size: 14, color: Color(0xFF3B82F6)),
                                    const SizedBox(width: 6),
                                    const Text(
                                      'Punch-In',
                                      style: TextStyle(
                                        color: Color(0xFF64748B),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        fontFamily: 'serif',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  record.checkIn,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1E293B),
                                    fontFamily: 'serif',
                                  ),
                                ),
                                if (record.checkInAdd.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    record.checkInAdd,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF475569),
                                      fontFamily: 'serif',
                                      height: 1.3,
                                    ),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 70,
                            color: const Color(0xFFE2E8F0),
                            margin: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                           Expanded(
                             child: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                 Row(
                                   children: [
                                     const Icon(Icons.logout_rounded, size: 14, color: Color(0xFF10B981)),
                                     const SizedBox(width: 6),
                                     const Text(
                                       'Punch-Out',
                                       style: TextStyle(
                                         color: Color(0xFF64748B),
                                         fontSize: 11,
                                         fontWeight: FontWeight.w500,
                                         fontFamily: 'serif',
                                       ),
                                     ),
                                   ],
                                 ),
                                 const SizedBox(height: 6),
                                 // ✅ NEW: Check if checkout button should be shown
                                 if (isPendingCheckOut && !_checkoutCompletedDates.contains(record.date))
                                   ElevatedButton.icon(
                                     onPressed: () async {
                                       await Navigator.push(
                                         context,
                                         MaterialPageRoute(
                                           builder: (context) => CheckInScreen(
                                             isCheckOut: true,
                                             existingRecord: record,
                                           ),
                                         ),
                                       );
                                       _fetchAttendanceData();
                                     },
                                     icon: const Icon(Icons.logout_rounded, size: 14),
                                     label: const Text(
                                       'Punch-Out',
                                       style: TextStyle(
                                         fontSize: 12,
                                         fontWeight: FontWeight.w600,
                                         fontFamily: 'serif',
                                       ),
                                     ),
                                     style: ElevatedButton.styleFrom(
                                       backgroundColor: const Color(0xFF10B981),
                                       foregroundColor: Colors.white,
                                       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                       shape: RoundedRectangleBorder(
                                         borderRadius: BorderRadius.circular(8),
                                       ),
                                     ),
                                   )
                                 else
                                   Column(
                                     crossAxisAlignment: CrossAxisAlignment.start,
                                     children: [
                                       Text(
                                         record.checkOut,
                                         style: const TextStyle(
                                           fontSize: 14,
                                           fontWeight: FontWeight.w700,
                                           color: Color(0xFF1E293B),
                                           fontFamily: 'serif',
                                         ),
                                       ),
                                       if (record.checkOutAdd.isNotEmpty) ...[
                                         const SizedBox(height: 6),
                                         Text(
                                           record.checkOutAdd,
                                           style: const TextStyle(
                                             fontSize: 10,
                                             color: Color(0xFF475569),
                                             fontFamily: 'serif',
                                             height: 1.3,
                                           ),
                                           maxLines: 3,
                                           overflow: TextOverflow.ellipsis,
                                         ),
                                       ],
                                     ],
                                   ),
                               ],
                             ),
                           ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // ✅ UPDATED: Hours summary chips using correct API parameters
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildHoursBadge(
                            Icons.work_history_rounded,
                            "Worked: ${record.workedHr}", // ✅ Uses worked_hr from API
                            Colors.blueGrey[700]!,
                          ),
                          const SizedBox(width: 8),
                          _buildHoursBadge(
                            Icons.timer_rounded,
                            "Regular: ${record.regularHr}", // ✅ Uses regular_hr from API
                            Colors.indigo[600]!,
                          ),
                          const SizedBox(width: 8),
                          _buildHoursBadge(
                            Icons.more_time_rounded,
                            "OT: ${record.overtimeHr}", // ✅ Uses overtime_hr from API
                            Colors.purple[600]!,
                          ),
                          const SizedBox(width: 8),
                          // ── View icon inline after OT ──────────────────
                          GestureDetector(
                            onTap: () => _AttendanceDetailPopup.show(
                              context: context,
                              name: userName,
                              date: record.date,
                              day: record.day,
                              checkIn: record.checkIn,
                              checkOut: record.checkOut,
                              checkInLocation: record.checkInAdd,
                              checkOutLocation: record.checkOutAdd,
                              checkInSelfie: record.checkInSelfie,
                              checkOutSelfie: record.checkOutSelfie,
                              workedHr: record.workedHr,
                              regularHr: record.regularHr,
                              overtimeHr: record.overtimeHr,
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.3)),
                              ),
                              child: const Icon(Icons.fingerprint_rounded, size: 15, color: Color(0xFF3B82F6)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // Holiday display
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.amber[50],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.amber[100]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.star_rounded, color: Colors.amber[700], size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              record.details.isNotEmpty
                                  ? record.details
                                  : "Attendance Pending",
                              style: TextStyle(
                                color: Colors.amber[900],
                                fontSize: 12,
                                fontFamily: 'serif',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHoursBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              fontFamily: 'serif',
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════
  // ADMIN: Stats Banner – total employees, present today / absent today
  // ════════════════════════════════════════════════════════════════════
  Widget _buildAdminStatsBanner() {
    final now = DateTime.now();
    final todayDay = now.day;

    int totalEmployees = _allEmployeeRecords.length;
    int presentToday = 0;
    int absentToday = 0;

    for (final emp in _allEmployeeRecords) {
      final daysList = emp['days'] as List<dynamic>? ?? [];
      bool foundToday = false;
      for (final d in daysList) {
        final dayNum = d['day'] is int ? d['day'] as int : int.tryParse(d['day'].toString()) ?? -1;
        if (dayNum == todayDay) {
          foundToday = true;
          final raw = (d['status']?.toString() ?? '').toUpperCase();
          if (raw == 'P' || raw == 'LATE') {
            presentToday++;
          } else if (raw == 'A' || raw.isEmpty) {
            absentToday++;
          } else {
            presentToday++;
          }
          break;
        }
      }
      if (!foundToday) {
        absentToday++;
      }
    }

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
            child: const Icon(Icons.groups_rounded, color: Colors.amberAccent, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "TEAM ATTENDANCE SUMMARY",
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
                      "Total: $totalEmployees",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'serif',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      "Present: $presentToday",
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'serif',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      "Absent: $absentToday",
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 13,
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

  // ════════════════════════════════════════════════════════════════════
  // ADMIN: Today Tab – list of all employees with today's check-in/out
  // ════════════════════════════════════════════════════════════════════
  Widget _buildAdminTodayList() {
    if (_filteredEmployeeRecords.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline_rounded, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              _searchController.text.isNotEmpty ? 'No results found' : 'No Employee Records Found',
              style: TextStyle(color: Colors.grey[500], fontFamily: 'serif', fontSize: 16),
            ),
          ],
        ),
      );
    }

    final now = DateTime.now();
    final todayDay = now.day;
    final currentMonth = now.month;
    final currentYear = now.year;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: _filteredEmployeeRecords.length,
      itemBuilder: (context, index) {
        final emp = _filteredEmployeeRecords[index];
        final empName = emp['emp_name']?.toString() ?? 'Unknown';
        final empCode = emp['emp_code']?.toString() ?? '';
        final daysList = emp['days'] as List<dynamic>? ?? [];

        String checkIn = '--';
        String checkOut = '--';
        String status = 'Absent';
        String workedHr = '00:00';
        String regularHr = '00:00';
        String overtimeHr = '00:00';
        String checkInAdd = '';
        String checkOutAdd = '';

        for (final d in daysList) {
          final dayNum = d['day'] is int ? d['day'] as int : int.tryParse(d['day'].toString()) ?? -1;
          if (dayNum == todayDay) {
            final raw = (d['status']?.toString() ?? '').toUpperCase();
            if (raw == 'P' || raw == 'LATE') {
              status = raw == 'LATE' ? 'Late' : 'Present';
            } else if (raw == 'A') {
              status = 'Absent';
            } else if (raw == 'WO' || raw == 'WO-I' || raw == 'OFF') {
              status = 'Holiday';
            } else {
              status = raw.isEmpty ? 'Absent' : raw;
            }
            checkIn = (d['check_in']?.toString() ?? '').isNotEmpty ? d['check_in'].toString() : '--';
            checkOut = (d['check_out']?.toString() ?? '').isNotEmpty ? d['check_out'].toString() : '--';
            workedHr = (d['worked_hr']?.toString() ?? '').isNotEmpty ? d['worked_hr'].toString() : '00:00';
            regularHr = (d['regular_hr']?.toString() ?? '').isNotEmpty ? d['regular_hr'].toString() : '00:00';
            overtimeHr = (d['overtime_hr']?.toString() ?? '').isNotEmpty ? d['overtime_hr'].toString() : '00:00';
            checkInAdd = d['checkInAdd']?.toString() ?? '';
            checkOutAdd = d['checkOutAdd']?.toString() ?? '';
            break;
          }
        }

        // final dateStr = "$currentYear-${currentMonth.toString().padLeft(2, '0')}-${todayDay.toString().padLeft(2, '0')}";
        String dayName = '';
        try {
          dayName = DateFormat('EEEE').format(DateTime(currentYear, currentMonth, todayDay));
        } catch (_) {}

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              children: [
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getStatusColor(status),
                        _getStatusColor(status).withOpacity(0.6),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: _getStatusColor(status).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _getStatusIcon(status),
                              color: _getStatusColor(status),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  empName,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1E293B),
                                    fontFamily: 'serif',
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "ID: $empCode  •  $dayName, $todayDay ${DateFormat('MMMM yyyy').format(now)}",
                                  style: const TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 11,
                                    fontFamily: 'serif',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getStatusColor(status).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                color: _getStatusColor(status),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                                fontFamily: 'serif',
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (status.toLowerCase() != 'holiday') ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFF1F5F9)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.login_rounded, size: 14, color: Color(0xFF3B82F6)),
                                        SizedBox(width: 6),
                                        Text('Punch-In', style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w500, fontFamily: 'serif')),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    if (checkIn == '--')
                                      ElevatedButton.icon(
                                        onPressed: () async {
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => CheckInScreen(
                                                isCheckOut: false,
                                                empCode: empCode,
                                                empName: empName,
                                              ),
                                            ),
                                          );
                                          _fetchAttendanceData();
                                        },
                                        icon: const Icon(Icons.login_rounded, size: 14),
                                        label: const Text('Punch-In', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'serif')),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF3B82F6),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                      )
                                    else
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(checkIn, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1E293B), fontFamily: 'serif')),
                                          if (checkInAdd.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(checkInAdd, style: const TextStyle(fontSize: 10, color: Color(0xFF475569), fontFamily: 'serif'), maxLines: 2, overflow: TextOverflow.ellipsis),
                                          ],
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                              Container(width: 1, height: 70, color: const Color(0xFFE2E8F0), margin: const EdgeInsets.symmetric(horizontal: 12)),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(Icons.logout_rounded, size: 14, color: Color(0xFF10B981)),
                                        SizedBox(width: 6),
                                        Text('Punch-Out', style: TextStyle(color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w500, fontFamily: 'serif')),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    if (checkIn != '--' && checkOut == '--')
                                      ElevatedButton.icon(
                                        onPressed: () async {
                                          final dateStr = "$currentYear-${currentMonth.toString().padLeft(2, '0')}-${todayDay.toString().padLeft(2, '0')}";
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => CheckInScreen(
                                                isCheckOut: true,
                                                existingRecord: AttendanceRecord(
                                                  date: dateStr,
                                                  day: dayName,
                                                  checkIn: checkIn,
                                                  checkOut: '--',
                                                  status: status,
                                                  location: '',
                                                  details: '',
                                                  checkInAdd: checkInAdd,
                                                  checkOutAdd: checkOutAdd,
                                                ),
                                                empCode: empCode,
                                                empName: empName,
                                              ),
                                            ),
                                          );
                                          _fetchAttendanceData();
                                        },
                                        icon: const Icon(Icons.logout_rounded, size: 14),
                                        label: const Text('Punch-Out', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'serif')),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF10B981),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                      )
                                    else
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(checkOut, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1E293B), fontFamily: 'serif')),
                                          if (checkOutAdd.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(checkOutAdd, style: const TextStyle(fontSize: 10, color: Color(0xFF475569), fontFamily: 'serif'), maxLines: 2, overflow: TextOverflow.ellipsis),
                                          ],
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildHoursBadge(Icons.work_history_rounded, "Worked: $workedHr", Colors.blueGrey[700]!),
                              const SizedBox(width: 8),
                              _buildHoursBadge(Icons.timer_rounded, "Regular: $regularHr", Colors.indigo[600]!),
                              const SizedBox(width: 8),
                              _buildHoursBadge(Icons.more_time_rounded, "OT: $overtimeHr", Colors.purple[600]!),
                              const SizedBox(width: 8),
                              // ── View icon inline after OT ──────────────
                              GestureDetector(
                                onTap: () => _AttendanceDetailPopup.show(
                                  context: context,
                                  name: empName,
                                  date: "$currentYear-${currentMonth.toString().padLeft(2, '0')}-${todayDay.toString().padLeft(2, '0')}",
                                  day: dayName,
                                  checkIn: checkIn,
                                  checkOut: checkOut,
                                  checkInLocation: checkInAdd,
                                  checkOutLocation: checkOutAdd,
                                  checkInSelfie: '',
                                  checkOutSelfie: '',
                                  workedHr: workedHr,
                                  regularHr: regularHr,
                                  overtimeHr: overtimeHr,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.3)),
                                  ),
                                  child: const Icon(Icons.fingerprint_rounded, size: 15, color: Color(0xFF3B82F6)),
                                ),
                              ),
                            ],
                          ),
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

  // ════════════════════════════════════════════════════════════════════
  // ADMIN: Monthly Tab – per-employee monthly summary (expandable)
  // ════════════════════════════════════════════════════════════════════
  Widget _buildAdminMonthlyList() {
    if (_filteredEmployeeRecords.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline_rounded, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              _searchController.text.isNotEmpty ? 'No results found' : 'No Employee Records Found',
              style: TextStyle(color: Colors.grey[500], fontFamily: 'serif', fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: _filteredEmployeeRecords.length,
      itemBuilder: (context, index) {
        final emp = _filteredEmployeeRecords[index];
        return _AdminMonthlyEmployeeCard(
          emp: emp,
          getStatusColor: _getStatusColor,
          getStatusIcon: _getStatusIcon,
          getMonthNumber: getMonthNumber,
          getFriendlyStatus: getFriendlyStatus,
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════════
// Expandable monthly employee card (StatefulWidget for expand toggle)
// ════════════════════════════════════════════════════════════════════
class _AdminMonthlyEmployeeCard extends StatefulWidget {
  final Map<String, dynamic> emp;
  final Color Function(String) getStatusColor;
  final IconData Function(String) getStatusIcon;
  final int Function(String) getMonthNumber;
  final String Function(String, int, int, int) getFriendlyStatus;

  const _AdminMonthlyEmployeeCard({
    required this.emp,
    required this.getStatusColor,
    required this.getStatusIcon,
    required this.getMonthNumber,
    required this.getFriendlyStatus,
  });

  @override
  State<_AdminMonthlyEmployeeCard> createState() => _AdminMonthlyEmployeeCardState();
}

class _AdminMonthlyEmployeeCardState extends State<_AdminMonthlyEmployeeCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final emp = widget.emp;
    final empName = emp['emp_name']?.toString() ?? 'Unknown';
    final empCode = emp['emp_code']?.toString() ?? '';
    final totalRegularHr = emp['total_regular_hr']?.toString() ?? '00:00';
    final totalOvertimeHr = emp['total_overtime_hr']?.toString() ?? '00:00';
    final daysList = emp['days'] as List<dynamic>? ?? [];

    int presentCount = 0;
    int absentCount = 0;
    int holidayCount = 0;
    int leaveCount = 0;

    for (final d in daysList) {
      final raw = (d['status']?.toString() ?? '').toUpperCase();
      if (raw == 'P' || raw == 'LATE') {
        presentCount++;
      } else if (raw == 'A' || raw.isEmpty) {
        absentCount++;
      } else if (raw == 'WO' || raw == 'WO-I' || raw == 'OFF') {
        holidayCount++;
      } else if (raw == 'LV' || raw == 'LEAVE') {
        leaveCount++;
      } else {
        presentCount++;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.person_rounded, color: Color(0xFF3B82F6), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              empName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E293B),
                                fontFamily: 'serif',
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "ID: $empCode",
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 11,
                                fontFamily: 'serif',
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        _isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                        color: Colors.grey[500],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildStatChip("Present", presentCount, Colors.green),
                        const SizedBox(width: 8),
                        _buildStatChip("Absent", absentCount, Colors.red),
                        const SizedBox(width: 8),
                        _buildStatChip("Holiday", holidayCount, Colors.grey),
                        const SizedBox(width: 8),
                        _buildStatChip("Leave", leaveCount, Colors.blue),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.timer_rounded, size: 14, color: Colors.indigo[600]),
                      const SizedBox(width: 6),
                      Text(
                        "Regular: $totalRegularHr",
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.indigo[600], fontFamily: 'serif'),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.more_time_rounded, size: 14, color: Colors.purple[600]),
                      const SizedBox(width: 6),
                      Text(
                        "OT: $totalOvertimeHr",
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.purple[600], fontFamily: 'serif'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded) ...[
            const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
            _buildExpandedDaysList(daysList),
          ],
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Text(
        "$label: $count",
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          fontFamily: 'serif',
        ),
      ),
    );
  }

  Widget _buildExpandedDaysList(List<dynamic> daysList) {
    if (daysList.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No day-level data available', style: TextStyle(color: Colors.grey, fontFamily: 'serif', fontSize: 12)),
      );
    }

    final sortedDays = List<Map<String, dynamic>>.from(daysList);
    sortedDays.sort((a, b) {
      final aDay = a['day'] is int ? a['day'] as int : int.tryParse(a['day'].toString()) ?? 0;
      final bDay = b['day'] is int ? b['day'] as int : int.tryParse(b['day'].toString()) ?? 0;
      return aDay.compareTo(bDay);
    });

    final now = DateTime.now();
    final recordMonthStr = widget.emp['month']?.toString() ?? DateFormat('MMMM').format(now);
    final recordYearStr = widget.emp['year']?.toString() ?? DateFormat('yyyy').format(now);
    final selectedMonthNum = widget.getMonthNumber(recordMonthStr);
    final selectedYearNum = int.tryParse(recordYearStr) ?? now.year;

    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      child: ListView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: sortedDays.length,
        itemBuilder: (context, index) {
          final d = sortedDays[index];
          final dayNum = d['day'] is int ? d['day'] as int : int.tryParse(d['day'].toString()) ?? 1;
          final raw = (d['status']?.toString() ?? '');
          final friendly = widget.getFriendlyStatus(raw, dayNum, selectedMonthNum, selectedYearNum);
          final checkIn = (d['check_in']?.toString() ?? '').isNotEmpty ? d['check_in'].toString() : '--';
          final checkOut = (d['check_out']?.toString() ?? '').isNotEmpty ? d['check_out'].toString() : '--';
          final workedHr = (d['worked_hr']?.toString() ?? '').isNotEmpty ? d['worked_hr'].toString() : '00:00';
          final regularHr = (d['regular_hr']?.toString() ?? '').isNotEmpty ? d['regular_hr'].toString() : '00:00';
          final overtimeHr = (d['overtime_hr']?.toString() ?? '').isNotEmpty ? d['overtime_hr'].toString() : '00:00';

          String dayName = '';
          try {
            dayName = DateFormat('EEE').format(DateTime(selectedYearNum, selectedMonthNum, dayNum));
          } catch (_) {}

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Text(
                    '$dayNum',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B), fontFamily: 'serif'),
                  ),
                ),
                SizedBox(
                  width: 36,
                  child: Text(dayName, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontFamily: 'serif')),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: widget.getStatusColor(friendly).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    friendly.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: widget.getStatusColor(friendly),
                      fontFamily: 'serif',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        checkIn != '--' ? '$checkIn – $checkOut' : '--',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF475569), fontFamily: 'serif'),
                      ),
                      if (checkIn != '--') ...[
                        const SizedBox(height: 2),
                        Text(
                          'W:$workedHr  R:$regularHr  OT:$overtimeHr',
                          style: TextStyle(fontSize: 9, color: Colors.indigo[400], fontFamily: 'serif', fontWeight: FontWeight.w600),
                        ),
                      ],
                    ],
                  ),
                ),
                // ── View icon ──────────────────────────────────────────
                if (checkIn != '--')
                  GestureDetector(
                    onTap: () {
                      final empName = widget.emp['emp_name']?.toString() ?? 'Employee';
                      final checkInAdd = d['checkInAdd']?.toString() ?? '';
                      final checkOutAdd = d['checkOutAdd']?.toString() ?? '';
                      final checkInSelfie = d['check_in_selfie']?.toString() ?? '';
                      final checkOutSelfie = d['check_out_selfie']?.toString() ?? '';
                      final dateStr = '$selectedYearNum-${selectedMonthNum.toString().padLeft(2, '0')}-${dayNum.toString().padLeft(2, '0')}';
                      _AttendanceDetailPopup.show(
                        context: context,
                        name: empName,
                        date: dateStr,
                        day: dayName,
                        checkIn: checkIn,
                        checkOut: checkOut,
                        checkInLocation: checkInAdd,
                        checkOutLocation: checkOutAdd,
                        checkInSelfie: checkInSelfie,
                        checkOutSelfie: checkOutSelfie,
                        workedHr: workedHr,
                        regularHr: regularHr,
                        overtimeHr: overtimeHr,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: const Icon(Icons.fingerprint_rounded, size: 14, color: Color(0xFF3B82F6)),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
} // end _AdminMonthlyEmployeeCardState

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

// ════════════════════════════════════════════════════════════════════
// ATTENDANCE DETAIL POPUP
// ════════════════════════════════════════════════════════════════════

class _AttendanceDetailPopup {
  static void show({
    required BuildContext context,
    required String name,
    required String date,
    required String day,
    required String checkIn,
    required String checkOut,
    required String checkInLocation,
    required String checkOutLocation,
    required String checkInSelfie,
    required String checkOutSelfie,
    required String workedHr,
    required String regularHr,
    required String overtimeHr,
  }) {
    String formattedDate = date;
    try {
      formattedDate = DateFormat('d MMMM yyyy').format(DateFormat('yyyy-MM-dd').parse(date));
    } catch (_) {}

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header ────────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[200]!, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: const TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'serif'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name,
                              style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'serif')),
                          const SizedBox(height: 3),
                          Text('$formattedDate  •  $day',
                              style: TextStyle(color: Colors.grey[600], fontSize: 12, fontFamily: 'serif')),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close_rounded, color: Colors.grey[700], size: 20),
                    ),
                  ],
                ),
              ),
              // ── Scrollable body ───────────────────────────────────────
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hours summary chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _chip(Icons.work_history_rounded, 'Worked', workedHr, Colors.blueGrey[700]!),
                            const SizedBox(width: 8),
                            _chip(Icons.timer_rounded, 'Regular', regularHr, const Color(0xFF4338CA)),
                            const SizedBox(width: 8),
                            _chip(Icons.more_time_rounded, 'OT', overtimeHr, const Color(0xFF7C3AED)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      // Punch-In / Punch-Out side by side
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _punchSection(
                            label: 'Punch-In',
                            icon: Icons.login_rounded,
                            iconColor: const Color(0xFF3B82F6),
                            time: checkIn,
                            location: checkInLocation,
                            selfieUrl: checkInSelfie,
                          )),
                          const SizedBox(width: 12),
                          Expanded(child: _punchSection(
                            label: 'Punch-Out',
                            icon: Icons.logout_rounded,
                            iconColor: const Color(0xFF10B981),
                            time: checkOut,
                            location: checkOutLocation,
                            selfieUrl: checkOutSelfie,
                          )),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _chip(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text('$label: $value',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color, fontFamily: 'serif')),
        ],
      ),
    );
  }

  static Widget _punchSection({
    required String label,
    required IconData icon,
    required Color iconColor,
    required String time,
    required String location,
    required String selfieUrl,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: iconColor.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          Row(
            children: [
              Icon(icon, size: 14, color: iconColor),
              const SizedBox(width: 5),
              Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: iconColor, fontFamily: 'serif')),
            ],
          ),
          const SizedBox(height: 10),
          // Selfie image
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: selfieUrl.isNotEmpty
                ? Image.network(
                    selfieUrl,
                    height: 110,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _selfieplaceholder(iconColor),
                  )
                : _selfieplaceholder(iconColor),
          ),
          const SizedBox(height: 10),
          // Time
          Row(
            children: [
              Icon(Icons.access_time_rounded, size: 13, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Text(time.isNotEmpty ? time : '--',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1E293B), fontFamily: 'serif')),
            ],
          ),
          const SizedBox(height: 6),
          // Location
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.location_on_outlined, size: 13, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  location.isNotEmpty ? location : 'Location not available',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600], fontFamily: 'serif', height: 1.4),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _selfieplaceholder(Color color) {
    return Container(
      height: 110,
      width: double.infinity,
      color: color.withValues(alpha: 0.06),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_outline_rounded, size: 36, color: color.withValues(alpha: 0.4)),
          const SizedBox(height: 4),
          Text('No selfie', style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.5), fontFamily: 'serif')),
        ],
      ),
    );
  }
}
