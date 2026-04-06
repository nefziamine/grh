<?php
require_once __DIR__ . '/../config/db_connect.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendResponse(["success" => false, "message" => "Méthode non autorisée"], 405);
}

$authUser = getAuthUser($conn);
requireRole($authUser, ['admin', 'rh']);

$data = json_decode(file_get_contents("php://input"), true);

$required = ['user_id', 'date_retard', 'heure_arrivee', 'duree_minutes'];
foreach ($required as $field) {
    if (!isset($data[$field])) {
        sendResponse(["success" => false, "message" => "Champ requis: $field"], 400);
    }
}

$motif = $data['motif'] ?? '';

$stmt = $conn->prepare("INSERT INTO retards (user_id, date_retard, heure_arrivee, duree_minutes, motif) VALUES (?, ?, ?, ?, ?)");
$stmt->bind_param("issis", $data['user_id'], $data['date_retard'], $data['heure_arrivee'], $data['duree_minutes'], $motif);

if ($stmt->execute()) {
    $retardId = $conn->insert_id;
    $targetUserId = intval($data['user_id']);

    // Check count of retards for the user
    $countStmt = $conn->prepare("SELECT COUNT(*) FROM retards WHERE user_id = ?");
    $countStmt->bind_param("i", $targetUserId);
    $countStmt->execute();
    $count = $countStmt->get_result()->fetch_row()[0];

    // Every 5 retards = -12h (0.5 day) conge
    if ($count > 0 && $count % 5 == 0) {
        $updateSolde = $conn->prepare("UPDATE users SET solde_conge = solde_conge - 0.5 WHERE id = ?");
        $updateSolde->bind_param("i", $targetUserId);
        $updateSolde->execute();
        
        // Add a notification about the deduction
        $msgDeduction = "Sanction : 12 heures (0.5 jour) ont été déduites de votre solde pour cause de cumul de $count retards.";
        $notifDeductionStmt = $conn->prepare("INSERT INTO notifications (user_id, titre, message, type_notif) VALUES (?, 'Sanction de retard', ?, 'sanction')");
        $notifDeductionStmt->bind_param("is", $targetUserId, $msgDeduction);
        $notifDeductionStmt->execute();
    }

    $notifStmt = $conn->prepare("INSERT INTO notifications (user_id, titre, message, type_notif) VALUES (?, 'Retard enregistré', ?, 'retard')");
    $msg = "Un retard de " . $data['duree_minutes'] . " minutes a été enregistré pour le " . $data['date_retard'];
    $notifStmt->bind_param("is", $targetUserId, $msg);
    $notifStmt->execute();
    
    sendResponse(["success" => true, "message" => "Retard enregistré", "id" => $retardId], 201);
} else {
    sendResponse(["success" => false, "message" => "Erreur"], 500);
}
?>
