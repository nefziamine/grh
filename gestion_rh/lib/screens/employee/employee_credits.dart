import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/stb_theme.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../config/api_config.dart';
import '../../models/credit.dart';

class EmployeeCredits extends StatefulWidget {
  const EmployeeCredits({super.key});

  @override
  State<EmployeeCredits> createState() => _EmployeeCreditsState();
}

class _EmployeeCreditsState extends State<EmployeeCredits> with WidgetsBindingObserver {
  List<Credit> _credits = [];
  bool _isLoading = true;
  bool _isInitialized = false;
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AuthService.addUserChangeListener(_onUserChanged);
    _isInitialized = true;
    _loadCredits();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AuthService.removeUserChangeListener(_onUserChanged);
    super.dispose();
  }

  void _onUserChanged() {
    if (mounted && _isInitialized) _loadCredits();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted && _isInitialized) {
      // Refresh data when app comes to foreground (user switched)
      _loadCredits();
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    // For now, just print the message to avoid deactivated widget errors
    print(isError ? 'ERROR: $message' : 'SUCCESS: $message');
    // TODO: Implement a better notification system later
  }

  Future<void> _loadCredits({bool showLoading = true}) async {
    if (!mounted) return;
    
    // Only show loading state for initial loads, not for immediate refreshes
    if (showLoading && mounted) {
      setState(() => _isLoading = true);
    }
    
    try {
      // Add timestamp to prevent caching
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final result = await ApiService.get('${ApiConfig.myCredits}?t=$timestamp');
      
      if (mounted) {
        setState(() {
          _credits = (result['data'] as List?)?.map((e) => Credit.fromJson(e)).toList() ?? [];
          _isLoading = false;
        });
        
        // Debug: Print the number of credits loaded
        print('Loaded ${_credits.length} credits');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        print('Error loading credits: $e');
      }
    }
  }

  Color _getStatusColor(String statut) {
    switch (statut) {
      case 'approuve': return STBColors.approved;
      case 'refuse': return STBColors.rejected;
      case 'en_cours': return STBColors.info;
      case 'termine': return STBColors.primaryGreen;
      default: return STBColors.pending;
    }
  }

  void _showDeleteDialog(int creditId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler la demande'),
        content: const Text('Êtes-vous sûr de vouloir annuler cette demande de crédit ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final result = await ApiService.post(ApiConfig.creditDelete, {'id': creditId});
              if (result['success'] == true) {
                if (mounted) {
                  print('DEBUG: Credit deleted successfully, waiting before refresh...');
                  // Add longer delay to ensure backend processing
                  await Future.delayed(const Duration(milliseconds: 800));
                  print('DEBUG: Now refreshing credits list...');
                  _loadCredits(showLoading: false); // Immediate refresh without loading state
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

  void _showCreateDialog() async {
    // Check eligibility first
    final eligibilityResult = await ApiService.get(ApiConfig.creditCheckEligibility);
    
    if (eligibilityResult['success'] != true) {
      if (mounted) {
        _showSnackBar('Erreur lors de la vérification d\'éligibilité', isError: true);
      }
      return;
    }

    if (!eligibilityResult['can_request']) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Demande non autorisée'),
            content: Text(eligibilityResult['message'] ?? 'Vous n\'êtes pas éligible pour faire une demande de crédit.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
      return;
    }

    final montantController = TextEditingController();
    final dureeController = TextEditingController();
    final motifController = TextEditingController();
    String selectedType = 'Personnel';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: STBColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: STBColors.divider, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                Text('Demande de crédit', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 20),

                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: 'Type de crédit'),
                  items: ['Personnel', 'Immobilier', 'Automobile', 'Consommation']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (v) => setModalState(() => selectedType = v!),
                ),
                const SizedBox(height: 16),
                TextFormField(controller: montantController, decoration: const InputDecoration(labelText: 'Montant (TND)', prefixIcon: Icon(Icons.attach_money)), keyboardType: TextInputType.number),
                const SizedBox(height: 16),
                TextFormField(controller: dureeController, decoration: const InputDecoration(labelText: 'Durée (mois)', prefixIcon: Icon(Icons.schedule)), keyboardType: TextInputType.number),
                const SizedBox(height: 16),
                TextFormField(controller: motifController, maxLines: 3, decoration: const InputDecoration(labelText: 'Motif')),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    if (montantController.text.isEmpty || dureeController.text.isEmpty) {
                      _showSnackBar('Montant et durée requis', isError: true);
                      return;
                    }
                    final result = await ApiService.post(ApiConfig.creditCreate, {
                      'type_credit': selectedType,
                      'montant': double.tryParse(montantController.text) ?? 0,
                      'duree_mois': int.tryParse(dureeController.text) ?? 0,
                      'taux_interet': 7.5,
                      'motif': motifController.text,
                    });
                    if (context.mounted) Navigator.pop(context);
                    if (result['success'] == true) {
                      // Simple immediate refresh
                      if (mounted) {
                        print('DEBUG: Credit created successfully, waiting before refresh...');
                        // Add longer delay to ensure backend processing
                        await Future.delayed(const Duration(milliseconds: 800));
                        print('DEBUG: Now refreshing credits list...');
                        _loadCredits(showLoading: false); // Immediate refresh without loading state
                        _showSnackBar(result['message'] ?? 'Demande de crédit soumise avec succès');
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
      appBar: AppBar(title: Row(mainAxisSize: MainAxisSize.min, children: [ Image.asset('assets/images/Logo_STB.png', height: 28), const SizedBox(width: 12), const Text('Mes Crédits') ])),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadCredits,
              child: _credits.isEmpty
                  ? Center(child: Text('Aucun crédit', style: GoogleFonts.inter(color: STBColors.textSecondary)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _credits.length,
                      itemBuilder: (c, i) {
                        final credit = _credits[i];
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
                                  Text(credit.typeCredit, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(color: _getStatusColor(credit.statut).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                        child: Text(credit.statutLabel, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: _getStatusColor(credit.statut))),
                                      ),
                                      const SizedBox(width: 8),
                                      if (credit.statut == 'en_attente')
                                        IconButton(
                                          icon: const Icon(Icons.cancel_outlined, color: Colors.red, size: 22),
                                          onPressed: () => _showDeleteDialog(credit.id!),
                                          tooltip: 'Annuler la demande',
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  _buildCreditInfo('Montant', '${credit.montant.toStringAsFixed(2)} TND'),
                                  _buildCreditInfo('Durée', '${credit.dureeMois} mois'),
                                  _buildCreditInfo('Taux', '${credit.tauxInteret?.toStringAsFixed(2) ?? '0'}%'),
                                ],
                              ),
                              if (credit.mensualite != null && credit.mensualite! > 0) ...[
                                const SizedBox(height: 8),
                                Text('Mensualité: ${credit.mensualite!.toStringAsFixed(2)} TND', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: STBColors.primaryBlue)),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        icon: const Icon(Icons.add),
        label: const Text('Nouveau crédit'),
        backgroundColor: STBColors.primaryBlue,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildCreditInfo(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 11, color: STBColors.textSecondary)),
          Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
