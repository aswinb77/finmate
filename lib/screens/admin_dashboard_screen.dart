import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/app_user.dart';
import '../models/bug_report.dart';
import '../services/auth_service.dart';
import '../services/local_storage_service.dart';
import '../services/sync_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AuthService _auth = AuthService();
  final LocalStorageService _storage = LocalStorageService();
  final SyncService _sync = SyncService();

  List<AppUser> _users = [];
  List<BugReport> _bugReports = [];
  int _aggregatedTotalEntries = 0;
  bool _isLoading = true;

  String _bugFilter = 'all'; // "all", "open", "in_progress", "resolved"

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDashboardData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final usersList = await _storage.getAllUsers();
      final bugsList = await _storage.getAllBugReports();
      final totalEntries = await _sync.fetchAggregatedCounterDoc();

      if (mounted) {
        setState(() {
          _users = usersList;
          _bugReports = bugsList;
          _aggregatedTotalEntries = totalEntries;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading admin dashboard data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int get _activeLast24h {
    final threshold = DateTime.now().subtract(const Duration(hours: 24));
    return _users.where((u) => u.lastActiveAt.isAfter(threshold)).length;
  }

  int get _activeLast7d {
    final threshold = DateTime.now().subtract(const Duration(days: 7));
    return _users.where((u) => u.lastActiveAt.isAfter(threshold)).length;
  }

  List<BugReport> get _filteredBugReports {
    if (_bugFilter == 'all') return _bugReports;
    return _bugReports.where((b) => b.status == _bugFilter).toList();
  }

  Future<void> _updateBugStatus(String id, String newStatus) async {
    await _storage.updateBugReportStatus(id, newStatus);
    await _loadDashboardData();
  }

  @override
  Widget build(BuildContext context) {
    // Role-gating check
    if (!_auth.isAdmin) {
      return Scaffold(
        backgroundColor: const Color(0xFFF9F6F0),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF2A1F14)),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🔒', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 16),
                Text(
                  'Access Restricted',
                  style: GoogleFonts.rubik(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2A1F14),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Admin privileges (role: "admin") are required to view this dashboard. Your current user is logged in as guest/user.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.rubik(
                    fontSize: 14,
                    color: const Color(0xFF8C7E72),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () async {
                    await _auth.updateRole('admin');
                    setState(() {});
                  },
                  icon: const Icon(Icons.shield),
                  label: const Text('Switch to Admin Role (Demo)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2A1F14),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9F6F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F6F0),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2A1F14)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Admin Control Center',
          style: GoogleFonts.rubik(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF2A1F14),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF2A1F14)),
            onPressed: _loadDashboardData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF2A1F14),
          unselectedLabelColor: const Color(0xFF8C7E72),
          indicatorColor: const Color(0xFFD4826A),
          labelStyle: GoogleFonts.rubik(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Users'),
            Tab(text: 'Bug Reports'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFD4826A)),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildUsersTab(),
                _buildBugsTab(),
              ],
            ),
    );
  }

  // ── 1. Overview Tab ───────────────────────────────────────────────────
  Widget _buildOverviewTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Metric Cards Grid
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Aggregated Total Entries',
                value: '$_aggregatedTotalEntries',
                subtitle: 'From counter doc',
                icon: '📊',
                color: const Color(0xFFA8CCAC),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: 'Total Users',
                value: '${_users.length}',
                subtitle: 'Registered accounts',
                icon: '👥',
                color: const Color(0xFF9BAFD6),
              ),
            ),
          ],
        ),
        const SizedBox(width: 12, height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Active (24h)',
                value: '$_activeLast24h',
                subtitle: 'Session in last 24 hours',
                icon: '⚡',
                color: const Color(0xFFE8C84A),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: 'Active (7d)',
                value: '$_activeLast7d',
                subtitle: 'Active past week',
                icon: '🔥',
                color: const Color(0xFFD4826A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Role Info Banner
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE8DFD5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('👑', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Text(
                    'Admin Profile',
                    style: GoogleFonts.rubik(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2A1F14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Logged in as: ${_auth.currentUser?.email ?? "varientLoki7@gmail.com"}',
                style: GoogleFonts.rubik(fontSize: 14, color: const Color(0xFF8C7E72)),
              ),
              Text(
                'Role: ${_auth.currentUser?.role ?? "admin"}',
                style: GoogleFonts.rubik(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2A1F14),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required String icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8DFD5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(icon, style: const TextStyle(fontSize: 24)),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: GoogleFonts.rubik(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF2A1F14),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.rubik(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2A1F14),
            ),
          ),
          Text(
            subtitle,
            style: GoogleFonts.rubik(
              fontSize: 11,
              color: const Color(0xFF8C7E72),
            ),
          ),
        ],
      ),
    );
  }

  // ── 2. Users Tab ──────────────────────────────────────────────────────
  Widget _buildUsersTab() {
    if (_users.isEmpty) {
      return Center(
        child: Text(
          'No users registered yet',
          style: GoogleFonts.rubik(color: const Color(0xFF8C7E72)),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _users.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final u = _users[index];
        final joinStr =
            '${u.createdAt.day}/${u.createdAt.month}/${u.createdAt.year}';
        final activeStr =
            '${u.lastActiveAt.day}/${u.lastActiveAt.month} ${u.lastActiveAt.hour}:${u.lastActiveAt.minute.toString().padLeft(2, '0')}';

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8DFD5)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFD4826A).withOpacity(0.15),
                child: Text(
                  u.name.isNotEmpty ? u.name[0].toUpperCase() : 'U',
                  style: GoogleFonts.rubik(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFD4826A),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          u.name,
                          style: GoogleFonts.rubik(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: const Color(0xFF2A1F14),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (u.isAdmin)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD4826A).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'ADMIN',
                              style: GoogleFonts.rubik(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFD4826A),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      u.email,
                      style: GoogleFonts.rubik(
                        fontSize: 13,
                        color: const Color(0xFF8C7E72),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          'Joined: $joinStr',
                          style: GoogleFonts.rubik(
                            fontSize: 11,
                            color: const Color(0xFFB5A99B),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Last active: $activeStr',
                          style: GoogleFonts.rubik(
                            fontSize: 11,
                            color: const Color(0xFFB5A99B),
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
      },
    );
  }

  // ── 3. Bug Reports Tab ────────────────────────────────────────────────
  Widget _buildBugsTab() {
    final list = _filteredBugReports;

    return Column(
      children: [
        // Status Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Row(
            children: [
              _buildFilterChip('all', 'All Reports'),
              const SizedBox(width: 8),
              _buildFilterChip('open', 'Open 🟢'),
              const SizedBox(width: 8),
              _buildFilterChip('in_progress', 'In Progress 🟡'),
              const SizedBox(width: 8),
              _buildFilterChip('resolved', 'Resolved 🔵'),
            ],
          ),
        ),

        Expanded(
          child: list.isEmpty
              ? Center(
                  child: Text(
                    'No bug reports found for status "$_bugFilter"',
                    style: GoogleFonts.rubik(color: const Color(0xFF8C7E72)),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final bug = list[index];
                    return _buildBugItem(bug);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final selected = _bugFilter == value;
    return ChoiceChip(
      label: Text(
        label,
        style: GoogleFonts.rubik(
          fontSize: 13,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? Colors.white : const Color(0xFF2A1F14),
        ),
      ),
      selected: selected,
      selectedColor: const Color(0xFF2A1F14),
      backgroundColor: Colors.white,
      onSelected: (_) {
        setState(() => _bugFilter = value);
      },
    );
  }

  Widget _buildBugItem(BugReport bug) {
    Color statusColor;
    switch (bug.status) {
      case 'in_progress':
        statusColor = const Color(0xFFE8C84A);
        break;
      case 'resolved':
        statusColor = const Color(0xFFA8CCAC);
        break;
      default:
        statusColor = const Color(0xFFD4826A);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8DFD5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  bug.userEmail,
                  style: GoogleFonts.rubik(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF8C7E72),
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  bug.status.toUpperCase().replaceAll('_', ' '),
                  style: GoogleFonts.rubik(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            bug.description,
            style: GoogleFonts.rubik(
              fontSize: 14,
              color: const Color(0xFF2A1F14),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${bug.createdAt.day}/${bug.createdAt.month} ${bug.createdAt.hour}:${bug.createdAt.minute.toString().padLeft(2, '0')}',
                style: GoogleFonts.rubik(
                  fontSize: 11,
                  color: const Color(0xFFB5A99B),
                ),
              ),

              // Status Toggle Menu
              PopupMenuButton<String>(
                onSelected: (val) => _updateBugStatus(bug.id, val),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'open', child: Text('Set Open 🟢')),
                  const PopupMenuItem(
                      value: 'in_progress', child: Text('Set In Progress 🟡')),
                  const PopupMenuItem(
                      value: 'resolved', child: Text('Set Resolved 🔵')),
                ],
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F6F0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Change Status',
                        style: GoogleFonts.rubik(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2A1F14),
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down,
                          size: 18, color: Color(0xFF2A1F14)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
