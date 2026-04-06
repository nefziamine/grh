import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/stb_theme.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';
import '../../models/absence.dart';

class RHRetards extends StatefulWidget {
  const RHRetards({super.key});

  @override
  State<RHRetards> createState() => _RHRetardsState();
}

class _RHRetardsState extends State<RHRetards> {
  List<Retard> _retards = [];
  List<dynamic> _employees = [];
  bool _isLoading = true;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _loadRetards();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    final result = await ApiService.get(ApiConfig.employeeList, params: {'limit': '500'});
    if (result['success'] == true && mounted) {
      setState(() {
        _employees = result['data'];
      });
    }
  }

  Future<void> _loadRetards() async {
    setState(() => _isLoading = true);
    final result = await ApiService.get(ApiConfig.retardList, forceRefresh: true);
    if (result['success'] == true && mounted) {
      setState(() {
        _retards = (result['data'] as List).map((e) => Retard.fromJson(e)).toList();
        _isLoading = false;
      });
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Row(mainAxisSize: MainAxisSize.min, children: [ Image.asset('assets/images/Logo_STB.png', height: 40), const SizedBox(width: 12), const Text('Retards') ])),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadRetards,
              child: _retards.isEmpty
                  ? Center(child: Text('Aucun retard enregistré', style: GoogleFonts.inter(color: STBColors.textSecondary)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _retards.length,
                      itemBuilder: (c, i) {
                        final r = _retards[i];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
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
                                decoration: BoxDecoration(color: STBColors.warning.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                                child: Icon(Icons.schedule, color: STBColors.warning, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(r.employeeName, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                                    Text('${r.dateRetard} • Arrivée: ${r.heureArrivee}', style: GoogleFonts.inter(fontSize: 12, color: STBColors.textSecondary)),
                                    if (r.motif != null && r.motif!.isNotEmpty)
                                      Text(r.motif!, style: GoogleFonts.inter(fontSize: 11, color: STBColors.textSecondary, fontStyle: FontStyle.italic)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(color: STBColors.danger.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                child: Text('${r.dureeMinutes} min', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: STBColors.danger)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddRetardDialog,
        backgroundColor: STBColors.primaryBlue,
        icon: const Icon(Icons.add_alarm, color: Colors.white),
        label: Text('Ajouter Retard', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white)),
      ),
    );
  }

  void _showAddRetardDialog() {
    int? selectedUserId;
    final dateController = TextEditingController(text: DateTime.now().toString().split(' ')[0]);
    final timeController = TextEditingController(text: "08:15");
    final durationController = TextEditingController();
    final motifController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Enregistrer un retard', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: STBColors.primaryBlue)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(labelText: 'Employé'),
                  items: _employees.map<DropdownMenuItem<int>>((e) {
                    return DropdownMenuItem<int>(
                      value: int.tryParse(e['id'].toString()),
                      child: Text('${e['prenom']} ${e['nom']} (${e['matricule']} - ${e['role']})', style: GoogleFonts.inter(fontSize: 12)),
                    );
                  }).toList(),
                  onChanged: (val) => setDialogState(() => selectedUserId = val),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: dateController,
                  decoration: const InputDecoration(labelText: 'Date (AAAA-MM-JJ)', suffixIcon: Icon(Icons.calendar_today)),
                  readOnly: true,
                  onTap: () async {
                    final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2024), lastDate: DateTime(2026));
                    if (d != null) dateController.text = d.toString().split(' ')[0];
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: timeController,
                  decoration: const InputDecoration(labelText: 'Heure d\'arrivée (HH:MM)', suffixIcon: Icon(Icons.access_time)),
                  readOnly: true,
                  onTap: () async {
                    final t = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 8, minute: 15));
                    if (t != null) timeController.text = "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: durationController,
                  decoration: const InputDecoration(labelText: 'Durée (minutes)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: motifController,
                  decoration: const InputDecoration(labelText: 'Motif (Optionnel)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: _isCreating ? null : () async {
                if (selectedUserId == null || durationController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez remplir les champs obligatoires')));
                  return;
                }
                
                setDialogState(() => _isCreating = true);
                final res = await ApiService.post(ApiConfig.retardCreate, {
                  'user_id': selectedUserId,
                  'date_retard': dateController.text,
                  'heure_arrivee': timeController.text,
                  'duree_minutes': int.parse(durationController.text),
                  'motif': motifController.text,
                });
                
                if (mounted) {
                  setDialogState(() => _isCreating = false);
                  Navigator.pop(ctx);
                  if (res['success'] == true) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Retard enregistré avec succès')));
                    _loadRetards();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Erreur lors de l\'enregistrement')));
                  }
                }
              },
              child: _isCreating ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
  }
}
