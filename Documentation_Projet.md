# 🏢 Solution de Gestion des Ressources Humaines (STB HR)

## 📖 Présentation du Projet
Cette application est une solution complète, moderne et performante de Gestion des Ressources Humaines. Elle a été conçue pour digitaliser et simplifier la communication entre les employés, le service RH, et la direction générale.
Grâce à une interface utilisateur extrêmement soignée et fluide, ce projet se positionne comme un outil "Prêt au déploiement" pour n'importe quelle moyenne ou grande entreprise cherchant à centraliser ses données et à simplifier ses démarches administratives. 

---

## 🚀 Fonctionnalités Clés et Modules Intégrés

### 👥 1. Gestion des Utilisateurs & Profils (Sécurité Multi-Rôles)
Le système offre une gestion stricte des autorisations en se basant sur la véritable étiquette/fonction de chaque utilisateur :
- **Espace Administrateur** : Création, modification, archivage d'employés et supervision technique globale du système avec tableau indicateur.
- **Espace RH** : Un portail métier spécialisé permettant à l'équipe RH de traiter les requêtes, valider ou refuser les demandes avec commentaires.
- **Espace Employé (Multi-rôles)** : "Manager", "Analyste", "Développeur", "Comptable", etc. Tous les autres rôles atterrissent sur un puissant tableau de bord intelligent qui permet d'interagir nativement avec l'entreprise.

### 🏖️ 2. Gestion Intelligente des Congés
* **Cycle Automatisé** : Allocation automatique des jours de congés (+30j/an, plafonné à 60j). Le cycle s'entretient de manière indépendante.
* **Vérification Immersive** : Impossible pour un employé de demander plus de jours que le solde dont il dispose. Le calcul et la déduction se font sans intervention manuelle après approbation RH.

### 💰 3. Gestion des Crédits et Avances sur Salaires
* Simulation de montants, choix du motif, taux d'intérêt embarqué (7.5%) et durée en mois. L'employé soumet son dossier de crédit et suit son statut directement depuis le portail.

### 🕒 4. Module Absences & Retards
* Interface RH dédiée pour tracer avec rigueur l'assiduité du personnel : enregistrement des retards et absences injustifiées pour optimiser le suivi des performances.

### 🔔 5. Centre de Notifications Intelligentes en Temps Réel
* Pastilles d'Alertes : Indicateur rouge (badge) intelligent d'alerte qui disparaît à la lecture pour ne jamais rater un changement de statut.
* Typage coloré : Bleues, rouges ou jaunes selon si c'est un message, un refus de crédit ou une validation de demande de congé.

### 🤖 6. Assistant RH Virtuel (Chatbot IA)
* L'application intègre une expérience "Smart Bot". Les employés ont une fenêtre d'assistance en cas de question réglementaire liée à l'entreprise.

---

## 🛠️ Stack Technologique (Architecture Logicielle)

L'architecture sépare proprement les couches d'interfaçage et de traitement de données (Clean Architecture) permettant l'évolution de la solution de manière agile sans endettement technique.

### 🎨 Front-End Mobile (Interface Utilisateur)
- **Framework** : Flutter (Dart)
- **Compatibilité** : Android & iOS (Cross-platform)
- **State Management** : Local State + SharedPreferences Manager (Optimisation du Cache et des Jetons)
- **UI/UX** : Design System rigoureux (Bannière Dégradée, Cartes, Ombres, Transitions et Animations de vues). 

### ⚙️ Back-End & API REST
- **Langage / Environnement** : PHP Natif (Haute Performance, léger et déployable sur n'importe quel panel d'entreprise comme cPanel).
- **Architecture Backend** : Modèle orienté Micro-fichiers sécurisés avec Routeurs.
- **Base de Données** : MySQL (Relationnel structuré, requêtes SQL préparées anti-injections).
- **Communication** : API RESTful (Format JSON), protégée par authentification basée sur Tokens.

---

## 📂 Organisation du Code Source 

L'intégralité du code inactif, inutile ou des scripts de test (Debug, Importation en masse, Dump de schéma temporaire, etc.) a été purgé afin de fournir un livrable pur.

### L'application Flutter (Dossier : `gestion_rh/`)
- `lib/main.dart` : Point d'entrée de l'application et chargeur asynchrone sécurisé de cache.
- `lib/config/` : Contient notamment `api_config.dart` : la centrale regroupant l'ensemble de tous les points de terminaisons (endpoints) du serveur.
- `lib/models/` : Les modèles de données (Classes `User`, `Conge`, `Notification`, etc).
- `lib/screens/` : Écrans sectorisés par type d'utilisateurs (`admin/`, `employee/`, `rh/`).
- `lib/services/` : Moteur de l'application gérant les requêtes HTTP (ApiService) avec des fonctions anti-timeout et un mode Hors Ligne cache.

### L'API Back-End (Dossier : `gestion_rh_api/`)
- `config/` : Le bridge (pont) MySQL (`db_connect.php`) et validateur de Rôles.
- Les dossiers Modulaires (`auth/`, `conges/`, `credits/`, `dashboard/`, `employees/`, `notifications/`) contiennent toutes les requêtes de manipulation de données (CRUD), triées minutieusement.

---

## 🚀 Lancer le Projet (Instructions de Déploiement)

### 1. Démarrer le Serveur et la Base de Données
1. Lancez **XAMPP** (ou tout autre serveur web avec PHP/MySQL).
2. Démarrez les modules **Apache** et **MySQL**.
3. Accédez à `phpMyAdmin` et importez le fichier ou assurez-vous que la base de données `gestion_rh` existe.
4. Le mot de passe par défaut généré pour le hash des utilisateurs de tests doit correspondre au script que vous avez lié à l'API.

### 2. Connecter l'Application Flutter au réseau local
1. Ouvrez Flutter (VS Code ou Android Studio).
2. L'application possède un détecteur d'adresse IP intelligent (`ApiConfig` localise automatiquement l'hébergeur). Assurez-vous tout de même que votre Adresse IP locale concorde si vous lancez sur un téléphone physique en Wifi. (Modifiez `192.168.x.x` dans le fichier `lib/config/api_config.dart` à la ligne 10).
3. Exécutez la commande `flutter run` ou l'outil de lancement visuel.

---

*L'intégralité du produit a été stabilisée, nettoyée et documentée en vue d'une production commerciale.*
