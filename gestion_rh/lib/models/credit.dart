class Credit {
  final int id;
  final int userId;
  final String typeCredit;
  final double montant;
  final int dureeMois;
  final double? tauxInteret;
  final double? mensualite;
  final String statut;
  final String? motif;
  final String? commentaireRh;
  final String? dateDebut;
  final String? dateFin;
  final String? nom;
  final String? prenom;
  final String? matricule;
  final String? departement;
  final String? createdAt;

  Credit({
    required this.id,
    required this.userId,
    required this.typeCredit,
    required this.montant,
    required this.dureeMois,
    this.tauxInteret,
    this.mensualite,
    required this.statut,
    this.motif,
    this.commentaireRh,
    this.dateDebut,
    this.dateFin,
    this.nom,
    this.prenom,
    this.matricule,
    this.departement,
    this.createdAt,
  });

  String get statutLabel {
    switch (statut) {
      case 'en_attente': return 'En attente';
      case 'approuve': return 'Approuvé';
      case 'refuse': return 'Refusé';
      case 'en_cours': return 'En cours';
      case 'termine': return 'Terminé';
      default: return statut;
    }
  }

  String get employeeName => '${prenom ?? ''} ${nom ?? ''}';

  factory Credit.fromJson(Map<String, dynamic> json) {
    return Credit(
      id: int.tryParse(json['id'].toString()) ?? 0,
      userId: int.tryParse(json['user_id'].toString()) ?? 0,
      typeCredit: json['type_credit'] ?? '',
      montant: double.tryParse(json['montant'].toString()) ?? 0,
      dureeMois: int.tryParse(json['duree_mois'].toString()) ?? 0,
      tauxInteret: double.tryParse(json['taux_interet']?.toString() ?? '0'),
      mensualite: double.tryParse(json['mensualite']?.toString() ?? '0'),
      statut: json['statut'] ?? 'en_attente',
      motif: json['motif'],
      commentaireRh: json['commentaire_rh'],
      dateDebut: json['date_debut'],
      dateFin: json['date_fin'],
      nom: json['nom'],
      prenom: json['prenom'],
      matricule: json['matricule'],
      departement: json['departement'],
      createdAt: json['created_at'],
    );
  }
}
