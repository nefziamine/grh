import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/stb_theme.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';
import '../login_screen.dart';
import 'admin_users.dart';
import '../employee/employee_profile.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _currentIndex = 0;
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    final result = await ApiService.get(ApiConfig.dashboardStats);
    if (result['success'] == true && mounted) {
      setState(() { _stats = result['data'] ?? {}; _isLoading = false; });
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
    final pages = [_buildDashboard(), const AdminUsers(), const EmployeeProfile()];

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
            onTap: (i) => setState(() => _currentIndex = i),
            selectedItemColor: STBColors.primaryBlue,
            unselectedItemColor: STBColors.textSecondary,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            elevation: 0,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Dashboard'),
              BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings_outlined), activeIcon: Icon(Icons.admin_panel_settings), label: 'Utilisateurs'),
              BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profil'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboard() {
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
                // Overview cards
                _buildStatCard('Utilisateurs', '${_stats['total_users'] ?? 0}', Icons.people, STBColors.primaryBlue),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildStatCard('Congés', '${_stats['conges_en_attente'] ?? 0}', Icons.hourglass_empty, STBColors.warning)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStatCard('Crédits', '${_stats['credits_en_attente'] ?? 0}', Icons.account_balance, STBColors.info)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildStatCard('Absences', '${_stats['absences_mois'] ?? 0}', Icons.person_off, STBColors.danger)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildStatCard('Retards', '${_stats['retards_mois'] ?? 0}', Icons.schedule, STBColors.warning)),
                  ],
                ),
                const SizedBox(height: 24),
                Text('Supervision système', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                _buildSystemTile('Gérer les utilisateurs', 'Ajouter, modifier, supprimer', Icons.manage_accounts, () {
                  setState(() => _currentIndex = 1);
                }),
                const SizedBox(height: 8),
                // Crédits actifs hidden for admin as requested
                /*
                _buildSystemTile('Crédits actifs', '${(_stats['montant_credits_actifs'] ?? 0).toStringAsFixed(2)} TND', Icons.account_balance_wallet, () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('La gestion des crédits est réservée au service Ressources Humaines.')));
                }),
                */
              ],
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: STBColors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 20)),
          const SizedBox(height: 10),
          Text(value, style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800)),
          Text(title, style: GoogleFonts.inter(fontSize: 12, color: STBColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildSystemTile(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: STBColors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)]),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: STBColors.primaryBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: STBColors.primaryBlue, size: 22)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600)),
                Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: STBColors.textSecondary)),
              ]),
            ),
            Icon(Icons.chevron_right, color: STBColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
