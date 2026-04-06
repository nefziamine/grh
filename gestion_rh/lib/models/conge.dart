class Conge {
  final int id;
  final int userId;
  final String typeConge;
  final String dateDebut;
  final String dateFin;
  final int nbJours;
  final String? motif;
  final String statut;
  final String? commentaireRh;
  final String? approvedByName;
  final String? nom;
  final String? prenom;
  final String? matricule;
  final String? departement;
  final String? createdAt;

  Conge({
    required this.id,
    required this.userId,
    required this.typeConge,
    required this.dateDebut,
    required this.dateFin,
    required this.nbJours,
    this.motif,
    required this.statut,
    this.commentaireRh,
    this.approvedByName,
    this.nom,
    this.prenom,
    this.matricule,
    this.departement,
    this.createdAt,
  });

  String get employeeName => '${prenom ?? ''} ${nom ?? ''}';

  String get typeLabel {
    switch (typeConge) {
      case 'annuel': return 'Annuel';
      case 'maladie': return 'Maladie';
      case 'maternite': return 'Maternité';
      case 'sans_solde': return 'Sans Solde';
      case 'exceptionnel': return 'Exceptionnel';
      default: return typeConge;
    }
  }

  String get statutLabel {
    switch (statut) {
      case 'en_attente': return 'En attente';
      case 'approuve': return 'Approuvé';
      case 'refuse': return 'Refusé';
      default: return statut;
    }
  }

  factory Conge.fromJson(Map<String, dynamic> json) {
    return Conge(
      id: int.tryParse(json['id'].toString()) ?? 0,
      userId: int.tryParse(json['user_id'].toString()) ?? 0,
      typeConge: json['type_conge'] ?? '',
      dateDebut: json['date_debut'] ?? '',
      dateFin: json['date_fin'] ?? '',
      nbJours: int.tryParse(json['nb_jours'].toString()) ?? 0,
      motif: json['motif'],
      statut: json['statut'] ?? 'en_attente',
      commentaireRh: json['commentaire_rh'],
      approvedByName: json['approved_by_name'],
      nom: json['nom'],
      prenom: json['prenom'],
      matricule: json['matricule'],
      departement: json['departement'],
      createdAt: json['created_at'],
    );
  }
}
