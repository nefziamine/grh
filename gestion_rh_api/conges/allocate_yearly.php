<?php
$_SERVER['REQUEST_METHOD'] = 'CLI'; 
require_once __DIR__ . '/../config/db_connect.php';

// Cette requête ajoute automatiquement 30 jours à tous les employés
// et limite le total à 60 jours grâce à la fonction MySQL LEAST()
$query = "UPDATE users SET solde_conge = LEAST(solde_conge + 30, 60) WHERE is_active = 1";

if ($conn->query($query) === TRUE) {
    echo json_encode(["success" => true, "message" => "Attribution réussie : +30 jours ajoutés (Plafond à 60 jours respecté)."]);
} else {
    echo json_encode(["success" => false, "message" => "Erreur : " . $conn->error]);
}
?>
