import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/stb_theme.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';
import '../../models/user.dart';
import '../employee/employee_profile.dart';

class AdminUsers extends StatefulWidget {
  const AdminUsers({super.key});

  @override
  State<AdminUsers> createState() => _AdminUsersState();
}

class _AdminUsersState extends State<AdminUsers> {
  List<User> _users = [];
  List<User> _filteredUsers = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();
  final Set<String> _selectedRoles = {};
  String _selectedAlphabet = 'Tous';
  final List<String> _roles = ['admin', 'rh', 'employee'];
  final List<String> _alphabets = ['Tous', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers({String? search, bool forceRefresh = false}) async {
    setState(() => _isLoading = true);
    // Remove limit to get all users
    final params = <String, String>{};
    if (search != null && search.isNotEmpty) params['search'] = search;
    final result = await ApiService.get(ApiConfig.employeeList, params: params, forceRefresh: forceRefresh);
    if (result['success'] == true && mounted) {
      setState(() {
        _users = (result['data'] as List).map((e) => User.fromJson(e)).toList();
        _filteredUsers = _users;
        _isLoading = false;
      });
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin': return STBColors.danger;
      case 'rh': return STBColors.primaryGreen;
      default: return STBColors.info;
    }
  }

  void _showUserActions(User user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(color: STBColors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: STBColors.divider, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            CircleAvatar(
              radius: 30,
              backgroundColor: STBColors.primaryBlue.withValues(alpha: 0.1),
              child: Text('${user.prenom.isNotEmpty ? user.prenom[0] : ''}${user.nom.isNotEmpty ? user.nom[0] : ''}', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: STBColors.primaryBlue)),
            ),
            const SizedBox(height: 12),
            Text(user.fullName, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600)),
            Text('${user.matricule} • ${user.role.toUpperCase()}', style: GoogleFonts.inter(fontSize: 13, color: STBColors.textSecondary)),
            ListTile(
              leading: Icon(Icons.person_outline, color: STBColors.primaryBlue),
              title: const Text('Afficher le profil'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => EmployeeProfile(userId: user.id)));
              },
            ),

            ListTile(
              leading: Icon(Icons.swap_horiz, color: STBColors.primaryBlue),
              title: const Text('Changer le rôle'),
              subtitle: Text('Rôle actuel: ${user.role}'),
              onTap: () {
                Navigator.pop(context);
                _showChangeRoleDialog(user);
              },
            ),

            ListTile(
              leading: Icon(Icons.delete_outline, color: STBColors.danger),
              title: Text('Supprimer', style: GoogleFonts.inter(color: STBColors.danger)),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(user);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _filterUsers() {
    setState(() {
      _filteredUsers = _users.where((user) {
        // Filter by role (Multi-select logic)
        if (_selectedRoles.isNotEmpty) {
          bool roleMatch = false;
          if (_selectedRoles.contains(user.role)) {
            roleMatch = true;
          } else if (_selectedRoles.contains('employee')) {
            // "Employee" filter includes any role that isn't admin or rh
            if (user.role != 'admin' && user.role != 'rh') roleMatch = true;
          }
          if (!roleMatch) return false;
        }
        
        // Filter by alphabet
        if (_selectedAlphabet != 'Tous') {
          final firstLetter = user.nom.isNotEmpty ? user.nom[0].toUpperCase() : '';
          if (firstLetter != _selectedAlphabet) {
            return false;
          }
        }
        
        // Filter by search
        if (_searchController.text.isNotEmpty) {
          final searchLower = _searchController.text.toLowerCase();
          return user.nom.toLowerCase().contains(searchLower) ||
                 user.prenom.toLowerCase().contains(searchLower) ||
                 user.matricule.toLowerCase().contains(searchLower) ||
                 user.email.toLowerCase().contains(searchLower);
        }
        
        return true;
      }).toList();
    });
  }

  void _showChangeRoleDialog(User user) {
    String newRole = user.role;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Changer le rôle', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${user.fullName} (${user.matricule})', style: GoogleFonts.inter(color: STBColors.textSecondary)),
              const SizedBox(height: 16),
              ...['rh', 'employee'].map((role) => RadioListTile<String>(
                value: role,
                groupValue: newRole,
                activeColor: STBColors.primaryBlue,
                title: Text(role.toUpperCase(), style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
                onChanged: (v) => setDialogState(() => newRole = v!),
              )),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await ApiService.post(ApiConfig.employeeUpdate, {'id': user.id, 'role': newRole});
                _loadUsers();
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Rôle mis à jour'), backgroundColor: STBColors.success));
              },
              child: const Text('Confirmer'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Confirmer la suppression', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        content: Text('Voulez-vous vraiment supprimer ${user.fullName}?', style: GoogleFonts.inter()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              setState(() {
                _users.removeWhere((u) => u.id == user.id);
              });
              
              final res = await ApiService.post(ApiConfig.employeeDelete, {'id': user.id});
              
              if (res['success'] != true) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur lors de la suppression'), backgroundColor: STBColors.danger)
                  );
                  _loadUsers(forceRefresh: true);
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: STBColors.danger),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _showCreateUserDialog() {
    final nomCtrl = TextEditingController();
    final prenomCtrl = TextEditingController();
    final matriculeCtrl = TextEditingController();
    final cinCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final pswdCtrl = TextEditingController();
    String role = 'employee';
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (ctx, setModalState) => SingleChildScrollView(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Créer un utilisateur', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
              TextField(controller: prenomCtrl, decoration: const InputDecoration(labelText: 'Prénom')),
              TextField(controller: nomCtrl, decoration: const InputDecoration(labelText: 'Nom')),
              TextField(controller: matriculeCtrl, decoration: const InputDecoration(labelText: 'Matricule')),
              TextField(controller: cinCtrl, decoration: const InputDecoration(labelText: 'CIN')),
              TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Téléphone')),
              TextField(controller: pswdCtrl, decoration: const InputDecoration(labelText: 'Mot de passe'), obscureText: true),
              DropdownButton<String>(
                value: role,
                isExpanded: true,
                items: ['employee', 'rh'].map((r) => DropdownMenuItem(value: r, child: Text(r.toUpperCase()))).toList(),
                onChanged: (v) => setModalState(() => role = v!),
              ),
              const SizedBox(height: 16),
              if (isSaving) const CircularProgressIndicator()
              else ElevatedButton(
                onPressed: () async {
                  setModalState(() => isSaving = true);
                  final res = await ApiService.post(ApiConfig.employeeCreate, {
                    'nom': nomCtrl.text,
                    'prenom': prenomCtrl.text,
                    'matricule': matriculeCtrl.text,
                    'cin': cinCtrl.text,
                    'email': emailCtrl.text,
                    'telephone': phoneCtrl.text,
                    'password': pswdCtrl.text,
                    'role': role,
                  });
                  setModalState(() => isSaving = false);
                  if (res['success'] == true) {
                    _loadUsers(forceRefresh: true);
                    if (mounted) Navigator.pop(ctx);
                  } else {
                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Erreur')));
                  }
                },
                child: const Text('Créer'),
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
    bool isAdmin = AuthService.currentUser?.role == 'admin';
    return Scaffold(
      appBar: AppBar(
        title: Row(mainAxisSize: MainAxisSize.min, children: [ Image.asset('assets/images/Logo_STB.png', height: 28), const SizedBox(width: 12), Text(isAdmin ? 'Gestion Admins' : 'Gestion Utilisateurs') ]),
        actions: [
          IconButton(icon: const Icon(Icons.person_add_outlined), onPressed: _showCreateUserDialog),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Rechercher un agent...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: STBColors.primaryBlue.withValues(alpha: 0.3))),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    ),
                    onChanged: (v) => _filterUsers(),
                  ),
                ),
                const SizedBox(width: 12),
                Badge(
                  isLabelVisible: _selectedRoles.isNotEmpty || _selectedAlphabet != 'Tous',
                  backgroundColor: STBColors.primaryGreen,
                  padding: const EdgeInsets.all(4),
                  label: Text('${_selectedRoles.length > 0 ? _selectedRoles.length : ''}', style: const TextStyle(fontSize: 8, color: Colors.white)),
                  child: InkWell(
                    onTap: _showFilterBottomSheet,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: STBColors.primaryBlue,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: STBColors.primaryBlue.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))],
                      ),
                      child: const Icon(Icons.tune_outlined, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Active Filter Chips
          if (_selectedRoles.isNotEmpty || _selectedAlphabet != 'Tous' || _searchController.text.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  if (_selectedRoles.isNotEmpty) 
                    _buildFilterChip(
                      label: 'Rôles: ${_selectedRoles.map((r) => r.toUpperCase()).join(', ')}', 
                      onDelete: () { setState(() => _selectedRoles.clear()); _filterUsers(); }
                    ),
                  if (_selectedAlphabet != 'Tous')
                    _buildFilterChip(
                      label: 'Lettre: $_selectedAlphabet', 
                      onDelete: () { setState(() => _selectedAlphabet = 'Tous'); _filterUsers(); }
                    ),
                  if (_searchController.text.isNotEmpty)
                    _buildFilterChip(
                      label: 'Recherche: "${_searchController.text}"', 
                      onDelete: () { setState(() => _searchController.clear()); _filterUsers(); }
                    ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedRoles.clear();
                        _selectedAlphabet = 'Tous';
                        _searchController.clear();
                      });
                      _filterUsers();
                    },
                    child: Text('Tout effacer', style: GoogleFonts.inter(fontSize: 12, color: STBColors.danger, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),
          
          // Results summary
          if (_filteredUsers.length != _users.length)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: STBColors.primaryBlue.withValues(alpha: 0.1),
              child: Text(
                '${_filteredUsers.length} / ${_users.length} employés affichés',
                style: GoogleFonts.inter(fontSize: 12, color: STBColors.primaryBlue, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ),          
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadUsers,
                    child: _filteredUsers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off, size: 64, color: STBColors.textSecondary),
                              const SizedBox(height: 16),
                              Text(
                                'Aucun employé trouvé',
                                style: GoogleFonts.inter(fontSize: 16, color: STBColors.textSecondary),
                              ),
                              if (_selectedRoles.isNotEmpty || _selectedAlphabet != 'Tous' || _searchController.text.isNotEmpty)
                                TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedRoles.clear();
                          _selectedAlphabet = 'Tous';
                          _searchController.clear();
                        });
                        _filterUsers();
                      },
                                  child: const Text('Réinitialiser les filtres'),
                                ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredUsers.length,
                          itemBuilder: (c, i) {
                            final user = _filteredUsers[i];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: user.isActive ? STBColors.white : STBColors.white.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                leading: CircleAvatar(
                                  backgroundColor: _getRoleColor(user.role).withValues(alpha: 0.1),
                                  child: Text('${user.prenom.isNotEmpty ? user.prenom[0] : ''}${user.nom.isNotEmpty ? user.nom[0] : ''}', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: _getRoleColor(user.role))),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(child: Text(user.fullName, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14, color: user.isActive ? null : STBColors.textSecondary))),
                                    if (!user.isActive) Icon(Icons.block, size: 16, color: STBColors.danger),
                                  ],
                                ),
                                subtitle: Text('${user.matricule} • ${user.email}', style: GoogleFonts.inter(fontSize: 11, color: STBColors.textSecondary)),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(color: _getRoleColor(user.role).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                                  child: Text(user.role.toUpperCase(), style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: _getRoleColor(user.role))),
                                ),
                                onTap: () => _showUserActions(user),
                              ),
                            );
                          },
                        ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({required String label, required VoidCallback onDelete}) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: STBColors.primaryBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: STBColors.primaryBlue)),
          const SizedBox(width: 4),
          GestureDetector(onTap: onDelete, child: Icon(Icons.close, size: 14, color: STBColors.primaryBlue)),
        ],
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          decoration: const BoxDecoration(color: STBColors.bgLight, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: STBColors.divider, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Filtres', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: STBColors.primaryBlue)),
                  TextButton(
                    onPressed: () {
                      setSheetState(() {
                        _selectedRoles.clear();
                        _selectedAlphabet = 'Tous';
                      });
                    },
                    child: Text('Réinitialiser', style: GoogleFonts.inter(color: STBColors.danger, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              Text('FILTRER PAR RÔLE', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: STBColors.textSecondary, letterSpacing: 1.2)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _roles.map((role) {
                  final isSelected = _selectedRoles.contains(role);
                  return InkWell(
                    onTap: () => setSheetState(() {
                      if (isSelected) {
                        _selectedRoles.remove(role);
                      } else {
                        _selectedRoles.add(role);
                      }
                    }),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? STBColors.primaryBlue : STBColors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSelected ? STBColors.primaryBlue : STBColors.divider),
                        boxShadow: isSelected ? [BoxShadow(color: STBColors.primaryBlue.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4))] : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            role == 'admin' ? Icons.admin_panel_settings : 
                            (role == 'rh' ? Icons.card_membership : Icons.person_outline),
                            size: 18,
                            color: isSelected ? Colors.white : STBColors.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            role == 'employee' ? 'EMPLOYÉ' : role.toUpperCase(),
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : STBColors.textPrimary),
                          ),
                          if (isSelected) const Padding(padding: EdgeInsets.only(left: 6), child: Icon(Icons.check, size: 14, color: Colors.white)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 32),
              
              Text('FILTRER PAR ALPHABET', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: STBColors.textSecondary, letterSpacing: 1.2)),
              const SizedBox(height: 12),
              SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _alphabets.length,
                  itemBuilder: (context, index) {
                    final letter = _alphabets[index];
                    final isSelected = _selectedAlphabet == letter;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () => setSheetState(() => _selectedAlphabet = letter),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected ? STBColors.primaryBlue : STBColors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isSelected ? STBColors.primaryBlue : STBColors.divider),
                          ),
                          child: Text(
                            letter,
                            style: GoogleFonts.inter(fontSize: 14, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500, color: isSelected ? Colors.white : STBColors.textPrimary),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 40),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    _filterUsers();
                    Navigator.pop(context);
                  },
                  child: const Text('Appliquer les filtres'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
