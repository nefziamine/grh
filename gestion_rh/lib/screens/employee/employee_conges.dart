import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/stb_theme.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../config/api_config.dart';
import '../../models/conge.dart';

class EmployeeConges extends StatefulWidget {
  const EmployeeConges({super.key});

  @override
  State<EmployeeConges> createState() => _EmployeeCongesState();
}

class _EmployeeCongesState extends State<EmployeeConges> with WidgetsBindingObserver {
  List<Conge> _conges = [];
  int _soldeConge = 0;
  bool _isLoading = true;
  bool _isInitialized = false;
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AuthService.addUserChangeListener(_onUserChanged);
    _isInitialized = true;
    _loadConges();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AuthService.removeUserChangeListener(_onUserChanged);
    super.dispose();
  }

  void _onUserChanged() {
    if (mounted && _isInitialized) _loadConges();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted && _isInitialized) {
      // Refresh data when app comes to foreground (user switched)
      _loadConges();
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    // For now, just print the message to avoid deactivated widget errors
    print(isError ? 'ERROR: $message' : 'SUCCESS: $message');
    // TODO: Implement a better notification system later
  }

  Future<void> _loadConges({bool showLoading = true}) async {
    if (!mounted) return;
    
    // Only show loading state for initial loads, not for immediate refreshes
    if (showLoading && mounted) {
      setState(() => _isLoading = true);
    }
    
    try {
      // Add timestamp to prevent caching
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      print('DEBUG: Making API call to ${ApiConfig.myConges}?t=$timestamp');
      final result = await ApiService.get('${ApiConfig.myConges}?t=$timestamp');
      print('DEBUG: API response: $result');
      
      if (mounted) {
        setState(() {
          _conges = (result['data'] as List?)?.map((e) => Conge.fromJson(e)).toList() ?? [];
          _soldeConge = result['solde_conge'] ?? 0;
          _isLoading = false;
        });
        
        // Debug: Print the number of congés loaded
        print('Loaded ${_conges.length} congés');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        print('Error loading congés: $e');
      }
    }
  }

  Color _getStatusColor(String statut) {
    switch (statut) {
      case 'approuve': return STBColors.approved;
      case 'refuse': return STBColors.rejected;
      default: return STBColors.pending;
    }
  }

  IconData _getStatusIcon(String statut) {
    switch (statut) {
      case 'approuve': return Icons.check_circle;
      case 'refuse': return Icons.cancel;
      default: return Icons.hourglass_empty;
    }
  }

  void _showDeleteDialog(int congeId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler la demande'),
        content: const Text('Êtes-vous sûr de vouloir annuler cette demande de congé ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final result = await ApiService.post(ApiConfig.congeDelete, {'id': congeId});
              if (result['success'] == true) {
                if (mounted) {
                  print('DEBUG: Congé deleted successfully, waiting before refresh...');
                  // Add longer delay to ensure backend processing
                  await Future.delayed(const Duration(milliseconds: 800));
                  print('DEBUG: Now refreshing congé list...');
                  _loadConges(showLoading: false); // Immediate refresh without loading state
                  _showSnackBar(result['message'] ?? 'Demande supprimée');
                }
              } else {
                if (mounted) {
                  _showSnackBar(result['message'] ?? 'Erreur', isError: true);
                }
              }
            },
            child: const Text('Annuler la demande', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showCreateDialog() {
    final motifController = TextEditingController();
    DateTime? dateDebut;
    DateTime? dateFin;
    String selectedType = 'annuel';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: STBColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(width: 40, height: 4, decoration: BoxDecoration(color: STBColors.divider, borderRadius: BorderRadius.circular(2))),
                ),
                const SizedBox(height: 20),
                Text('Nouvelle demande de congé', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text('Solde actuel: $_soldeConge jours', style: GoogleFonts.inter(fontSize: 13, color: STBColors.primaryBlue, fontWeight: FontWeight.w500)),
                const SizedBox(height: 20),

                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: 'Type de congé'),
                  items: const [
                    DropdownMenuItem(value: 'annuel', child: Text('Annuel')),
                    DropdownMenuItem(value: 'maladie', child: Text('Maladie')),
                    DropdownMenuItem(value: 'maternite', child: Text('Maternité')),
                    DropdownMenuItem(value: 'sans_solde', child: Text('Sans solde')),
                    DropdownMenuItem(value: 'exceptionnel', child: Text('Exceptionnel')),
                  ],
                  onChanged: (v) => setModalState(() => selectedType = v!),
                ),
                const SizedBox(height: 16),

                ListTile(
                  title: Text(dateDebut != null ? '${dateDebut!.day}/${dateDebut!.month}/${dateDebut!.year}' : 'Sélectionner'),
                  subtitle: const Text('Date de début'),
                  leading: Icon(Icons.calendar_today, color: STBColors.primaryBlue),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: STBColors.divider)),
                  onTap: () async {
                    final d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                    if (d != null) setModalState(() => dateDebut = d);
                  },
                ),
                const SizedBox(height: 12),
                ListTile(
                  title: Text(dateFin != null ? '${dateFin!.day}/${dateFin!.month}/${dateFin!.year}' : 'Sélectionner'),
                  subtitle: const Text('Date de fin'),
                  leading: Icon(Icons.calendar_today, color: STBColors.primaryBlue),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: STBColors.divider)),
                  onTap: () async {
                    final d = await showDatePicker(context: context, initialDate: dateDebut ?? DateTime.now(), firstDate: dateDebut ?? DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                    if (d != null) setModalState(() => dateFin = d);
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: motifController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Motif', hintText: 'Raison de la demande...'),
                ),
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: () async {
                    if (dateDebut == null || dateFin == null) {
                      _showSnackBar('Veuillez sélectionner les dates', isError: true);
                      return;
                    }
                    final nbJours = dateFin!.difference(dateDebut!).inDays + 1;
                    final result = await ApiService.post(ApiConfig.congeCreate, {
                      'type_conge': selectedType,
                      'date_debut': '${dateDebut!.year}-${dateDebut!.month.toString().padLeft(2, '0')}-${dateDebut!.day.toString().padLeft(2, '0')}',
                      'date_fin': '${dateFin!.year}-${dateFin!.month.toString().padLeft(2, '0')}-${dateFin!.day.toString().padLeft(2, '0')}',
                      'nb_jours': nbJours,
                      'motif': motifController.text,
                    });
                    if (context.mounted) Navigator.pop(context);
                    if (result['success'] == true) {
                      // Simple immediate refresh
                      if (mounted) {
                        print('DEBUG: Congé created successfully, waiting before refresh...');
                        // Add longer delay to ensure backend processing
                        await Future.delayed(const Duration(milliseconds: 800));
                        print('DEBUG: Now refreshing congé list...');
                        _loadConges(showLoading: false); // Immediate refresh without loading state
                        _showSnackBar(result['message'] ?? 'Demande de congé soumise avec succès');
                      }
                    } else {
                      if (mounted) {
                        _showSnackBar(result['message'] ?? 'Erreur', isError: true);
                      }
                    }
                  },
                  child: const Text('Soumettre la demande'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(title: Row(mainAxisSize: MainAxisSize.min, children: [ Image.asset('assets/images/Logo_STB.png', height: 28), const SizedBox(width: 12), const Text('Mes Congés') ])),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadConges,
              child: Column(
                children: [
                  // Balance card
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [STBColors.gradientStart, STBColors.gradientEnd]),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Solde de congé', style: GoogleFonts.inter(fontSize: 14, color: STBColors.white.withValues(alpha: 0.8))),
                            const SizedBox(height: 4),
                            Text('$_soldeConge jours', style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w800, color: STBColors.white)),
                          ],
                        ),
                        Icon(Icons.beach_access, size: 50, color: STBColors.white.withValues(alpha: 0.3)),
                      ],
                    ),
                  ),
                  // List
                  Expanded(
                    child: _conges.isEmpty
                        ? Center(child: Text('Aucune demande de congé', style: GoogleFonts.inter(color: STBColors.textSecondary)))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _conges.length,
                            itemBuilder: (c, i) {
                              final conge = _conges[i];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: STBColors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: STBColors.primaryBlue.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(conge.typeLabel, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: STBColors.primaryBlue)),
                                        ),
                                        Row(
                                          children: [
                                            Icon(_getStatusIcon(conge.statut), size: 16, color: _getStatusColor(conge.statut)),
                                            const SizedBox(width: 4),
                                            Text(conge.statutLabel, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: _getStatusColor(conge.statut))),
                                            const SizedBox(width: 8),
                                            if (conge.statut == 'en_attente')
                                              IconButton(
                                                icon: const Icon(Icons.cancel_outlined, color: Colors.red, size: 22),
                                                onPressed: () => _showDeleteDialog(conge.id!),
                                                tooltip: 'Annuler la demande',
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Icon(Icons.date_range, size: 16, color: STBColors.textSecondary),
                                        const SizedBox(width: 6),
                                        Text('${conge.dateDebut} → ${conge.dateFin}', style: GoogleFonts.inter(fontSize: 13, color: STBColors.textPrimary)),
                                        const Spacer(),
                                        Text('${conge.nbJours} jours', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: STBColors.textPrimary)),
                                      ],
                                    ),
                                    if (conge.motif != null && conge.motif!.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(conge.motif!, style: GoogleFonts.inter(fontSize: 12, color: STBColors.textSecondary)),
                                    ],
                                    if (conge.commentaireRh != null && conge.commentaireRh!.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(color: STBColors.bgLight, borderRadius: BorderRadius.circular(8)),
                                        child: Row(
                                          children: [
                                            Icon(Icons.comment, size: 14, color: STBColors.textSecondary),
                                            const SizedBox(width: 6),
                                            Expanded(child: Text('RH: ${conge.commentaireRh}', style: GoogleFonts.inter(fontSize: 12, color: STBColors.textSecondary, fontStyle: FontStyle.italic))),
                                          ],
                                        ),
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
        onPressed: _showCreateDialog,
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle demande'),
        backgroundColor: STBColors.primaryBlue,
        foregroundColor: Colors.white,
      ),
    );
  }
}
