import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/stb_theme.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';
import '../../models/conge.dart';

class RHConges extends StatefulWidget {
  const RHConges({super.key});

  @override
  State<RHConges> createState() => _RHCongesState();
}

class _RHCongesState extends State<RHConges> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Conge> _allConges = [];
  bool _isLoading = true;
  String _selectedFilter = 'Toutes';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadConges();
  }

  Future<void> _loadConges({bool showLoading = true}) async {
    if (showLoading) setState(() => _isLoading = true);
    final result = await ApiService.get(ApiConfig.congeList, forceRefresh: true);
    if (result['success'] == true && mounted) {
      setState(() {
        _allConges = (result['data'] as List).map((e) => Conge.fromJson(e)).toList();
        _isLoading = false;
      });
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Conge> _filterByStatus(String statut) {
    return _allConges.where((c) {
      bool matchStatus = c.statut == statut;
      bool matchType = _selectedFilter == 'Toutes' || c.typeConge == _selectedFilter;
      return matchStatus && matchType;
    }).toList();
  }

  void _showFilterMenu() {
    final types = {
      'Toutes': 'Toutes les causes',
      'annuel': 'Congé Annuel',
      'maladie': 'Congé Maladie',
      'maternite': 'Maternité',
      'sans_solde': 'Sans Solde',
      'exceptionnel': 'Exceptionnel',
    };

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Text('Filtrer par cause', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const Divider(),
            ...types.entries.map((e) => ListTile(
              title: Text(e.value, style: GoogleFonts.inter(fontWeight: _selectedFilter == e.key ? FontWeight.bold : FontWeight.normal)),
              trailing: _selectedFilter == e.key ? const Icon(Icons.check_circle, color: STBColors.primaryBlue) : null,
              onTap: () {
                setState(() => _selectedFilter = e.key);
                Navigator.pop(context);
              },
            )),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showActionDialog(Conge conge) {
    final commentController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return FutureBuilder(
              future: Future.wait([
                ApiService.get(ApiConfig.employeeRead, params: {'id': conge.userId.toString()}),
                ApiService.get(ApiConfig.congeList, params: {'user_id': conge.userId.toString(), 'limit': '5'}),
              ]),
              builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
                bool isLoading = snapshot.connectionState == ConnectionState.waiting;
                Map<String, dynamic>? employeeData;
                List<Conge> history = [];

                if (snapshot.hasData) {
                  final empResult = snapshot.data![0];
                  final histResult = snapshot.data![1];
                  
                  if (empResult['success'] == true) {
                    employeeData = empResult['data'];
                  }
                  
                  if (histResult['success'] == true) {
                    history = (histResult['data'] as List)
                        .map((e) => Conge.fromJson(e))
                        .where((c) => c.id != conge.id) // Exclude current request
                        .toList();
                  }
                }

                return AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  title: Row(
                    children: [
                      const Icon(Icons.history, color: STBColors.primaryBlue),
                      const SizedBox(width: 10),
                      Text('Analyse et Traitement', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  content: SizedBox(
                    width: double.maxFinite,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Employee Summary Card
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: STBColors.primaryBlue.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: STBColors.primaryBlue.withValues(alpha: 0.1)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${conge.employeeName}', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text('Matricule: ${conge.matricule ?? 'N/A'} • ${conge.departement ?? ''}', style: GoogleFonts.inter(fontSize: 12, color: STBColors.textSecondary)),
                                const Divider(),
                                if (isLoading)
                                  const Center(child: Padding(padding: EdgeInsets.all(8.0), child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))))
                                else if (employeeData != null)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Solde actuel:', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(color: STBColors.primaryBlue, borderRadius: BorderRadius.circular(20)),
                                        child: Text('${employeeData['solde_conge'] ?? 0} jours', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          Text('Détails de la demande:', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                          const SizedBox(height: 8),
                          Text('Type: ${conge.typeLabel}', style: GoogleFonts.inter(fontSize: 13)),
                          Text('Période: ${conge.dateDebut} → ${conge.dateFin}', style: GoogleFonts.inter(fontSize: 13)),
                          Text('Durée: ${conge.nbJours} jours', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: STBColors.primaryBlue)),
                          if (conge.motif != null && conge.motif!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text('Motif: ${conge.motif}', style: GoogleFonts.inter(fontSize: 12, fontStyle: FontStyle.italic, color: STBColors.textSecondary)),
                          ],
                          
                          const SizedBox(height: 20),
                          Text('Historique récent:', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                          const SizedBox(height: 8),
                          if (isLoading)
                            const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()))
                          else if (history.isEmpty)
                            Text('Aucun historique trouvé.', style: GoogleFonts.inter(fontSize: 12, color: STBColors.textSecondary))
                          else
                            ...history.take(3).map((h) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  Icon(Icons.circle, size: 8, color: h.statut == 'approuve' ? STBColors.approved : STBColors.rejected),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text('${h.typeLabel} (${h.nbJours}j)', style: GoogleFonts.inter(fontSize: 12))),
                                  Text(h.dateDebut, style: GoogleFonts.inter(fontSize: 11, color: STBColors.textSecondary)),
                                ],
                              ),
                            )),

                          const SizedBox(height: 24),
                          TextField(
                            controller: commentController,
                            maxLines: 2,
                            decoration: InputDecoration(
                              labelText: 'Commentaire RH',
                              labelStyle: GoogleFonts.inter(fontSize: 13),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              hintText: 'Expliquez votre décision...',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Annuler', style: GoogleFonts.inter(color: STBColors.textSecondary)),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        final result = await ApiService.post(ApiConfig.congeUpdateStatus, {
                          'id': conge.id, 'statut': 'refuse', 'commentaire_rh': commentController.text,
                        });
                        if (result['success'] == true) _loadConges(showLoading: false);
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? ''), backgroundColor: result['success'] == true ? STBColors.success : STBColors.danger));
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: STBColors.danger, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      child: const Text('Refuser'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        final result = await ApiService.post(ApiConfig.congeUpdateStatus, {
                          'id': conge.id, 'statut': 'approuve', 'commentaire_rh': commentController.text,
                        });
                        if (result['success'] == true) _loadConges(showLoading: false);
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? ''), backgroundColor: result['success'] == true ? STBColors.success : STBColors.danger));
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: STBColors.approved, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      child: const Text('Approuver'),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final pending = _filterByStatus('en_attente');
    final approved = _filterByStatus('approuve');
    final rejected = _filterByStatus('refuse');

    return Scaffold(
      appBar: AppBar(
        title: Text('Gestion des Congés', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.filter_list),
                if (_selectedFilter != 'Toutes') 
                  Positioned(right: 0, top: 0, child: Container(padding: const EdgeInsets.all(2), decoration: const BoxDecoration(color: STBColors.warning, shape: BoxShape.circle), constraints: const BoxConstraints(minWidth: 8, minHeight: 8))),
              ],
            ),
            onPressed: _showFilterMenu,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: STBColors.white,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 13),
          unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w400, fontSize: 13),
          labelColor: STBColors.white,
          unselectedLabelColor: STBColors.white.withValues(alpha: 0.6),
          tabs: [
            Tab(text: 'En attente (${pending.length})'),
            Tab(text: 'Approuvés (${approved.length})'),
            Tab(text: 'Refusés (${rejected.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildCongeList(pending, showActions: true),
                _buildCongeList(approved),
                _buildCongeList(rejected),
              ],
            ),
    );
  }

  Widget _buildCongeList(List<Conge> conges, {bool showActions = false}) {
    if (conges.isEmpty) {
      return Center(child: Text('Aucune demande', style: GoogleFonts.inter(color: STBColors.textSecondary)));
    }
    return RefreshIndicator(
      onRefresh: _loadConges,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: conges.length,
        itemBuilder: (c, i) {
          final conge = conges[i];
          Color statusColor;
          switch (conge.statut) {
            case 'approuve': statusColor = STBColors.approved; break;
            case 'refuse': statusColor = STBColors.rejected; break;
            default: statusColor = STBColors.pending;
          }
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: STBColors.white,
              borderRadius: BorderRadius.circular(14),
              border: showActions ? Border.all(color: STBColors.warning.withValues(alpha: 0.3)) : null,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: STBColors.primaryBlue.withValues(alpha: 0.1),
                      child: Text(conge.employeeName.isNotEmpty ? conge.employeeName[0] : '?', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: STBColors.primaryBlue, fontSize: 14)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(conge.employeeName, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                          Text('${conge.matricule ?? ''} • ${conge.departement ?? ''}', style: GoogleFonts.inter(fontSize: 11, color: STBColors.textSecondary)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                      child: Text(conge.statutLabel, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: STBColors.primaryBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                      child: Text(conge.typeLabel, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: STBColors.primaryBlue)),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.date_range, size: 14, color: STBColors.textSecondary),
                    const SizedBox(width: 4),
                    Text('${conge.dateDebut} → ${conge.dateFin}', style: GoogleFonts.inter(fontSize: 12, color: STBColors.textPrimary)),
                    const Spacer(),
                    Text('${conge.nbJours}j', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
                if (showActions) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _showActionDialog(conge),
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
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
