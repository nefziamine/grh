import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../theme/stb_theme.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';

import '../login_screen.dart';
import 'employee_conges.dart';
import 'employee_credits.dart';
import 'employee_notifications.dart';
import 'employee_profile.dart';
import '../rh/rh_documents.dart';
import '../rh/rh_dashboard.dart';
import '../rh/rh_conges.dart';
import '../rh/rh_absences.dart';
import '../rh/rh_retards.dart';
import '../rh/rh_pointages.dart';
import '../rh/rh_credits.dart';
import '../admin/admin_users.dart';
import '../../widgets/chatbot_widget.dart';
import 'dart:async';

class EmployeeHome extends StatefulWidget {
  const EmployeeHome({super.key});

  @override
  State<EmployeeHome> createState() => _EmployeeHomeState();
}

class _EmployeeHomeState extends State<EmployeeHome> {
  int _currentIndex = 0;
  int _unreadNotifs = 0;
  bool _isSidebarExpanded = true;

  List<dynamic> _absences = [];
  List<dynamic> _retards = [];
  bool _isLoadingStats = false;
  bool _hasPointedToday = false;
  bool _markedAbsentToday = false;
  Map<String, dynamic> _stats = {};
  Timer? _refreshTimer;

  String get _role => AuthService.currentUser?.role ?? 'employee';
  bool get _isRH => _role == 'rh';
  bool get _isAdmin => _role == 'admin';
  int get _profileIndex {
    if (_isRH) return 7;
    if (_isAdmin) return 5;
    return 4;
  }

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
    _loadAbsencesAndRetards();
    _loadStats();
    _checkTodayPointage();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_currentIndex == 0) {
        _loadAbsencesAndRetards();
        _loadStats(showLoading: false);
        _loadUnreadCount();
        _checkTodayPointage();
        AuthService.getProfile().then((_) {
          if (mounted) setState(() {});
        });
      }
    });
  }

  Future<void> _loadAbsencesAndRetards() async {
    if (mounted) setState(() => _isLoadingStats = true);
    try {
      final absRes = await ApiService.get(ApiConfig.myAbsences);
      final retRes = await ApiService.get(ApiConfig.myRetards);

      if (mounted) {
        setState(() {
          if (absRes['success'] == true) _absences = absRes['data'] ?? [];
          if (retRes['success'] == true) _retards = retRes['data'] ?? [];
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingStats = false);
    }
  }

  Future<void> _loadStats({bool showLoading = true}) async {
    if (showLoading && mounted) setState(() => _isLoadingStats = true);
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final result = await ApiService.get(
        '${ApiConfig.dashboardStats}?t=$timestamp',
        forceRefresh: true,
      );
      if (result['success'] == true && mounted) {
        setState(() {
          _stats = result['data'] ?? {};
          if (showLoading) _isLoadingStats = false;
        });
      } else {
        if (showLoading && mounted) setState(() => _isLoadingStats = false);
      }
    } catch (e) {
      if (showLoading && mounted) setState(() => _isLoadingStats = false);
    }
  }

  Future<void> _checkTodayPointage() async {
    try {
      final result = await ApiService.get(ApiConfig.pointageToday);
      if (result['success'] == true && mounted) {
        setState(() {
          final type = result['pointage']?['type_action'];
          _markedAbsentToday = type == 'absence';
          _hasPointedToday =
              result['has_pointed'] == true && type != 'absence';
        });
      }
    } catch (_) {}
  }

  Future<void> _doPointage() async {
    final now = DateTime.now();
    final cutoff = DateTime(now.year, now.month, now.day, 10, 0);
    if (now.isAfter(cutoff)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Pointage impossible après 10:00. Veuillez contacter les RH.',
            ),
            backgroundColor: STBColors.danger,
          ),
        );
      }
      return;
    }

    setState(() => _isLoadingStats = true);
    final result = await ApiService.post(ApiConfig.pointageCreate, {});
    setState(() => _isLoadingStats = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Erreur'),
          backgroundColor: result['success'] == true
              ? STBColors.primaryGreen
              : STBColors.danger,
        ),
      );
      if (result['success'] == true) {
        setState(() => _hasPointedToday = true);
      } else if (result['auto_absence'] == true) {
        setState(() => _markedAbsentToday = true);
      }
    }
  }

  Future<void> _loadUnreadCount() async {
    final result = await ApiService.get(ApiConfig.notificationList);
    if (result['success'] == true && mounted) {
      setState(() {
        _unreadNotifs = result['unread_count'] ?? 0;
      });
    }
  }

  void _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  List<Widget> _buildPages(dynamic user) {
    final pages = <Widget>[
      _buildDashboard(user),
      const EmployeeConges(),
      const EmployeeCredits(),
      const RHDashboard(),
    ];
    if (_isAdmin) pages.add(const AdminUsers());
    if (_isRH) {
      pages.addAll([
        const RHConges(),
        const RHAbsences(),
        const RHRetards(),
      ]);
    }
    pages.add(const EmployeeProfile());
    return pages;
  }

  List<({int index, IconData icon, IconData activeIcon, String label})>
  _sidebarItems() {
    final items = <({int index, IconData icon, IconData activeIcon, String label})>[
      (index: 0, icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Accueil'),
      (index: 1, icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_today, label: 'Congés'),
      (index: 2, icon: Icons.account_balance_outlined, activeIcon: Icons.account_balance, label: 'Crédits'),
      (index: 3, icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'Dashboard'),
    ];
    if (_isAdmin) {
      items.add((index: 4, icon: Icons.admin_panel_settings_outlined, activeIcon: Icons.admin_panel_settings, label: 'Utilisateurs'));
    }
    if (_isRH) {
      items.addAll([
        (index: 4, icon: Icons.fact_check_outlined, activeIcon: Icons.fact_check, label: 'Congés RH'),
        (index: 5, icon: Icons.person_off_outlined, activeIcon: Icons.person_off, label: 'Absences'),
        (index: 6, icon: Icons.schedule_outlined, activeIcon: Icons.schedule, label: 'Retards'),
      ]);
    }
    items.add((index: _profileIndex, icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profil'));
    return items;
  }

  void _openChatbot() {
    final userId = AuthService.currentUser?.id;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChatbotWidget(userId: userId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    final pages = _buildPages(user);

    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        setState(() => _currentIndex = 0);
      },
      child: Scaffold(
        backgroundColor: STBColors.bgLight,
        body: Stack(
          children: [
            Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  width: _isSidebarExpanded ? 260 : 0,
                  clipBehavior: Clip.hardEdge,
                  decoration: const BoxDecoration(),
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(width: 260, child: _buildSidebar()),
                  ),
                ),
                Expanded(child: ClipRRect(child: pages[_currentIndex])),
              ],
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              top: 24,
              left: _isSidebarExpanded ? -100 : 24,
              child: FloatingActionButton.small(
                heroTag: 'emp_menu_btn',
                backgroundColor: STBColors.white,
                onPressed: () => setState(() => _isSidebarExpanded = true),
                elevation: _isSidebarExpanded ? 0 : 8,
                child: const Icon(Icons.menu, color: STBColors.primaryBlue),
              ),
            ),
            Positioned(
              bottom: 24,
              right: 24,
              child: FloatingActionButton.small(
                heroTag: 'emp_chatbot_btn',
                backgroundColor: STBColors.primaryBlue,
                onPressed: _openChatbot,
                elevation: 8,
                child: const Icon(Icons.smart_toy_rounded, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: STBColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(5, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.menu_open,
                  color: STBColors.textSecondary,
                ),
                onPressed: () => setState(() => _isSidebarExpanded = false),
                tooltip: 'Masquer le menu',
              ),
              const SizedBox(width: 8),
            ],
          ),
          const SizedBox(height: 10),
          Image.asset('assets/images/Logo_STB.png', height: 70),
          const SizedBox(height: 40),
          Expanded(
            child: Builder(
              builder: (context) {
                final items = _sidebarItems();
                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    for (var i = 0; i < items.length; i++) ...[
                      if (i > 0 && _isRH && i == 4) ...[
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            'Gestion RH',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: STBColors.textSecondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (i > 0 && _isAdmin && i == 4) ...[
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            'Administration',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: STBColors.textSecondary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      _buildSidebarItem(
                        items[i].index,
                        items[i].icon,
                        items[i].activeIcon,
                        items[i].label,
                      ),
                      if (i < items.length - 1) const SizedBox(height: 8),
                    ],
                  ],
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: STBColors.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.logout,
                  color: STBColors.danger,
                  size: 20,
                ),
              ),
              title: Text(
                'Déconnexion',
                style: GoogleFonts.inter(
                  color: STBColors.danger,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              onTap: _logout,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
  ) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? STBColors.primaryBlue : STBColors.textSecondary;
    return ListTile(
      leading: Icon(isSelected ? activeIcon : icon, color: color, size: 22),
      title: Text(
        label,
        style: GoogleFonts.inter(
          color: color,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          fontSize: 14,
        ),
      ),
      trailing: null,
      selected: isSelected,
      selectedTileColor: STBColors.primaryBlue.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      onTap: () => setState(() => _currentIndex = index),
    );
  }

  Widget _buildDashboard(dynamic user) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 320,
          pinned: true,
          backgroundColor: STBColors.primaryBlue,
          elevation: 0,
          actions: [
            IconButton(
              icon: Badge.count(
                count: _unreadNotifs,
                isLabelVisible: _unreadNotifs > 0,
                child: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.white,
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const EmployeeNotifications(),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: _logout,
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [STBColors.primaryBlue, Color(0xFF003875)],
                ),
              ),
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  Positioned(
                    bottom: 24,
                    left: 24,
                    right: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      padding: const EdgeInsets.all(2),
                                      child: Image.asset(
                                        'assets/images/Logo_STB.png',
                                        height: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Bonjour,',
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        color: STBColors.white.withValues(
                                          alpha: 0.8,
                                        ),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ).animate().fadeIn(delay: 100.ms).slideX(),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${user?.prenom ?? ''} ${user?.nom ?? ''}',
                                  style: GoogleFonts.inter(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    color: STBColors.white,
                                    letterSpacing: -0.5,
                                  ),
                                ).animate().fadeIn(delay: 200.ms).slideX(),
                              ],
                            ),
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: STBColors.white,
                              child: Text(
                                '${(user?.prenom != null && user!.prenom!.isNotEmpty) ? user.prenom![0] : ''}${(user?.nom != null && user!.nom!.isNotEmpty) ? user.nom![0] : ''}',
                                style: GoogleFonts.inter(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: STBColors.primaryBlue,
                                ),
                              ),
                            ).animate().scale(
                              delay: 300.ms,
                              duration: 400.ms,
                              curve: Curves.easeOutBack,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Solde Principal (Modern Glassmorphism Card)
                        Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white.withValues(alpha: 0.15),
                                    Colors.white.withValues(alpha: 0.05),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.flight_takeoff_rounded,
                                        color: STBColors.white.withValues(
                                          alpha: 0.9,
                                        ),
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Mon Solde de Congé',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          color: STBColors.white.withValues(
                                            alpha: 0.9,
                                          ),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const Spacer(),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: STBColors.primaryGreen,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Text(
                                          'ACTIF',
                                          style: GoogleFonts.inter(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${user?.soldeConge ?? 0}',
                                        style: GoogleFonts.inter(
                                          fontSize: 42,
                                          fontWeight: FontWeight.w900,
                                          color: STBColors.white,
                                          letterSpacing: -1,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 8,
                                        ),
                                        child: Text(
                                          'JOURS RESTANTS',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: STBColors.white.withValues(
                                              alpha: 0.7,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            )
                            .animate()
                            .fadeIn(delay: 400.ms, duration: 500.ms)
                            .slideY(begin: 0.2, end: 0)
                            .scale(
                              begin: const Offset(0.9, 0.9),
                              end: const Offset(1, 1),
                            ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Smart Pointage Action (Premium Card)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: STBColors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: STBColors.primaryBlue.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(
                  color: STBColors.primaryBlue.withValues(alpha: 0.1),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _hasPointedToday
                          ? STBColors.primaryGreen.withValues(alpha: 0.1)
                          : _markedAbsentToday
                          ? STBColors.danger.withValues(alpha: 0.1)
                          : STBColors.primaryBlue.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _hasPointedToday
                          ? Icons.check_circle_outline
                          : _markedAbsentToday
                          ? Icons.event_busy_outlined
                          : Icons.touch_app_outlined,
                      color: _hasPointedToday
                          ? STBColors.primaryGreen
                          : _markedAbsentToday
                          ? STBColors.danger
                          : STBColors.primaryBlue,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _hasPointedToday
                              ? 'Présence Enregistrée'
                              : _markedAbsentToday
                              ? 'Absence Automatique'
                              : 'Pointage Quotidien',
                          style: GoogleFonts.inter(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: STBColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _hasPointedToday
                              ? 'Fait à ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}'
                              : _markedAbsentToday
                              ? 'Aucun pointage avant 10:00 — absence enregistrée'
                              : 'Enregistrez votre arrivée avant 10:00',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: STBColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!_hasPointedToday && !_markedAbsentToday)
                    ElevatedButton(
                      onPressed: _isLoadingStats ? null : _doPointage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: STBColors.primaryBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoadingStats
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Pointer',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                    ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.1, end: 0),
        ),

        // Ma Ponctualité (Absences & Retards)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Mes Statistiques',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: STBColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: STBColors.primaryBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${DateTime.now().year}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: STBColors.primaryBlue,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildKPICard(
                              'Mes Congés (attente)',
                              '${_stats['conges_en_attente'] ?? 0}',
                              Icons.hourglass_empty,
                              STBColors.warning,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildKPICard(
                              'Mes Crédits (attente)',
                              '${_stats['credits_en_attente'] ?? 0}',
                              Icons.account_balance,
                              STBColors.primaryGreen,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildKPICard(
                              'Absences (mois)',
                              '${_stats['absences_mois'] ?? 0}',
                              Icons.person_off,
                              STBColors.danger,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildKPICard(
                              'Retards (mois)',
                              '${_stats['retards_mois'] ?? 0}',
                              Icons.schedule,
                              STBColors.warning,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Ma Ponctualité',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: STBColors.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (_isLoadingStats)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _showHistoryBottomSheet('Absences'),
                            borderRadius: BorderRadius.circular(24),
                            child:
                                _buildStatCard(
                                      'Total Abs.',
                                      '${_absences.length}',
                                      'Jours',
                                      Icons.event_busy_rounded,
                                      STBColors.danger,
                                    )
                                    .animate()
                                    .fadeIn(delay: 600.ms, duration: 400.ms)
                                    .slideX(begin: -0.2, end: 0),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () => _showHistoryBottomSheet('Retards'),
                            borderRadius: BorderRadius.circular(24),
                            child:
                                _buildStatCard(
                                      'Total Retards',
                                      '${_retards.length}',
                                      'Fois',
                                      Icons.more_time_rounded,
                                      STBColors.warning,
                                    )
                                    .animate()
                                    .fadeIn(delay: 700.ms, duration: 400.ms)
                                    .slideX(begin: 0.2, end: 0),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (!_isLoadingStats &&
                    (_absences.isNotEmpty || _retards.isNotEmpty))
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: STBColors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: STBColors.divider),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Dernière activité',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: STBColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Divider(
                                  color: STBColors.divider,
                                  thickness: 1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (_retards.isNotEmpty)
                            _buildMiniActivity(
                              'Retard le ${_retards.first['date_retard']}',
                              '${_retards.first['duree_minutes']} min • ${_retards.first['heure_arrivee']}',
                              STBColors.warning,
                            ).animate().fadeIn(delay: 800.ms),
                          if (_absences.isNotEmpty)
                            _buildMiniActivity(
                              'Absence le ${_absences.first['date_absence']}',
                              _absences.first['type_absence'] == 'justifiee'
                                  ? 'Justifiée'
                                  : 'Injustifiée',
                              STBColors.danger,
                            ).animate().fadeIn(delay: 900.ms),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 750.ms).slideY(begin: 0.1, end: 0),
              ],
            ),
          ),
        ),

        // Role-specific management section
        if (_isRH || _isAdmin)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isRH ? 'Gestion rapide' : 'Supervision système',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: STBColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_isRH) ...[
                    _buildRoleActionTile(
                      'Valider les pointages',
                      Icons.fact_check_outlined,
                      STBColors.primaryBlue,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RHPointages()),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildRoleActionTile(
                      'Gérer les crédits',
                      Icons.account_balance,
                      STBColors.primaryGreen,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RHCredits()),
                      ),
                    ),
                  ],
                  if (_isAdmin) ...[
                    Row(
                      children: [
                        Expanded(
                          child: _buildKPICard(
                            'Congés (attente)',
                            '${_stats['conges_en_attente'] ?? 0}',
                            Icons.hourglass_empty,
                            STBColors.warning,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildKPICard(
                            'Absences (mois)',
                            '${_stats['absences_mois'] ?? 0}',
                            Icons.person_off,
                            STBColors.danger,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildRoleActionTile(
                      'Gérer les utilisateurs',
                      Icons.manage_accounts,
                      STBColors.primaryBlue,
                      () => setState(() => _currentIndex = 4),
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

        // Quick Service & Highlight
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RhDocumentsScreen()),
                );
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F7FF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: STBColors.primaryBlue.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: STBColors.primaryBlue,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.description_outlined,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Documents Officiels',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: STBColors.primaryBlue,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Accédez aux documents RH et formulaires bancaires.',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: STBColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: STBColors.primaryBlue,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Quick settings / info
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Assistance STB',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: STBColors.textSecondary,
                  ),
                ).animate().fadeIn(delay: 500.ms),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _openChatbot,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: STBColors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: STBColors.shadow,
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: STBColors.primaryBlue.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.smart_toy_rounded,
                            color: STBColors.primaryBlue,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Assistant RH Virtuel',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: STBColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Posez vos questions RH (IA)',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: STBColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: STBColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showHistoryBottomSheet(String type) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: STBColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: STBColors.divider,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(
                  type == 'Absences'
                      ? Icons.event_busy_rounded
                      : Icons.more_time_rounded,
                  color: STBColors.primaryBlue,
                ),
                const SizedBox(width: 12),
                Text(
                  'Historique des $type',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: STBColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: (type == 'Absences' ? _absences : _retards).isEmpty
                  ? Center(
                      child: Text(
                        'Aucun historique trouvé.',
                        style: GoogleFonts.inter(
                          color: STBColors.textSecondary,
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: type == 'Absences'
                          ? _absences.length
                          : _retards.length,
                      separatorBuilder: (c, i) =>
                          Divider(color: STBColors.divider),
                      itemBuilder: (c, i) {
                        final item = type == 'Absences'
                            ? _absences[i]
                            : _retards[i];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            type == 'Absences'
                                ? 'Le ${item['date_absence']}'
                                : 'Le ${item['date_retard']}',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Text(
                            type == 'Absences'
                                ? (item['type_absence'] == 'justifiee'
                                      ? 'Justifiée'
                                      : 'Injustifiée')
                                : '${item['duree_minutes']} min • ${item['heure_arrivee']}',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: STBColors.textSecondary,
                            ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  (type == 'Absences'
                                          ? STBColors.danger
                                          : STBColors.warning)
                                      .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              type == 'Absences' ? 'ABS' : 'RETARD',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: type == 'Absences'
                                    ? STBColors.danger
                                    : STBColors.warning,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    String unit,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: STBColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: color.withValues(alpha: 0.1), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: STBColors.textPrimary,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  unit,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: STBColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: STBColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleActionTile(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: STBColors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: STBColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildKPICard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: STBColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: STBColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: STBColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniActivity(String title, String subtitle, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: STBColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: STBColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
