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
  bool _isSidebarExpanded = true;
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
    final result = await ApiService.get('${ApiConfig.dashboardStats}?t=$timestamp', forceRefresh: true);
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
      const EmployeeProfile(),
    ];

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
                    child: SizedBox(
                      width: 260,
                      child: _buildSidebar(),
                    ),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    child: pages[_currentIndex],
                  ),
                ),
              ],
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              top: 24,
              left: _isSidebarExpanded ? -100 : 24,
              child: FloatingActionButton.small(
                heroTag: 'rh_menu_btn',
                backgroundColor: STBColors.white,
                onPressed: () => setState(() => _isSidebarExpanded = true),
                elevation: _isSidebarExpanded ? 0 : 8,
                child: const Icon(Icons.menu, color: STBColors.primaryBlue),
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
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15, offset: const Offset(5, 0)),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.menu_open, color: STBColors.textSecondary),
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
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildSidebarItem(0, Icons.home_outlined, Icons.home, 'Accueil'),
                const SizedBox(height: 8),
                _buildSidebarItem(1, Icons.calendar_today_outlined, Icons.calendar_today, 'Congés'),
                const SizedBox(height: 8),
                _buildSidebarItem(2, Icons.person_off_outlined, Icons.person_off, 'Absences'),
                const SizedBox(height: 8),
                _buildSidebarItem(3, Icons.schedule_outlined, Icons.schedule, 'Retards'),
                const SizedBox(height: 8),
                _buildSidebarItem(4, Icons.person_outline, Icons.person, 'Profil'),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: STBColors.danger.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.logout, color: STBColors.danger, size: 20),
              ),
              title: Text('Déconnexion', style: GoogleFonts.inter(color: STBColors.danger, fontWeight: FontWeight.w600, fontSize: 14)),
              onTap: _logout,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(int index, IconData icon, IconData activeIcon, String label) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? STBColors.primaryBlue : STBColors.textSecondary;
    return ListTile(
      leading: Icon(isSelected ? activeIcon : icon, color: color, size: 22),
      title: Text(label, style: GoogleFonts.inter(color: color, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, fontSize: 14)),
      selected: isSelected,
      selectedTileColor: STBColors.primaryBlue.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      onTap: () {
        setState(() => _currentIndex = index);
        if (index == 0) _loadStats(showLoading: false);
      },
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
                /* // KPI Cards
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
                ), */
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
                /* _buildActionTile('Envoyer notification', Icons.send, STBColors.info, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const RHNotifications()));
                }), */
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
