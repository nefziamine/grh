class Absence {
  final int id;
  final int userId;
  final String dateAbsence;
  final String typeAbsence;
  final String? motif;
  final String? justification;
  final String? nom;
  final String? prenom;
  final String? matricule;
  final String? departement;
  final String? createdAt;

  Absence({
    required this.id,
    required this.userId,
    required this.dateAbsence,
    required this.typeAbsence,
    this.motif,
    this.justification,
    this.nom,
    this.prenom,
    this.matricule,
    this.departement,
    this.createdAt,
  });

  String get typeLabel => typeAbsence == 'justifiee' ? 'Justifiée' : 'Injustifiée';
  String get employeeName => '${prenom ?? ''} ${nom ?? ''}';

  factory Absence.fromJson(Map<String, dynamic> json) {
    return Absence(
      id: int.tryParse(json['id'].toString()) ?? 0,
      userId: int.tryParse(json['user_id'].toString()) ?? 0,
      dateAbsence: json['date_absence'] ?? '',
      typeAbsence: json['type_absence'] ?? 'injustifiee',
      motif: json['motif'],
      justification: json['justification'],
      nom: json['nom'],
      prenom: json['prenom'],
      matricule: json['matricule'],
      departement: json['departement'],
      createdAt: json['created_at'],
    );
  }
}

class Retard {
  final int id;
  final int userId;
  final String dateRetard;
  final String heureArrivee;
  final int dureeMinutes;
  final String? motif;
  final String? nom;
  final String? prenom;
  final String? matricule;
  final String? departement;

  Retard({
    required this.id,
    required this.userId,
    required this.dateRetard,
    required this.heureArrivee,
    required this.dureeMinutes,
    this.motif,
    this.nom,
    this.prenom,
    this.matricule,
    this.departement,
  });

  String get employeeName => '${prenom ?? ''} ${nom ?? ''}';

  factory Retard.fromJson(Map<String, dynamic> json) {
    return Retard(
      id: int.tryParse(json['id'].toString()) ?? 0,
      userId: int.tryParse(json['user_id'].toString()) ?? 0,
      dateRetard: json['date_retard'] ?? '',
      heureArrivee: json['heure_arrivee'] ?? '',
      dureeMinutes: int.tryParse(json['duree_minutes'].toString()) ?? 0,
      motif: json['motif'],
      nom: json['nom'],
      prenom: json['prenom'],
      matricule: json['matricule'],
      departement: json['departement'],
    );
  }
}
