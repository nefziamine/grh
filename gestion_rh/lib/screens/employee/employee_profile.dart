import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/stb_theme.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';
import '../../models/user.dart';

class EmployeeProfile extends StatefulWidget {
  final int? userId;
  const EmployeeProfile({super.key, this.userId});

  @override
  State<EmployeeProfile> createState() => _EmployeeProfileState();
}

class _EmployeeProfileState extends State<EmployeeProfile> {
  User? user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (widget.userId == null) {
      user = AuthService.currentUser;
      _isLoading = false;
      return;
    }
    
    setState(() => _isLoading = true);
    final result = await ApiService.get(ApiConfig.employeeRead, params: {'id': widget.userId.toString()});
    if (result['success'] == true && mounted) {
      setState(() {
        user = User.fromJson(result['data']);
        _isLoading = false;
      });
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showEditDialog() async {
    final emailCtrl = TextEditingController(text: user?.email);
    final phoneCtrl = TextEditingController(text: user?.telephone);
    final addressCtrl = TextEditingController(text: user?.adresse);
    final nomCtrl = TextEditingController(text: user?.nom);
    final prenomCtrl = TextEditingController(text: user?.prenom);
    final posteCtrl = TextEditingController(text: user?.poste);
    final depCtrl = TextEditingController(text: user?.departement);
    final soldeCtrl = TextEditingController(text: user?.soldeConge?.toString());
    final roleCtrl = TextEditingController(text: user?.role);
    final isAdmin = AuthService.currentUser?.role == 'admin';
    bool isSaving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (ctx, setModalState) => SingleChildScrollView(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Modifier mes informations", style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
              if (isAdmin) ...[
                TextField(controller: prenomCtrl, decoration: const InputDecoration(labelText: 'Prénom')),
                TextField(controller: nomCtrl, decoration: const InputDecoration(labelText: 'Nom')),
                TextField(controller: posteCtrl, decoration: const InputDecoration(labelText: 'Poste')),
                TextField(controller: depCtrl, decoration: const InputDecoration(labelText: 'Département')),
                TextField(controller: soldeCtrl, decoration: const InputDecoration(labelText: 'Solde Congé'), keyboardType: TextInputType.number),
                TextField(controller: roleCtrl, decoration: const InputDecoration(labelText: 'Rôle (employee/rh/admin)')),
              ],
              TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Téléphone')),
              TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Adresse')),
              const SizedBox(height: 16),
              if (isSaving) const CircularProgressIndicator()
              else ElevatedButton(
                onPressed: () async {
                  setModalState(() => isSaving = true);
                  final res = await ApiService.post(ApiConfig.employeeUpdate, {
                    'id': user?.id,
                    if (isAdmin) ...{
                      'nom': nomCtrl.text,
                      'prenom': prenomCtrl.text,
                      'poste': posteCtrl.text,
                      'departement': depCtrl.text,
                      'solde_conge': double.tryParse(soldeCtrl.text) ?? user?.soldeConge,
                      'role': roleCtrl.text,
                    },
                    'email': emailCtrl.text,
                    'telephone': phoneCtrl.text,
                    'adresse': addressCtrl.text,
                  });
                  setModalState(() => isSaving = false);
                  if (res['success'] == true) {
                    if (widget.userId == null) {
                      await AuthService.getProfile();
                    } else {
                      await _loadProfile();
                    }
                    if (mounted) Navigator.pop(ctx, true);
                  } else {
                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Erreur')));
                  }
                },
                child: const Text('Enregistrer'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (user == null) return const Scaffold(body: Center(child: Text("Utilisateur non trouvé")));

    return Scaffold(
      appBar: AppBar(
        title: Row(mainAxisSize: MainAxisSize.min, children: [
          Image.asset('assets/images/Logo_STB.png', height: 28),
          const SizedBox(width: 12),
          Text(widget.userId == null ? 'Mon Profil' : 'Profil Employé')
        ]),
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: _showEditDialog),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Avatar header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [STBColors.gradientStart, STBColors.gradientEnd]),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 45,
                    backgroundColor: STBColors.white.withValues(alpha: 0.2),
                    child: Text(
                      '${(user?.prenom?.isNotEmpty ?? false) ? user!.prenom![0] : ''}${(user?.nom?.isNotEmpty ?? false) ? user!.nom![0] : ''}',
                      style: GoogleFonts.inter(fontSize: 30, fontWeight: FontWeight.w700, color: STBColors.white),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(user?.fullName ?? '', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: STBColors.white)),
                  const SizedBox(height: 4),
                  Text(user?.poste ?? '', style: GoogleFonts.inter(fontSize: 14, color: STBColors.white.withValues(alpha: 0.8))),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: STBColors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                    child: Text(user?.matricule ?? '', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: STBColors.white)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildInfoSection('Informations Personnelles', [
              _buildInfoTile(Icons.email, 'Email', user?.email ?? ''),
              _buildInfoTile(Icons.phone, 'Téléphone', user?.telephone ?? 'Non renseigné'),
              _buildInfoTile(Icons.location_on, 'Adresse', user?.adresse ?? 'Non renseignée'),
            ]),
            const SizedBox(height: 16),
            _buildInfoSection('Informations Professionnelles', [
              _buildInfoTile(Icons.business, 'Département', user?.departement ?? ''),
              _buildInfoTile(Icons.work, 'Poste', user?.poste ?? ''),
              _buildInfoTile(Icons.calendar_today, 'Date d\'embauche', user?.dateEmbauche ?? ''),
              _buildInfoTile(Icons.beach_access, 'Solde congé', '${user?.soldeConge ?? 0} jours'),
            ]),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: STBColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: STBColors.textPrimary)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: STBColors.primaryBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: STBColors.primaryBlue, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.inter(fontSize: 12, color: STBColors.textSecondary)),
                Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: STBColors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
