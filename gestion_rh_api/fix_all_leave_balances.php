<?php
require_once 'config/db_connect.php';

// Recalculate all user balances based on approved leave
$sql = "SELECT u.id, u.nom, u.prenom,
        COALESCE(SUM(CASE WHEN c.statut = 'approuve' AND c.type_conge != 'sans_solde' THEN c.nb_jours ELSE 0 END), 0) as total_approved_days
        FROM users u
        LEFT JOIN conges c ON u.id = c.user_id
        WHERE u.is_active = 1
        GROUP BY u.id, u.nom, u.prenom";

$result = $conn->query($sql);
$updatedCount = 0;
$errors = [];

echo "Fixing leave balances for all users...\n";
echo "=========================================\n\n";

while($row = $result->fetch_assoc()) {
    $userId = $row['id'];
    $approvedDays = intval($row['total_approved_days']);
    $correctSolde = 30 - $approvedDays;
    
    // Update the user's solde_conge
    $updateStmt = $conn->prepare("UPDATE users SET solde_conge = ? WHERE id = ?");
    $updateStmt->bind_param("ii", $correctSolde, $userId);
    
    if ($updateStmt->execute()) {
        echo "✓ " . $row['prenom'] . " " . $row['nom'] . " - Balance updated to: " . $correctSolde . " (Approved: " . $approvedDays . " days)\n";
        $updatedCount++;
    } else {
        $errors[] = "✗ " . $row['prenom'] . " " . $row['nom'] . " - Update failed";
        echo "✗ " . $row['prenom'] . " " . $row['nom'] . " - Update failed\n";
    }
}

echo "\n=========================================\n";
echo "Fix completed!\n";
echo "Total users updated: " . $updatedCount . "\n";

if (!empty($errors)) {
    echo "Errors encountered: " . count($errors) . "\n";
    foreach ($errors as $error) {
        echo $error . "\n";
    }
}

// Verify the fix
echo "\n\nVerifying the fix...\n";
echo "=========================================\n";

$verifySql = "SELECT u.id, u.nom, u.prenom, u.solde_conge,
        SUM(CASE WHEN c.statut = 'approuve' AND c.type_conge != 'sans_solde' THEN c.nb_jours ELSE 0 END) as total_approved_days
        FROM users u
        LEFT JOIN conges c ON u.id = c.user_id
        GROUP BY u.id, u.nom, u.prenom, u.solde_conge
        HAVING total_approved_days > 0
        ORDER BY total_approved_days DESC";

$verifyResult = $conn->query($verifySql);
$issuesFound = 0;

while($row = $verifyResult->fetch_assoc()) {
    $approved = intval($row['total_approved_days'] ?? 0);
    if ($approved > 0) {
        $expectedSolde = 30 - $approved;
        if ($row['solde_conge'] == $expectedSolde) {
            echo "✓ " . $row['prenom'] . " " . $row['nom'] . " - Balance OK (Current: " . $row['solde_conge'] . ", Approved: " . $approved . ")\n";
        } else {
            echo "✗ " . $row['prenom'] . " " . $row['nom'] . " - STILL WRONG! (Current: " . $row['solde_conge'] . ", Expected: " . $expectedSolde . ", Approved: " . $approved . ")\n";
            $issuesFound++;
        }
    }
}

echo "\n=========================================\n";
if ($issuesFound === 0) {
    echo "✓ All balances are now correct!\n";
} else {
    echo "✗ " . $issuesFound . " users still have incorrect balances!\n";
}
?>
