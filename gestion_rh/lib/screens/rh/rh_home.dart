import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/stb_theme.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';
import '../login_screen.dart';
import 'rh_conges.dart';
import 'rh_absences.dart';
import 'rh_retards.dart';
import 'rh_credits.dart';
import 'rh_notifications.dart';
import 'rh_dashboard.dart';
import 'rh_pointages.dart';
import '../admin/admin_users.dart';
import '../employee/employee_profile.dart';
import 'rh_documents.dart';
import 'dart:async';

class RHHome extends StatefulWidget {
  const RHHome({super.key});

  @override
  State<RHHome> createState() => _RHHomeState();
}

class _RHHomeState extends State<RHHome> {
  int _currentIndex = 0;
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  Timer? _refreshTimer;
  
  @override
  void initState() {
    super.initState();
    _loadStats();
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
        _loadStats(showLoading: false);
      }
    });
  }

  Future<void> _loadStats({bool showLoading = true}) async {
    if (showLoading) setState(() => _isLoading = true);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final result = await ApiService.get('${ApiConfig.dashboardStats}?t=$timestamp');
    if (result['success'] == true && mounted) {
      setState(() {
        _stats = result['data'] ?? {};
        _isLoading = false;
      });
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildMainDashboard(),
      const RHConges(),
      const RHAbsences(),
      const RHRetards(), // New item
      const RHDashboard(),
      const EmployeeProfile(),
    ];

    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        setState(() => _currentIndex = 0);
      },
      child: Scaffold(
        body: pages[_currentIndex],
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: STBColors.white,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, -2))],
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (i) {
              setState(() => _currentIndex = i);
              if (i == 0) _loadStats(showLoading: false); // Silent refresh when coming back to home
            },
            selectedItemColor: STBColors.primaryBlue,
            unselectedItemColor: STBColors.textSecondary,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedLabelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
            unselectedLabelStyle: GoogleFonts.inter(fontSize: 11),
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Accueil'),
              BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), activeIcon: Icon(Icons.calendar_today), label: 'Congés'),
              BottomNavigationBarItem(icon: Icon(Icons.person_off_outlined), activeIcon: Icon(Icons.person_off), label: 'Absences'),
              BottomNavigationBarItem(icon: Icon(Icons.schedule_outlined), activeIcon: Icon(Icons.schedule), label: 'Retards'),
              BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Dashboard'),
              BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profil'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainDashboard() {
    final user = AuthService.currentUser;
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 280,
          pinned: true,
          backgroundColor: STBColors.primaryBlue,
          elevation: 0,
          actions: [
            IconButton(icon: const Icon(Icons.logout, color: Colors.white), onPressed: _logout),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: STBTheme.headerGradient,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  Image.asset('assets/images/Logo_STB.png', height: 120),
                  const SizedBox(height: 15),
                  Text(
                    'Bonjour, ${user?.prenom ?? ''}!',
                    style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w800, color: STBColors.white),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Bienvenue sur STB Mobile',
                    style: GoogleFonts.inter(fontSize: 15, color: STBColors.white.withValues(alpha: 0.8), fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              if (_isLoading) const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
              else ...[
                // KPI Cards
                Row(
                  children: [
                    Expanded(child: _buildKPICard('Congés en attente', '${_stats['conges_en_attente'] ?? 0}', Icons.hourglass_empty, STBColors.warning)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildKPICard('Crédits en attente', '${_stats['credits_en_attente'] ?? 0}', Icons.account_balance, STBColors.primaryGreen)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildKPICard('Absences (mois)', '${_stats['absences_mois'] ?? 0}', Icons.person_off, STBColors.danger)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildKPICard('Retards (mois)', '${_stats['retards_mois'] ?? 0}', Icons.schedule, STBColors.warning)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildKPICard('Retard moyen', '${_stats['retard_moyen_minutes'] ?? 0} min', Icons.timer, STBColors.info)),
                  ],
                ),
                const SizedBox(height: 24),
                // Quick Actions
                Text('Gestion rapide', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                _buildActionTile('Valider les pointages', Icons.fact_check_outlined, STBColors.primaryBlue, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const RHPointages()));
                }),
                const SizedBox(height: 8),
                _buildActionTile('Gérer les retards', Icons.schedule, STBColors.warning, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const RHRetards()));
                }),
                const SizedBox(height: 8),
                _buildActionTile('Gérer les crédits', Icons.account_balance, STBColors.primaryGreen, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const RHCredits()));
                }),
                const SizedBox(height: 8),
                _buildActionTile('Envoyer notification', Icons.send, STBColors.info, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const RHNotifications()));
                }),
                const SizedBox(height: 8),
                _buildActionTile('Documents Officiels', Icons.description, STBColors.primaryBlue, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const RhDocumentsScreen()));
                }),
              ],
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildKPICard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: STBColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(value, style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: STBColors.textPrimary)),
          const SizedBox(height: 2),
          Text(title, style: GoogleFonts.inter(fontSize: 12, color: STBColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildActionTile(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: STBColors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(child: Text(title, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500))),
            Icon(Icons.chevron_right, color: STBColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
