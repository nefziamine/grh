import 'package:flutter/material.dart';
import '../../config/api_config.dart';
import '../../services/api_service.dart';
import '../../theme/stb_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/auth_service.dart';

class RhDocumentsScreen extends StatefulWidget {
  const RhDocumentsScreen({super.key});

  @override
  State<RhDocumentsScreen> createState() => _RhDocumentsScreenState();
}

class _RhDocumentsScreenState extends State<RhDocumentsScreen> {
  bool _isLoading = true;
  List<dynamic> _documents = [];
  final List<Map<String, String>> _defaultDocuments = [
    {
      'titre': 'STB Indicators as of 31/12/2024',
      'description':
          'Rapport officiel des indicateurs financiers de STB au 31 décembre 2024.',
      'url':
          'https://www.stb.com.tn/en/the-bank/stb-indicators-as-of-31-12-2024/',
      'categorie': 'BANQUE',
    },
    {
      'titre': 'Moody’s upgrades STB’s rating',
      'description':
          'Communiqué officiel STB sur l’amélioration de la note Moody’s.',
      'url':
          'https://www.stb.com.tn/en/press/moodys-upgrades-stbs-rating-a-sign-of-confidence-and-financial-stability/',
      'categorie': 'BANQUE',
    },
    {
      'titre': 'Regulatory notices and compliance updates',
      'description':
          'Page officielle des avis réglementaires STB et documents de conformité.',
      'url': 'https://www.stb.com.tn/en/important-links/',
      'categorie': 'BANQUE',
    },
    {
      'titre': 'STB Annual Report 2023',
      'description': 'Rapport annuel 2023 publié par la banque STB.',
      'url': 'https://www.stb.com.tn/en/press/annual-report-2023/',
      'categorie': 'BANQUE',
    },
    {
      'titre': 'STB Corporate Governance',
      'description': 'Document de gouvernance d’entreprise officiel de STB.',
      'url': 'https://www.stb.com.tn/en/the-bank/corporate-governance/',
      'categorie': 'BANQUE',
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchDocuments();
  }

  Future<void> _fetchDocuments() async {
    setState(() => _isLoading = true);
    final result = await ApiService.get(ApiConfig.documentList);
    if (result['success'] == true) {
      setState(() {
        _documents = (result['data'] as List<dynamic>?)?.cast<dynamic>() ?? [];
        if (_documents.isEmpty) {
          _documents = List<dynamic>.from(_defaultDocuments);
        }
        _isLoading = false;
      });
    } else {
      setState(() {
        _documents = List<dynamic>.from(_defaultDocuments);
        _isLoading = false;
      });
    }
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible d\'ouvrir ce lien')),
        );
      }
    }
  }

  void _showAddDocumentDialog() {
    final titreC = TextEditingController();
    final descC = TextEditingController();
    final urlC = TextEditingController();
    String selectedCat = 'RH';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
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
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: STBColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Ajouter un document',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: STBColors.primaryBlue,
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: titreC,
                  decoration: const InputDecoration(
                    labelText: 'Titre du document',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descC,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: urlC,
                  decoration: const InputDecoration(
                    labelText: 'URL du document (ou lien OneDrive/Sharepoint)',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedCat,
                  decoration: const InputDecoration(labelText: 'Catégorie'),
                  items: const [
                    DropdownMenuItem(
                      value: 'RH',
                      child: Text('Ressources Humaines'),
                    ),
                    DropdownMenuItem(value: 'BANQUE', child: Text('Bancaire')),
                    DropdownMenuItem(
                      value: 'AVANTAGES',
                      child: Text('Avantages & Social'),
                    ),
                    DropdownMenuItem(value: 'AUTRE', child: Text('Autre')),
                  ],
                  onChanged: (v) => setModalState(() => selectedCat = v!),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    if (titreC.text.isEmpty || urlC.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Titre et URL requis')),
                      );
                      return;
                    }
                    final result =
                        await ApiService.post(ApiConfig.documentCreate, {
                          'titre': titreC.text,
                          'description': descC.text,
                          'url': urlC.text,
                          'categorie': selectedCat,
                        });
                    if (context.mounted) Navigator.pop(context);
                    if (result['success'] == true) _fetchDocuments();
                  },
                  child: const Text('Enregistrer'),
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
      backgroundColor: STBColors.bgLight,
      appBar: AppBar(
        title: Text(
          'Documents Officiels STB',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: STBColors.primaryBlue,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchDocuments,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _documents.length,
                itemBuilder: (context, index) {
                  final doc = _documents[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: STBColors.primaryBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.picture_as_pdf,
                          color: STBColors.primaryBlue,
                        ),
                      ),
                      title: Text(
                        doc['titre'],
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            doc['description'],
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: STBColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: STBColors.bgLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              doc['categorie'].toString().toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: STBColors.primaryBlue,
                              ),
                            ),
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.open_in_new,
                          color: STBColors.primaryBlue,
                        ),
                        onPressed: () => _launchUrl(doc['url']),
                      ),
                      onTap: () => _launchUrl(doc['url']),
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: AuthService.currentUser?.role == 'rh'
          ? FloatingActionButton.extended(
              onPressed: _showAddDocumentDialog,
              icon: const Icon(Icons.add),
              label: const Text('Ajouter'),
              backgroundColor: STBColors.primaryBlue,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }
}
