import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/stb_theme.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';
import '../../models/user.dart';
import '../employee/employee_profile.dart';

class RHEmployees extends StatefulWidget {
  const RHEmployees({super.key});

  @override
  State<RHEmployees> createState() => _RHEmployeesState();
}

class _RHEmployeesState extends State<RHEmployees> {
  List<User> _employees = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees({String? search}) async {
    setState(() => _isLoading = true);
    final params = <String, String>{};
    if (search != null && search.isNotEmpty) params['search'] = search;
    final result = await ApiService.get(ApiConfig.employeeList, params: params);
    if (result['success'] == true && mounted) {
      setState(() {
        _employees = (result['data'] as List).map((e) => User.fromJson(e)).toList();
        _isLoading = false;
      });
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showDocumentsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(children: [Icon(Icons.folder_shared, color: STBColors.primaryBlue), const SizedBox(width: 8), Text('Documents RH', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 18))]),
        content: Text('Le module de gestion centralisée des documents RH (dépôt, consultation, archivage) est en cours de finalisation.', style: GoogleFonts.inter()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Row(mainAxisSize: MainAxisSize.min, children: [ Image.asset('assets/images/Logo_STB.png', height: 28), const SizedBox(width: 12), const Text('Employés') ])),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher un employé...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchController.clear(); _loadEmployees(); })
                    : null,
              ),
              onChanged: (v) => _loadEmployees(search: v),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadEmployees,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _employees.length,
                      itemBuilder: (c, i) {
                        final emp = _employees[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: STBColors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: CircleAvatar(
                              backgroundColor: STBColors.primaryBlue.withValues(alpha: 0.1),
                              child: Text('${emp.prenom.isNotEmpty ? emp.prenom[0] : ''}${emp.nom.isNotEmpty ? emp.nom[0] : ''}',
                                style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: STBColors.primaryBlue)),
                            ),
                            title: Text(emp.fullName, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15)),
                            subtitle: Text('${emp.matricule} • ${emp.departement ?? ''}', style: GoogleFonts.inter(fontSize: 12, color: STBColors.textSecondary)),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: emp.role == 'rh' ? STBColors.primaryGreen.withValues(alpha: 0.1) : STBColors.info.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                emp.role.toUpperCase(),
                                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: emp.role == 'rh' ? STBColors.primaryGreen : STBColors.info),
                              ),
                            ),
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => EmployeeProfile(userId: emp.id)));
                            },
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showDocumentsDialog,
        icon: const Icon(Icons.folder_shared),
        label: const Text('Documents RH'),
        backgroundColor: STBColors.primaryBlue,
        foregroundColor: Colors.white,
      ),
    );
  }
}
