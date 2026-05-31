<?php
require_once 'config/db_connect.php';

// Get all users with their leave data
$sql = "SELECT u.id, u.nom, u.prenom, u.solde_conge,
        SUM(CASE WHEN c.statut = 'approuve' AND c.type_conge != 'sans_solde' THEN c.nb_jours ELSE 0 END) as total_approved_days
        FROM users u
        LEFT JOIN conges c ON u.id = c.user_id
        GROUP BY u.id, u.nom, u.prenom, u.solde_conge
        ORDER BY total_approved_days DESC";

$result = $conn->query($sql);
echo "Users with approved leave days:\n";
echo "=========================================\n";
while($row = $result->fetch_assoc()) {
    $approved = intval($row['total_approved_days'] ?? 0);
    if ($approved > 0) {
        $expectedSolde = 30 - $approved;
        $match = ($row['solde_conge'] == $expectedSolde) ? "✓ OK" : "✗ BUG";
        echo "ID: " . $row['id'] . " | " . $row['prenom'] . " " . $row['nom'] . 
             " | Current: " . $row['solde_conge'] . " | Expected: " . $expectedSolde . 
             " | Approved Days: " . $approved . " | " . $match . "\n";
    }
}
?>
