import 'package:flutter/material.dart';
import 'package:nlf/utils/colors.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import 'package:intl/intl.dart';

class UpcomingBirthdayScreen extends StatefulWidget {
  const UpcomingBirthdayScreen({super.key});

  @override
  State<UpcomingBirthdayScreen> createState() => _UpcomingBirthdayScreenState();
}

class _UpcomingBirthdayScreenState extends State<UpcomingBirthdayScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<BirthdayRecord> allBirthdays = [];
  List<BirthdayRecord> filteredBirthdays = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUpcomingBirthdays();
  }

  Future<void> _loadUpcomingBirthdays() async {
    try {
      setState(() => _isLoading = true);
      
      final response = await http.get(
        Uri.parse(AppConstants.UPCOMING_BIRTHDAYS_API),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == true) {
          final List<dynamic> birthdayList = data['birthdays'] ?? [];
          
          final list = birthdayList.map((item) => BirthdayRecord(
            empId: item['emp_id']?.toString() ?? '',
            name: item['name']?.toString() ?? 'Unknown',
            dob: item['dob']?.toString() ?? '',
            birthdayThisYear: item['birthday_this_year']?.toString() ?? '',
            daysLeft: item['days_left']?.toString() ?? '0',
          )).toList();
          
          // Sort by days left (ascending - nearest birthdays first)
          list.sort((a, b) {
            final daysA = int.tryParse(a.daysLeft) ?? 999;
            final daysB = int.tryParse(b.daysLeft) ?? 999;
            return daysA.compareTo(daysB);
          });
          
          setState(() {
            allBirthdays = list;
            filteredBirthdays = list;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading upcoming birthdays: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterBirthdays(String query) {
    setState(() {
      filteredBirthdays = allBirthdays.where((birthday) {
        final q = query.toLowerCase();
        return birthday.name.toLowerCase().contains(q);
      }).toList();
    });
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('d MMM yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  String _formatBirthdayDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('d MMM').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  Color _getDaysLeftColor(int daysLeft) {
    if (daysLeft == 0) return Colors.red;
    if (daysLeft <= 3) return Colors.orange;
    if (daysLeft <= 7) return Colors.blue;
    return Colors.green;
  }

  String _getDaysLeftText(int daysLeft) {
    if (daysLeft == 0) return 'Today!';
    if (daysLeft == 1) return 'Tomorrow';
    return '$daysLeft days';
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
          "Upcoming Birthdays",
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
            // Search Bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: AppColors.primaryText, width: 1.5),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 15),
                  Icon(Icons.search, color: AppColors.primaryText, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: _filterBirthdays,
                      decoration: InputDecoration(
                        hintText: 'Search by Employee Name...',
                        hintStyle: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 14,
                          fontFamily: 'serif',
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                      ),
                      style: const TextStyle(fontSize: 14, fontFamily: 'serif'),
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(Icons.clear, size: 18, color: Colors.grey[600]),
                      onPressed: () {
                        _searchController.clear();
                        _filterBirthdays('');
                      },
                    )
                  else
                    const SizedBox(width: 15),
                ],
              ),
            ),

            // Record count badge
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primaryText.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primaryText.withOpacity(0.3)),
              ),
              child: Text(
                'Showing ${filteredBirthdays.length} upcoming birthdays',
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 12,
                  fontFamily: 'serif',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // List
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: AppColors.primaryText))
                  : filteredBirthdays.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: filteredBirthdays.length,
                          itemBuilder: (context, index) =>
                              _buildBirthdayCard(filteredBirthdays[index]),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBirthdayCard(BirthdayRecord birthday) {
    final daysLeft = int.tryParse(birthday.daysLeft) ?? 0;
    final daysLeftColor = _getDaysLeftColor(daysLeft);

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {},
            splashColor: daysLeftColor.withOpacity(0.1),
            child: Column(
              children: [
                // Top color bar
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 4,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        daysLeftColor,
                        daysLeftColor.withOpacity(0.7),
                        daysLeftColor.withOpacity(0.4),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header row with birthday icon and days left badge
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: daysLeftColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.cake_rounded,
                              color: daysLeftColor,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  birthday.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1E293B),
                                    fontFamily: 'serif',
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.person_outline_rounded,
                                      size: 12,
                                      color: Colors.grey[700],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Employee ID: ${birthday.empId}',
                                      style: TextStyle(
                                        color: Colors.grey[700],
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
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: daysLeftColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: daysLeftColor.withOpacity(0.4)),
                            ),
                            child: Text(
                              _getDaysLeftText(daysLeft),
                              style: TextStyle(
                                color: daysLeftColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'serif',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Birthday details
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildInfoItem(
                                    icon: Icons.calendar_today_rounded,
                                    label: 'Date of Birth',
                                    value: _formatDate(birthday.dob),
                                    iconColor: const Color(0xFF3B82F6),
                                  ),
                                ),
                                Container(width: 1, height: 36, color: Colors.grey[200], margin: const EdgeInsets.symmetric(horizontal: 8)),
                                Expanded(
                                  child: _buildInfoItem(
                                    icon: Icons.celebration_rounded,
                                    label: 'This Year Birthday',
                                    value: _formatBirthdayDate(birthday.birthdayThisYear),
                                    iconColor: const Color(0xFF10B981),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildInfoItem(
                              icon: Icons.timer_rounded,
                              label: 'Days Remaining',
                              value: _getDaysLeftText(daysLeft),
                              iconColor: daysLeftColor,
                              isFullWidth: true,
                            ),
                          ],
                        ),
                      ),
                      
                      // Celebration note for today/tomorrow birthdays
                      if (daysLeft <= 1) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: daysLeftColor.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: daysLeftColor.withOpacity(0.2)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.celebration, color: daysLeftColor, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  daysLeft == 0 
                                    ? "🎉 It's ${birthday.name}'s birthday today! Don't forget to wish them!"
                                    : "🎂 ${birthday.name}'s birthday is tomorrow! Get ready to celebrate!",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: daysLeftColor,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'serif',
                                  ),
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
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
    bool isFullWidth = false,
  }) {
    return Container(
      padding: isFullWidth 
          ? EdgeInsets.zero 
          : const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 13, color: iconColor),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                    fontFamily: 'serif',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                    fontFamily: 'serif',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cake_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No upcoming birthdays',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
              fontFamily: 'serif',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isNotEmpty 
                ? 'Try adjusting your search'
                : 'No birthdays found for the upcoming period',
            style: TextStyle(fontSize: 14, color: Colors.grey[500], fontFamily: 'serif'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class BirthdayRecord {
  final String empId;
  final String name;
  final String dob;
  final String birthdayThisYear;
  final String daysLeft;

  BirthdayRecord({
    required this.empId,
    required this.name,
    required this.dob,
    required this.birthdayThisYear,
    required this.daysLeft,
  });
}