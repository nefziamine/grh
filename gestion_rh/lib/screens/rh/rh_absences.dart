import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/stb_theme.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';
import '../../models/absence.dart';
import '../../models/user.dart';

class RHAbsences extends StatefulWidget {
  const RHAbsences({super.key});

  @override
  State<RHAbsences> createState() => _RHAbsencesState();
}

class _RHAbsencesState extends State<RHAbsences> {
  List<Absence> _absences = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAbsences();
  }

  Future<void> _loadAbsences() async {
    setState(() => _isLoading = true);
    final result = await ApiService.get(
      ApiConfig.absenceList,
      params: {'all_pending': '1'},
      forceRefresh: true,
    );
    if (result['success'] == true && mounted) {
      final data = result['data'];
      setState(() {
        _absences = data is List
            ? data.map((e) => Absence.fromJson(e as Map<String, dynamic>)).toList()
            : [];
        _isLoading = false;
      });
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Impossible de charger les absences'),
            backgroundColor: STBColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _verifyPendingAbsence(Absence absence, String status) async {
    final pointageId = absence.pointageId ?? absence.id;
    final result = await ApiService.post(ApiConfig.pointageVerify, {
      'id': pointageId,
      'status': status,
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Action effectuée'),
          backgroundColor: status == 'valide'
              ? STBColors.primaryGreen
              : STBColors.danger,
        ),
      );
      if (result['success'] == true) {
        _loadAbsences();
      }
    }
  }

  void _showAddAbsenceDialog() {
    String? selectedUserId;
    String selectedType = 'injustifiee';
    DateTime? selectedDate;
    final motifC = TextEditingController();
    List<User> employees = [];
    bool loadingEmployees = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (ctx, setModalState) {
          if (loadingEmployees) {
            ApiService.get(ApiConfig.employeeList, params: {'limit': '100'}).then((result) {
              if (result['success'] == true) {
                setModalState(() {
                  employees = (result['data'] as List).map((e) => User.fromJson(e)).toList();
                  loadingEmployees = false;
                });
              }
            });
          }
          return Container(
            height: MediaQuery.of(context).size.height * 0.65,
            decoration: const BoxDecoration(color: STBColors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: STBColors.divider, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                Text('Enregistrer une absence', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 20),
                if (loadingEmployees) const Center(child: CircularProgressIndicator())
                else DropdownButtonFormField<String>(
                  value: selectedUserId,
                  decoration: const InputDecoration(labelText: 'Employé'),
                  items: employees.map((e) => DropdownMenuItem(
                    value: e.id.toString(), 
                    child: Text('${e.fullName} (${e.matricule} - ${e.role})', style: GoogleFonts.inter(fontSize: 12))
                  )).toList(),
                  onChanged: (v) => setModalState(() => selectedUserId = v),
                ),
                const SizedBox(height: 12),
                ListTile(
                  title: Text(selectedDate != null ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}' : 'Sélectionner'),
                  subtitle: const Text('Date d\'absence'),
                  leading: Icon(Icons.calendar_today, color: STBColors.primaryBlue),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: STBColors.divider)),
                  onTap: () async {
                    final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now().subtract(const Duration(days: 365)), lastDate: DateTime.now());
                    if (d != null) setModalState(() => selectedDate = d);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: const [
                    DropdownMenuItem(value: 'injustifiee', child: Text('Injustifiée')),
                    DropdownMenuItem(value: 'justifiee', child: Text('Justifiée')),
                  ],
                  onChanged: (v) => setModalState(() => selectedType = v!),
                ),
                const SizedBox(height: 12),
                TextFormField(controller: motifC, decoration: const InputDecoration(labelText: 'Motif')),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedUserId == null || selectedDate == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Employé et date requis')));
                      return;
                    }
                    final result = await ApiService.post(ApiConfig.absenceCreate, {
                      'user_id': int.parse(selectedUserId!),
                      'date_absence': '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}',
                      'type_absence': selectedType,
                      'motif': motifC.text,
                    });
                    if (context.mounted) Navigator.pop(context);
                    if (result['success'] == true) _loadAbsences();
                  },
                  child: const Text('Enregistrer'),
                ),
              ],
            )),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pending = _absences.where((a) => a.isPending).length;
    final confirmed = _absences.where((a) => !a.isPending).toList();
    final justified = confirmed.where((a) => a.typeAbsence == 'justifiee').length;
    final unjustified = confirmed.where((a) => a.typeAbsence == 'injustifiee').length;

    return Scaffold(
      appBar: AppBar(title: Row(mainAxisSize: MainAxisSize.min, children: [ Image.asset('assets/images/Logo_STB.png', height: 40), const SizedBox(width: 12), const Text('Absences') ])),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAbsences,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(child: _buildStatChip('En attente', '$pending', STBColors.warning)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildStatChip('Confirmées', '${confirmed.length}', STBColors.primaryBlue)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildStatChip('Injustifiées', '$unjustified', STBColors.danger)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _absences.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                'Aucune absence pour le moment.\nLes absences automatiques apparaissent ici après 10:00.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(color: STBColors.textSecondary),
                              ),
                            ),
                          )
                        : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _absences.length,
                      itemBuilder: (c, i) {
                        final absence = _absences[i];
                        final isPending = absence.isPending;
                        final isUnjustified = absence.typeAbsence == 'injustifiee';
                        final accentColor = isPending
                            ? STBColors.warning
                            : isUnjustified
                            ? STBColors.danger
                            : STBColors.approved;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: STBColors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: accentColor.withValues(alpha: 0.25)),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: accentColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      isPending
                                          ? Icons.hourglass_empty
                                          : isUnjustified
                                          ? Icons.warning_amber
                                          : Icons.check_circle,
                                      color: accentColor,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(absence.employeeName, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                                        Text(
                                          '${absence.dateAbsence} • ${isPending ? 'En attente validation' : absence.typeLabel}',
                                          style: GoogleFonts.inter(fontSize: 12, color: STBColors.textSecondary),
                                        ),
                                        if (absence.motif != null && absence.motif!.isNotEmpty)
                                          Text(absence.motif!, style: GoogleFonts.inter(fontSize: 11, color: STBColors.textSecondary, fontStyle: FontStyle.italic)),
                                      ],
                                    ),
                                  ),
                                  if (isPending)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: STBColors.warning.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'AUTO',
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: STBColors.warning,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              if (isPending) ...[
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => _verifyPendingAbsence(absence, 'rejete'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: STBColors.danger,
                                          side: const BorderSide(color: STBColors.danger),
                                        ),
                                        child: const Text('Rejeter'),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () => _verifyPendingAbsence(absence, 'valide'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: STBColors.primaryBlue,
                                          foregroundColor: Colors.white,
                                        ),
                                        child: const Text('Approuver'),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddAbsenceDialog,
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
        backgroundColor: STBColors.primaryBlue,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text(value, style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: color)),
        ],
      ),
    );
  }
}
