<?php
require_once 'config/db_connect.php';

// Find Saidi or Nader
$sql = "SELECT id, matricule, nom, prenom, solde_conge FROM users WHERE prenom LIKE '%Saidi%' OR nom LIKE '%Saidi%' OR prenom LIKE '%Nader%' OR nom LIKE '%Nader%' LIMIT 1";
$result = $conn->query($sql);
$user = $result->fetch_assoc();

if ($user) {
    echo "User ID: " . $user['id'] . "\n";
    echo "Name: " . $user['prenom'] . " " . $user['nom'] . "\n";
    echo "Current solde_conge: " . $user['solde_conge'] . "\n";
    echo "\n";
    
    // Get leave requests
    $congesSql = "SELECT id, type_conge, date_debut, date_fin, nb_jours, statut FROM conges WHERE user_id = ? ORDER BY created_at DESC";
    $stmt = $conn->prepare($congesSql);
    $stmt->bind_param('i', $user['id']);
    $stmt->execute();
    $congesResult = $stmt->get_result();
    
    echo "Leave requests:\n";
    $totalApprovedDays = 0;
    while ($c = $congesResult->fetch_assoc()) {
        echo "  - " . $c['date_debut'] . " to " . $c['date_fin'] . ": " . $c['nb_jours'] . " days (" . $c['type_conge'] . ") - Status: " . $c['statut'] . "\n";
        if ($c['statut'] === 'approuve' && $c['type_conge'] !== 'sans_solde') {
            $totalApprovedDays += $c['nb_jours'];
        }
    }
    echo "\nTotal approved days (sans_solde): " . $totalApprovedDays . "\n";
    echo "Expected solde should be: 30 - " . $totalApprovedDays . " = " . (30 - $totalApprovedDays) . "\n";
} else {
    echo "User Saidi Nader not found\n";
}
?>
