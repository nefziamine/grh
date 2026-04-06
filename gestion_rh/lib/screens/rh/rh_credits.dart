import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/stb_theme.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';
import '../../models/credit.dart';

class RHCredits extends StatefulWidget {
  const RHCredits({super.key});

  @override
  State<RHCredits> createState() => _RHCreditsState();
}

class _RHCreditsState extends State<RHCredits> {
  List<Credit> _credits = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCredits();
  }

  Future<void> _loadCredits() async {
    setState(() => _isLoading = true);
    final result = await ApiService.get(ApiConfig.creditList);
    if (result['success'] == true && mounted) {
      setState(() {
        _credits = (result['data'] as List).map((e) => Credit.fromJson(e)).toList();
        _isLoading = false;
      });
    } else {
      if (mounted) setState(() => _isLoading = false);
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

  void _showActionDialog(Credit credit) {
    final commentController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Traiter le crédit', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(credit.employeeName, style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
            Text('${credit.typeCredit} • ${credit.montant.toStringAsFixed(2)} TND', style: GoogleFonts.inter(fontSize: 13, color: STBColors.textSecondary)),
            Text('${credit.dureeMois} mois • ${credit.tauxInteret}%', style: GoogleFonts.inter(fontSize: 13, color: STBColors.textSecondary)),
            const SizedBox(height: 16),
            TextField(controller: commentController, maxLines: 2, decoration: const InputDecoration(labelText: 'Commentaire')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Annuler', style: GoogleFonts.inter(color: STBColors.textSecondary))),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await ApiService.post(ApiConfig.creditUpdateStatus, {'id': credit.id, 'statut': 'refuse', 'commentaire_rh': commentController.text});
              _loadCredits();
            },
            style: ElevatedButton.styleFrom(backgroundColor: STBColors.danger),
            child: const Text('Refuser'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await ApiService.post(ApiConfig.creditUpdateStatus, {'id': credit.id, 'statut': 'approuve', 'commentaire_rh': commentController.text});
              _loadCredits();
            },
            style: ElevatedButton.styleFrom(backgroundColor: STBColors.approved),
            child: const Text('Approuver'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Row(mainAxisSize: MainAxisSize.min, children: [ Image.asset('assets/images/Logo_STB.png', height: 40), const SizedBox(width: 12), const Text('Crédits Employés') ])),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadCredits,
              child: ListView.builder(
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
                          children: [
                            Expanded(child: Text(credit.employeeName, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15))),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: _getStatusColor(credit.statut).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                              child: Text(credit.statutLabel, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: _getStatusColor(credit.statut))),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('${credit.typeCredit} • ${credit.montant.toStringAsFixed(2)} TND', style: GoogleFonts.inter(fontSize: 13, color: STBColors.textPrimary)),
                        Text('${credit.dureeMois} mois • Taux: ${credit.tauxInteret}%', style: GoogleFonts.inter(fontSize: 12, color: STBColors.textSecondary)),
                        if (credit.statut == 'en_attente') ...[
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () => _showActionDialog(credit),
                                icon: const Icon(Icons.gavel, size: 16),
                                label: const Text('Traiter'),
                                style: OutlinedButton.styleFrom(foregroundColor: STBColors.primaryBlue),
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
    );
  }
}
