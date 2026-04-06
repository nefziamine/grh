class User {
  final int id;
  final String matricule;
  final String email;
  final String role;
  final String nom;
  final String prenom;
  final String? telephone;
  final String? departement;
  final String? poste;
  final String? dateEmbauche;
  final String? adresse;
  final int soldeConge;
  final String? avatar;
  final bool isActive;
  final String? token;

  User({
    required this.id,
    required this.matricule,
    required this.email,
    required this.role,
    required this.nom,
    required this.prenom,
    this.telephone,
    this.departement,
    this.poste,
    this.dateEmbauche,
    this.adresse,
    this.soldeConge = 30,
    this.avatar,
    this.isActive = true,
    this.token,
  });

  String get fullName => '$prenom $nom';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: int.tryParse(json['id'].toString()) ?? 0,
      matricule: json['matricule'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'employee',
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      telephone: json['telephone'],
      departement: json['departement'],
      poste: json['poste'],
      dateEmbauche: json['date_embauche'],
      adresse: json['adresse'],
      soldeConge: int.tryParse(json['solde_conge']?.toString() ?? '30') ?? 30,
      avatar: json['avatar'],
      isActive: json['is_active'] == '1' || json['is_active'] == 1 || json['is_active'] == true,
      token: json['token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'matricule': matricule,
      'email': email,
      'role': role,
      'nom': nom,
      'prenom': prenom,
      'telephone': telephone,
      'departement': departement,
      'poste': poste,
      'date_embauche': dateEmbauche,
      'adresse': adresse,
      'solde_conge': soldeConge,
    };
  }
}
