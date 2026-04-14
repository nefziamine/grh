<?php
$_SERVER['REQUEST_METHOD'] = 'CLI'; 
require_once __DIR__ . '/../config/db_connect.php';

// Cette requête ajoute automatiquement 30 jours (720 heures) à tous les employés
// et limite le total à 60 jours (1440 heures) grâce à la fonction MySQL LEAST()
$query = "UPDATE users SET solde_conge = LEAST(solde_conge + 720, 1440) WHERE is_active = 1";

if ($conn->query($query) === TRUE) {
    // Send notification to all active employees
    $users = $conn->query("SELECT id FROM users WHERE is_active = 1");
    $titre = "Renouvellement du solde de congé";
    $msg = "Votre solde de congé annuel a été renouvelé (+30 jours).";
    
    while ($u = $users->fetch_assoc()) {
        $notif = $conn->prepare("INSERT INTO notifications (user_id, titre, message, type_notif) VALUES (?, ?, ?, 'conge')");
        $notif->bind_param("iss", $u['id'], $titre, $msg);
        $notif->execute();
    }
    
    echo json_encode(["success" => true, "message" => "Attribution réussie : +30 jours ajoutés (Plafond à 60 jours respecté)."]);
} else {
    echo json_encode(["success" => false, "message" => "Erreur : " . $conn->error]);
}
?>
