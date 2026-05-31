import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/stb_theme.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';

class RHPointages extends StatefulWidget {
  const RHPointages({super.key});

  @override
  State<RHPointages> createState() => _RHPointagesState();
}

class _RHPointagesState extends State<RHPointages> {
  List<dynamic> _pointages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPointages();
  }

  Future<void> _loadPointages() async {
    setState(() => _isLoading = true);
    final result = await ApiService.get(ApiConfig.pointageList);
    if (result['success'] == true && mounted) {
      setState(() {
        _pointages = result['data'] ?? [];
        _isLoading = false;
      });
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyPointage(int id, String status) async {
    final result = await ApiService.post(ApiConfig.pointageVerify, {
      'id': id,
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
        _loadPointages();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Validation des Pointages',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        backgroundColor: STBColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_search_outlined),
            tooltip: 'Scanner les retards manquants',
            onPressed: _scanMissingRetards,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadPointages,
              child: _pointages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.fact_check_outlined,
                            size: 80,
                            color: STBColors.textSecondary.withValues(
                              alpha: 0.2,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun pointage en attente',
                            style: GoogleFonts.inter(
                              color: STBColors.textSecondary,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _pointages.length,
                      itemBuilder: (c, i) {
                        final p = _pointages[i];
                        final isLate = p['type_action'] == 'retard';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          elevation: 0,
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: STBColors.primaryBlue
                                          .withValues(alpha: 0.1),
                                      child: Text(
                                        p['prenom'][0] + p['nom'][0],
                                        style: const TextStyle(
                                          color: STBColors.primaryBlue,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${p['prenom']} ${p['nom']}',
                                            style: GoogleFonts.inter(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 16,
                                            ),
                                          ),
                                          Text(
                                            '${p['departement']} • Mat: ${p['matricule']}',
                                            style: GoogleFonts.inter(
                                              fontSize: 12,
                                              color: STBColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isLate
                                            ? STBColors.warning.withValues(
                                                alpha: 0.1,
                                              )
                                            : STBColors.primaryGreen.withValues(
                                                alpha: 0.1,
                                              ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        isLate ? 'RETARD' : 'PONCTUEL',
                                        style: GoogleFonts.inter(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: isLate
                                              ? STBColors.warning
                                              : STBColors.primaryGreen,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  child: Divider(),
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Arrivée à',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: STBColors.textSecondary,
                                          ),
                                        ),
                                        Text(
                                          p['heure_pointage'],
                                          style: GoogleFonts.inter(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                            color: STBColors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        OutlinedButton(
                                          onPressed: () => _verifyPointage(
                                            int.parse(p['id'].toString()),
                                            'rejete',
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: STBColors.danger,
                                            side: const BorderSide(
                                              color: STBColors.danger,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          child: const Text('Rejeter'),
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton(
                                          onPressed: () => _verifyPointage(
                                            int.parse(p['id'].toString()),
                                            'valide',
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                STBColors.primaryBlue,
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          child: const Text('Confirmer'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }

  Future<void> _scanMissingRetards() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final res = await ApiService.post(ApiConfig.pointageGenerateAbsences, {});
    if (!mounted) return;
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(res['message'] ?? 'Scanner terminé')),
    );
    _loadPointages();
  }
}
