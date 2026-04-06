<?php
require_once __DIR__ . '/../config/db_connect.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendResponse(["success" => false, "message" => "Méthode non autorisée"], 405);
}

$authUser = getAuthUser($conn);
requireRole($authUser, ['admin', 'rh']);

$data = json_decode(file_get_contents("php://input"), true);

if (!isset($data['user_id']) || !isset($data['date_absence'])) {
    sendResponse(["success" => false, "message" => "user_id et date_absence requis"], 400);
}

$type = $data['type_absence'] ?? 'injustifiee';
$motif = $data['motif'] ?? '';
$justification = $data['justification'] ?? '';

$stmt = $conn->prepare("INSERT INTO absences (user_id, date_absence, type_absence, motif, justification) VALUES (?, ?, ?, ?, ?)");
$stmt->bind_param("issss", $data['user_id'], $data['date_absence'], $type, $motif, $justification);

if ($stmt->execute()) {
    // Notify employee
    $notifStmt = $conn->prepare("INSERT INTO notifications (user_id, titre, message, type_notif) VALUES (?, 'Absence enregistrée', ?, 'absence')");
    $msg = "Une absence a été enregistrée pour le " . $data['date_absence'] . " (" . $type . ")";
    $notifStmt->bind_param("is", $data['user_id'], $msg);
    $notifStmt->execute();
    
    sendResponse(["success" => true, "message" => "Absence enregistrée", "id" => $conn->insert_id], 201);
} else {
    sendResponse(["success" => false, "message" => "Erreur"], 500);
}
?>
