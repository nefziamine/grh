<?php
require_once __DIR__ . '/../config/db_connect.php';
require_once __DIR__ . '/../config/attendance_helpers.php';

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
$targetUserId = intval($data['user_id']);

$stmt = $conn->prepare(
    "INSERT INTO retards (user_id, date_retard, heure_arrivee, duree_minutes, motif, is_confirmed) VALUES (?, ?, ?, ?, ?, 1)"
);
$stmt->bind_param("issis", $targetUserId, $data['date_retard'], $data['heure_arrivee'], $data['duree_minutes'], $motif);

if ($stmt->execute()) {
    $retardId = $conn->insert_id;

    applyRetardPenalty($conn, $targetUserId);

    $notifStmt = $conn->prepare(
        "INSERT INTO notifications (user_id, titre, message, type_notif) VALUES (?, 'Retard enregistré', ?, 'retard')"
    );
    $msg = "Un retard de " . $data['duree_minutes'] . " minutes a été enregistré pour le " . $data['date_retard'];
    $notifStmt->bind_param("is", $targetUserId, $msg);
    $notifStmt->execute();

    sendResponse(["success" => true, "message" => "Retard enregistré", "id" => $retardId], 201);
} else {
    sendResponse(["success" => false, "message" => "Erreur"], 500);
}
?>
