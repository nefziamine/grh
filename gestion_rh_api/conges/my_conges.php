<?php
require_once __DIR__ . '/../config/db_connect.php';

$authUser = getAuthUser($conn);
$userId = intval($authUser['id']);

$sql = "SELECT c.*, CONCAT(a.nom, ' ', a.prenom) as approved_by_name
        FROM conges c
        LEFT JOIN users a ON c.approved_by = a.id
        WHERE c.user_id = ?
        ORDER BY c.created_at DESC";

$stmt = $conn->prepare($sql);
$stmt->bind_param("i", $userId);
$stmt->execute();
$result = $stmt->get_result();

$conges = [];
while ($row = $result->fetch_assoc()) {
    $conges[] = $row;
}

// Get leave balance
$soldeStmt = $conn->prepare("SELECT solde_conge FROM users WHERE id = ?");
$soldeStmt->bind_param("i", $userId);
$soldeStmt->execute();
$solde = $soldeStmt->get_result()->fetch_assoc()['solde_conge'];

sendResponse([
    "success" => true,
    "data" => $conges,
    "solde_conge" => intval($solde)
]);
?>
