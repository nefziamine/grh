<?php
require_once __DIR__ . '/../config/db_connect.php';

$authUser = getAuthUser($conn);
$userId = intval($authUser['id']);

$data = json_decode(file_get_contents("php://input"), true);

if (!isset($data['id'])) {
    sendResponse(["success" => false, "message" => "ID du congé requis"], 400);
}

$congeId = intval($data['id']);

// Check if the congé belongs to the current user
$checkStmt = $conn->prepare("SELECT user_id, statut FROM conges WHERE id = ?");
$checkStmt->bind_param("i", $congeId);
$checkStmt->execute();
$result = $checkStmt->get_result();

if ($result->num_rows === 0) {
    sendResponse(["success" => false, "message" => "Congé non trouvé"], 404);
}

$conge = $result->fetch_assoc();

// Only allow users to delete their own congés
if ($conge['user_id'] != $userId) {
    sendResponse(["success" => false, "message" => "Accès non autorisé"], 403);
}

// Only allow deletion of pending congés
if ($conge['statut'] !== 'en_attente') {
    sendResponse(["success" => false, "message" => "Seules les demandes en attente peuvent être supprimées"], 400);
}

// Delete the congé
$deleteStmt = $conn->prepare("DELETE FROM conges WHERE id = ?");
$deleteStmt->bind_param("i", $congeId);

if ($deleteStmt->execute()) {
    sendResponse(["success" => true, "message" => "Demande de congé supprimée avec succès"]);
} else {
    sendResponse(["success" => false, "message" => "Erreur lors de la suppression"], 500);
}
?>
