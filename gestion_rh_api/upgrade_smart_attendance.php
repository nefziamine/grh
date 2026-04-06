<?php
require 'c:/xampp/htdocs/Gestion_RH/gestion_rh_api/config/db_connect.php';

$sql = "
-- Table des paramètres de l'agence
CREATE TABLE IF NOT EXISTS settings (
    id INT AUTO_INCREMENT PRIMARY KEY,
    key_name VARCHAR(50) UNIQUE NOT NULL,
    key_value VARCHAR(100) NOT NULL
);

INSERT IGNORE INTO settings (key_name, key_value) VALUES ('opening_time', '08:00:00');

-- Table des pointages (digital check-in)
CREATE TABLE IF NOT EXISTS pointages (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    date_pointage DATE NOT NULL,
    heure_pointage TIME NOT NULL,
    status ENUM('en_attente', 'valide', 'rejete') DEFAULT 'en_attente',
    type_action ENUM('presence', 'retard', 'absence') DEFAULT 'presence',
    valide_par INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (valide_par) REFERENCES users(id) ON DELETE SET NULL
);

-- Ajouter une colonne statut aux tables absences et retards existantes pour permettre la validation
ALTER TABLE absences ADD COLUMN IF NOT EXISTS is_confirmed TINYINT(1) DEFAULT 0;
ALTER TABLE retards ADD COLUMN IF NOT EXISTS is_confirmed TINYINT(1) DEFAULT 0;
";

if ($conn->multi_query($sql)) {
    echo "Smart Check-in tables created successfully.\n";
} else {
    echo "Error: " . $conn->error . "\n";
}
?>
