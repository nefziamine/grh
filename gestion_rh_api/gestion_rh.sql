-- ============================================
-- STB Gestion RH - Database Schema
-- Société Tunisienne de Banque
-- ============================================

CREATE DATABASE IF NOT EXISTS gestion_rh CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE gestion_rh;

-- ============================================
-- Users Table (Employees, RH, Admin)
-- ============================================
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    matricule VARCHAR(20) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role ENUM('admin', 'rh', 'employee') NOT NULL DEFAULT 'employee',
    nom VARCHAR(100) NOT NULL,
    prenom VARCHAR(100) NOT NULL,
    telephone VARCHAR(20),
    departement VARCHAR(100),
    poste VARCHAR(100),
    date_embauche DATE,
    adresse TEXT,
    solde_conge INT DEFAULT 30,
    avatar VARCHAR(255),
    is_active TINYINT(1) DEFAULT 1,
    token VARCHAR(255),
    token_expiry DATETIME,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ============================================
-- Congés (Leave Requests)
-- ============================================
CREATE TABLE IF NOT EXISTS conges (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    type_conge ENUM('annuel', 'maladie', 'maternite', 'sans_solde', 'exceptionnel') NOT NULL,
    date_debut DATE NOT NULL,
    date_fin DATE NOT NULL,
    nb_jours INT NOT NULL,
    motif TEXT,
    statut ENUM('en_attente', 'approuve', 'refuse') DEFAULT 'en_attente',
    commentaire_rh TEXT,
    approved_by INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (approved_by) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- ============================================
-- Absences
-- ============================================
CREATE TABLE IF NOT EXISTS absences (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    date_absence DATE NOT NULL,
    type_absence ENUM('justifiee', 'injustifiee') NOT NULL DEFAULT 'injustifiee',
    motif TEXT,
    justification VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================
-- Retards (Tardiness)
-- ============================================
CREATE TABLE IF NOT EXISTS retards (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    date_retard DATE NOT NULL,
    heure_arrivee TIME NOT NULL,
    duree_minutes INT NOT NULL,
    motif TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================
-- Crédits (Employee Loans)
-- ============================================
CREATE TABLE IF NOT EXISTS credits (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    type_credit VARCHAR(100) NOT NULL,
    montant DECIMAL(12,2) NOT NULL,
    duree_mois INT NOT NULL,
    taux_interet DECIMAL(5,2),
    mensualite DECIMAL(12,2),
    statut ENUM('en_attente', 'approuve', 'refuse', 'en_cours', 'termine') DEFAULT 'en_attente',
    motif TEXT,
    commentaire_rh TEXT,
    approved_by INT,
    date_demande TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    date_debut DATE,
    date_fin DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (approved_by) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB;

-- ============================================
-- Notifications
-- ============================================
CREATE TABLE IF NOT EXISTS notifications (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    titre VARCHAR(200) NOT NULL,
    message TEXT NOT NULL,
    type_notif ENUM('conge', 'absence', 'retard', 'credit', 'system', 'message') DEFAULT 'system',
    is_read TINYINT(1) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================
-- Messages (Internal Messaging)
-- ============================================
CREATE TABLE IF NOT EXISTS messages (
    id INT AUTO_INCREMENT PRIMARY KEY,
    sender_id INT NOT NULL,
    receiver_id INT NOT NULL,
    contenu TEXT NOT NULL,
    is_read TINYINT(1) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (sender_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (receiver_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ============================================
-- Documents officiels
-- ============================================
CREATE TABLE IF NOT EXISTS documents (
    id INT AUTO_INCREMENT PRIMARY KEY,
    titre VARCHAR(255) NOT NULL,
    description TEXT,
    url VARCHAR(255) NOT NULL,
    categorie VARCHAR(100) NOT NULL DEFAULT 'RH',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ============================================
-- Seed Data - Default Admin & Sample Users
-- ============================================
INSERT INTO users (matricule, email, password_hash, role, nom, prenom, telephone, departement, poste, date_embauche, solde_conge) VALUES
('ADM001', 'admin@stb.com.tn', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'admin', 'Admin', 'STB', '71000001', 'Direction Générale', 'Administrateur Système', '2020-01-01', 30),
('RH001', 'rh@stb.com.tn', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'rh', 'Ben Ali', 'Sarra', '71000002', 'Ressources Humaines', 'Responsable RH', '2019-06-15', 30),
('EMP001', 'emp1@stb.com.tn', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'employee', 'Trabelsi', 'Mohamed', '71000003', 'Informatique', 'Développeur', '2021-03-10', 25),
('EMP002', 'emp2@stb.com.tn', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'employee', 'Gharbi', 'Fatma', '71000004', 'Finance', 'Analyste Financier', '2022-01-20', 28),
('EMP003', 'emp3@stb.com.tn', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'employee', 'Mansouri', 'Ahmed', '71000005', 'Marketing', 'Chef de Projet', '2020-09-01', 22),
('EMP004', 'marwen.saidi944@stb.com.tn', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'employee', 'Saidi', 'Marwen', '71000006', 'Support IT', 'Technicien Support', '2023-06-15', 18);

-- Default password for all seed users: 'password'

-- Sample leave requests
INSERT INTO conges (user_id, type_conge, date_debut, date_fin, nb_jours, motif, statut) VALUES
(3, 'annuel', '2026-04-01', '2026-04-05', 5, 'Vacances familiales', 'en_attente'),
(4, 'maladie', '2026-03-20', '2026-03-22', 3, 'Consultation médicale', 'approuve'),
(5, 'exceptionnel', '2026-04-10', '2026-04-11', 2, 'Mariage', 'en_attente'),
(6, 'annuel', '2026-02-12', '2026-02-16', 5, 'Congé de formation IT', 'approuve');

-- Sample absences
INSERT INTO absences (user_id, date_absence, type_absence, motif) VALUES
(3, '2026-03-15', 'injustifiee', NULL),
(4, '2026-03-18', 'justifiee', 'Rendez-vous médical'),
(5, '2026-03-10', 'injustifiee', NULL),
(6, '2026-02-05', 'injustifiee', 'Retard transport'),
(6, '2026-03-12', 'justifiee', 'Contrôle de santé'),
(6, '2026-04-20', 'injustifiee', NULL),
(6, '2026-05-08', 'injustifiee', 'Absence justifiée par dossier en cours');

-- Sample tardiness
INSERT INTO retards (user_id, date_retard, heure_arrivee, duree_minutes, motif) VALUES
(3, '2026-03-20', '09:15:00', 15, 'Embouteillage'),
(4, '2026-03-21', '09:30:00', 30, 'Problème de transport'),
(5, '2026-03-22', '09:10:00', 10, NULL),
(6, '2026-02-15', '08:55:00', 10, 'Problème de métro'),
(6, '2026-03-18', '09:05:00', 18, 'Retard imprévu'),
(6, '2026-04-02', '09:08:00', 8, NULL),
(6, '2026-05-09', '09:12:00', 12, 'Arrivée tardive déclarée');

-- Sample credits
INSERT INTO credits (user_id, type_credit, montant, duree_mois, taux_interet, statut, motif) VALUES
(3, 'Personnel', 15000.00, 24, 7.50, 'en_attente', 'Achat véhicule'),
(4, 'Immobilier', 120000.00, 240, 5.25, 'en_cours', 'Acquisition appartement'),
(5, 'Personnel', 8000.00, 12, 8.00, 'approuve', 'Aménagement'),
(6, 'Personnel', 6500.00, 18, 6.75, 'en_attente', 'Réparation matériel informatique');

-- Sample notifications
INSERT INTO notifications (user_id, titre, message, type_notif) VALUES
(3, 'Demande de congé soumise', 'Votre demande de congé du 01/04 au 05/04 a été soumise avec succès.', 'conge'),
(4, 'Congé approuvé', 'Votre congé maladie du 20/03 au 22/03 a été approuvé.', 'conge'),
(5, 'Bienvenue', 'Bienvenue sur la plateforme Gestion RH de la STB.', 'system'),
(6, 'Statistiques Marwen', 'Les données de Marwen Saidi ont été initialisées pour la démonstration du tableau de bord.', 'system');

-- Sample official documents
INSERT INTO documents (titre, description, url, categorie) VALUES
('STB Indicators as of 31/12/2024', 'Rapport officiel des indicateurs financiers de STB au 31 décembre 2024.', 'https://www.stb.com.tn/en/the-bank/stb-indicators-as-of-31-12-2024/', 'BANQUE'),
('Moody’s upgrades STB’s rating: A sign of confidence and financial stability', 'Communiqué officiel de STB sur l’amélioration de la note de Moody’s.', 'https://www.stb.com.tn/en/press/moodys-upgrades-stbs-rating-a-sign-of-confidence-and-financial-stability/', 'BANQUE'),
('Regulatory notices and compliance updates', 'Documents officiels STB sur les réglementations bancaires et communiqués importants.', 'https://www.stb.com.tn/en/important-links/', 'BANQUE'),
('STB Annual Report 2023', 'Rapport annuel 2023 publié par la banque STB.', 'https://www.stb.com.tn/en/press/annual-report-2023/', 'BANQUE'),
('STB Corporate Governance', 'Document de gouvernance d’entreprise officiel de STB.', 'https://www.stb.com.tn/en/the-bank/corporate-governance/', 'BANQUE');
