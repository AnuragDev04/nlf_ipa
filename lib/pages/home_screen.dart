import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nlf/pages/attendance_main_screen.dart';
import 'package:nlf/pages/backoffice_main_screen.dart';
import 'package:nlf/pages/dm_screen.dart';
import 'package:nlf/pages/lead_screen_add.dart';
import 'package:nlf/pages/admin_main_screen.dart';
import 'package:nlf/pages/client_screen.dart';
import 'package:nlf/pages/lead_main_screen.dart';
import 'package:nlf/pages/master_screen.dart';
import 'package:nlf/pages/material_main_screen.dart';
import 'package:nlf/pages/order_confirm_screen.dart';
import 'package:nlf/pages/quotation.dart';
import 'package:nlf/pages/site_screen.dart';
import '../utils/colors.dart';
import 'hr_main_screen.dart';
import 'attendance_screen.dart';
import 'leave_approvals.dart';
import 'new_claim_screen.dart';
import 'login.dart';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../utils/constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, bool> _permissions = {
    'dashboard': true,
    'master': true,
    'admin': true,
    'lead': true,
    'backoffice': true,
    'accounts': true,
    'material': true,
    'dispatch': true,
    'site': true,
    'hr': true,
    'reports': true,
    'attendance': true,
    'notifications': true,
  };

  String _userRole = '';

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _loadCachedPermissions();
    _fetchAndCachePermissions();
  }

  Future<void> _loadUserRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final role = prefs.getString('role') ?? '';
      setState(() {
        _userRole = role;
      });
    } catch (e) {
      debugPrint("Error loading user role: $e");
    }
  }

  Future<void> _loadCachedPermissions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString('role_permissions_cache');
      if (cachedJson != null) {
        final Map<String, dynamic> decoded = json.decode(cachedJson);
        setState(() {
          _permissions = decoded.map((key, value) => MapEntry(key, value == true));
        });
      }
    } catch (e) {
      debugPrint("Error loading cached permissions: $e");
    }
  }

  Future<void> _fetchAndCachePermissions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userRoleName = prefs.getString('role') ?? '';
      if (userRoleName.isEmpty) return;

      final response = await http.get(Uri.parse(AppConstants.ROLE_MANAGEMENT_API));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded['status'] == true && decoded['data'] is List) {
          final list = decoded['data'] as List;
          final roleEntry = list.firstWhere(
            (element) => element['role_name']?.toString().toLowerCase().trim() == userRoleName.toLowerCase().trim(),
            orElse: () => null,
          );

          if (roleEntry != null) {
            final Map<String, bool> newPermissions = {
              'dashboard': roleEntry['dashboard'] == '1',
              'master': roleEntry['master'] == '1',
              'admin': roleEntry['admin'] == '1',
              'lead': roleEntry['lead'] == '1',
              'backoffice': roleEntry['backoffice'] == '1',
              'accounts': roleEntry['accounts'] == '1',
              'material': roleEntry['material'] == '1',
              'dispatch': roleEntry['dispatch'] == '1',
              'site': roleEntry['site'] == '1',
              'hr': roleEntry['hr'] == '1',
              'reports': roleEntry['reports'] == '1',
              'attendance': roleEntry['attendance'] == '1',
              'notifications': roleEntry['notifications'] == '1',
            };

            setState(() {
              _permissions = newPermissions;
            });

            await prefs.setString('role_permissions_cache', json.encode(newPermissions));
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching permissions: $e");
    }
  }

  Future<void> _handleRefresh() async {
    await _fetchAndCachePermissions();
  }

  Future<void> _handleLogout(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Clear all user data from SharedPreferences
      await prefs.clear();

      if (context.mounted) {
        // Navigate to login screen and remove all previous routes
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error logging out: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging out: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFFB91C1C); // Elegant Deep Red
    final accentColor = const Color(0xFFF87171); // Soft Red Accent
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFFEFCFC),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        color: primaryColor,
        child: CustomScrollView(
          slivers: [
            // ✨ Elegant Compact Header
            _buildElegantHeader(context, primaryColor, accentColor, isDark),

            // ✨ Stats Grid with Elegant Cards
            _permissions['dashboard'] == true
                ? _buildElegantStatsGrid(primaryColor, accentColor, isDark)
                : const SliverToBoxAdapter(child: SizedBox.shrink()),

            // ✨ Quick Actions with Hover Effects
            _buildElegantQuickActions(
              context,
              primaryColor,
              accentColor,
              isDark,
            ),

            // ✨ Modules Section with Elegant Cards
            _buildElegantModulesSection(
              context,
              primaryColor,
              accentColor,
              isDark,
            ),

            // ✨ Activity Feed with Timeline Style
            _buildElegantActivityFeed(primaryColor, accentColor, isDark),

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ✨ Helper method to format dashboard title based on role
  // ═══════════════════════════════════════════════════════════
  String _getDashboardTitle() {
    if (_userRole.isEmpty) return 'Dashboard';

    // Format role name: "admin" -> "Admin", "hr_manager" -> "HR Manager", etc.
    final formattedRole = _userRole
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');

    return '$formattedRole Dashboard';
  }

  // ═══════════════════════════════════════════════════════════
  // ✨ ELEGANT COMPACT HEADER
  // ═══════════════════════════════════════════════════════════
  Widget _buildElegantHeader(
    BuildContext context,
    Color primaryColor,
    Color accentColor,
    bool isDark,
  ) {
    return SliverAppBar(
      expandedHeight: 65,
      pinned: true,
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            border: Border(
              bottom: BorderSide(
                color: primaryColor.withOpacity(0.15),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Title with elegant accent line
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getDashboardTitle(),
                        style: GoogleFonts.lora(
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF1F2937),
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        width: 45,
                        height: 2,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [primaryColor, accentColor],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),

                  // Elegant profile button with logout option - Available for all users
                  Material(
                    color: Colors.transparent,
                    child: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'logout') {
                          _handleLogout(context);
                        }
                      },
                      itemBuilder: (BuildContext context) => [
                        PopupMenuItem<String>(
                          value: 'logout',
                          child: Row(
                            children: [
                              Icon(
                                Icons.logout,
                                color: primaryColor,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Logout',
                                style: GoogleFonts.lora(
                                  color: primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: primaryColor.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.account_circle_rounded,
                          color: primaryColor,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ✨ ELEGANT STATS GRID
  // ═══════════════════════════════════════════════════════════
  Widget _buildElegantStatsGrid(
    Color primaryColor,
    Color accentColor,
    bool isDark,
  ) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.25, // Fixed overflow by increasing card height
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        delegate: SliverChildListDelegate([
          _buildElegantStatCard(
            '24',
            'Pending PO',
            Icons.pending_actions_rounded,
            const Color(0xFFFB923C),
            '+12%',
            isDark,
          ),
          _buildElegantStatCard(
            '6',
            'Active Sites',
            Icons.construction_rounded,
            const Color(0xFF22C55E),
            '+3',
            isDark,
          ),
          _buildElegantStatCard(
            '3.4K',
            'In Stock',
            Icons.inventory_2_rounded,
            const Color(0xFF3B82F6),
            '✓',
            isDark,
          ),
          _buildElegantStatCard(
            '₹80L',
            'Pending Due',
            Icons.account_balance_wallet_rounded,
            primaryColor,
            '⚠',
            isDark,
          ),
        ]),
      ),
    );
  }

  Widget _buildElegantStatCard(
    String value,
    String label,
    IconData icon,
    Color accentColor,
    String badge,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.grey.withOpacity(0.15)
              : const Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : const Color(0xFFE5E7EB))
                .withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Icon with elegant background
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accentColor.withOpacity(0.15),
                      accentColor.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: accentColor.withOpacity(0.25),
                    width: 1,
                  ),
                ),
                child: Icon(icon, color: accentColor, size: 19),
              ),
              // Badge with elegant style
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: accentColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  badge,
                  style: GoogleFonts.lora(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: accentColor,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          // Value with elegant typography
          Text(
            value,
            style: GoogleFonts.lora(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF111827),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          // Label
          Text(
            label,
            style: GoogleFonts.lora(
              fontSize: 10,
              fontWeight: FontWeight.w400,
              color: Colors.grey[500],
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ✨ ELEGANT QUICK ACTIONS
  // ═══════════════════════════════════════════════════════════
  Widget _buildElegantQuickActions(
    BuildContext context,
    Color primaryColor,
    Color accentColor,
    bool isDark,
  ) {
    final List<Widget> activeActions = [];



    if (_permissions['backoffice'] == true) {
      activeActions.add(
        _buildElegantActionItem(
          'Back Office',
          Icons.note_add_rounded,
          const Color(0xFF14B8A6),
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => BackofficeMainScreen()),
          ),
          isDark,
        ),
      );
    }

    if (_permissions['accounts'] == true) {
      activeActions.add(
        _buildElegantActionItem(
          'Accounts',
          Icons.account_balance_rounded,
          const Color(0xFF8B5CF6),
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AddLeadScreen()),
          ),
          isDark,
        ),
      );
    }

    if (_permissions['material'] == true) {
      activeActions.add(
        _buildElegantActionItem(
          'Materials',
          Icons.category_rounded,
          const Color(0xFFFB923C),
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => MaterialMainScreen()),
          ),
          isDark,
        ),
      );
    }

    if (_permissions['dispatch'] == true) {
      activeActions.add(
        _buildElegantActionItem(
          'Dispatch',
          Icons.local_shipping_rounded,
          const Color(0xFF06B6D4),
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => DmScreen()),
          ),
          isDark,
        ),
      );
    }

    if (_permissions['hr'] == true) {
      activeActions.add(
        _buildElegantActionItem(
          'HR',
          Icons.people_rounded,
          const Color(0xFFEC4899),
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => HrMainScreen()),
          ),
          isDark,
        ),
      );
    }

    if (_permissions['attendance'] == true) {
      activeActions.add(
        _buildElegantActionItem(
          'Attendance',
          Icons.fingerprint_rounded,
          const Color(0xFF0D9488),
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AttendanceMainScreen()),
          ),
          isDark,
        ),
      );
    }

    if (_permissions['site'] == true) {
      activeActions.add(
        _buildElegantActionItem(
          'Site Management',
          Icons.location_on_rounded,
          const Color(0xFFD97706),
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SiteScreen()),
          ),
          isDark,
        ),
      );
    }

    if (activeActions.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final List<Widget> rows = [];
    for (int i = 0; i < activeActions.length; i += 3) {
      final end = (i + 3 < activeActions.length) ? i + 3 : activeActions.length;
      final chunk = activeActions.sublist(i, end);

      while (chunk.length < 3) {
        chunk.add(const SizedBox.shrink());
      }

      rows.add(_buildElegantActionRow(chunk));
      if (end < activeActions.length) {
        rows.add(const SizedBox(height: 10));
      }
    }

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildElegantSectionHeader('Quick Actions', primaryColor),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? Colors.grey.withOpacity(0.15)
                      : const Color(0xFFE5E7EB),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? Colors.black : const Color(0xFFE5E7EB))
                        .withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: rows,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildElegantActionRow(List<Widget> actions) {
    return Row(
      children: actions
          .expand(
            (action) => [Expanded(child: action), const SizedBox(width: 10)],
          )
          .take(actions.length * 2 - 1)
          .toList(),
    );
  }

  Widget _buildElegantActionItem(
    String label,
    IconData icon,
    Color accentColor,
    VoidCallback onTap,
    bool isDark,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [accentColor.withOpacity(0.06), Colors.transparent],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accentColor.withOpacity(0.15), width: 1),
          ),
          child: Column(
            children: [
              // Icon with elegant container
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withOpacity(0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
              const SizedBox(height: 8),
              // Label with serif elegance
              Text(
                label,
                style: GoogleFonts.lora(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.grey[300] : const Color(0xFF374151),
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ✨ ELEGANT MODULES SECTION
  // ═══════════════════════════════════════════════════════════
  Widget _buildElegantModulesSection(
    BuildContext context,
    Color primaryColor,
    Color accentColor,
    bool isDark,
  ) {
    final List<Widget> activeModules = [];

    if (_permissions['lead'] == true) {
      activeModules.add(
        _buildElegantModuleCard(
          'Lead Gen',
          'Manage leads',
          Icons.leaderboard_rounded,
          const Color(0xFF3B82F6),
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => LeadMainScreen()),
          ),
          isDark,
        ),
      );
    }

    if (_permissions['admin'] == true) {
      activeModules.add(
        _buildElegantModuleCard(
          'Admin',
          'Settings',
          Icons.admin_panel_settings_rounded,
          const Color(0xFFA855F7),
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => AdminScreen()),
          ),
          isDark,
        ),
      );
    }

    if (_permissions['master'] == true) {
      activeModules.add(
        _buildElegantModuleCard(
          'Master',
          'Data',
          Icons.storage_rounded,
          const Color(0xFFFB923C),
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => MasterScreen()),
          ),
          isDark,
        ),
      );
    }

    if (activeModules.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final List<Widget> rows = [];
    for (int i = 0; i < activeModules.length; i += 2) {
      final end = (i + 2 < activeModules.length) ? i + 2 : activeModules.length;
      final chunk = activeModules.sublist(i, end);

      while (chunk.length < 2) {
        chunk.add(const SizedBox.shrink());
      }

      rows.add(_buildElegantModuleRow(chunk));
      if (end < activeModules.length) {
        rows.add(const SizedBox(height: 10));
      }
    }

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildElegantSectionHeader('Modules', primaryColor),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: rows,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildElegantModuleRow(List<Widget> cards) {
    return Row(
      children: cards
          .expand((card) => [Expanded(child: card), const SizedBox(width: 10)])
          .take(cards.length * 2 - 1)
          .toList(),
    );
  }

  Widget _buildElegantModuleCard(
    String title,
    String subtitle,
    IconData icon,
    Color accentColor,
    VoidCallback onTap,
    bool isDark,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? Colors.grey.withOpacity(0.15)
                  : const Color(0xFFE5E7EB),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: (isDark ? Colors.black : const Color(0xFFE5E7EB))
                    .withOpacity(0.25),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon container with gradient
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accentColor.withOpacity(0.15),
                      accentColor.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: accentColor.withOpacity(0.25),
                    width: 1,
                  ),
                ),
                child: Icon(icon, color: accentColor, size: 19),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.lora(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF1F2937),
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: GoogleFonts.lora(
                        fontSize: 10,
                        color: Colors.grey[500],
                        height: 1.4,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Elegant chevron
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey[400],
                  size: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ✨ ELEGANT ACTIVITY FEED
  // ═══════════════════════════════════════════════════════════
  Widget _buildElegantActivityFeed(
    Color primaryColor,
    Color accentColor,
    bool isDark,
  ) {
    return const SliverToBoxAdapter(child: SizedBox.shrink());
  }

  Widget _buildElegantActivityItem(
    String title,
    String subtitle,
    IconData icon,
    Color accentColor,
    String time,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.grey.withOpacity(0.15)
              : const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Timeline dot with accent
          Container(
            margin: const EdgeInsets.only(right: 10),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: accentColor.withOpacity(0.25),
                      width: 1,
                    ),
                  ),
                  child: Icon(icon, color: accentColor, size: 16),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.lora(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.lora(
                    fontSize: 9,
                    color: Colors.grey[500],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          // Elegant time badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              time,
              style: GoogleFonts.lora(
                fontSize: 9,
                fontWeight: FontWeight.w400,
                color: Colors.grey[500],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ✨ ELEGANT SECTION HEADER
  // ═══════════════════════════════════════════════════════════
  Widget _buildElegantSectionHeader(String title, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Row(
        children: [
          // Elegant pill with gradient
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, primaryColor.withOpacity(0.85)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Text(
              title,
              style: GoogleFonts.lora(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                fontStyle: FontStyle.italic,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
