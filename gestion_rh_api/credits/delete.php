<?php
require_once __DIR__ . '/../config/db_connect.php';

$authUser = getAuthUser($conn);
$userId = intval($authUser['id']);

$data = json_decode(file_get_contents("php://input"), true);

if (!isset($data['id'])) {
    sendResponse(["success" => false, "message" => "ID du crédit requis"], 400);
}

$creditId = intval($data['id']);

// Check if the credit belongs to the current user
$checkStmt = $conn->prepare("SELECT user_id, statut FROM credits WHERE id = ?");
$checkStmt->bind_param("i", $creditId);
$checkStmt->execute();
$result = $checkStmt->get_result();

if ($result->num_rows === 0) {
    sendResponse(["success" => false, "message" => "Crédit non trouvé"], 404);
}

$credit = $result->fetch_assoc();

// Only allow users to delete their own credits
if ($credit['user_id'] != $userId) {
    sendResponse(["success" => false, "message" => "Accès non autorisé"], 403);
}

// Only allow deletion of pending credits
if ($credit['statut'] !== 'en_attente') {
    sendResponse(["success" => false, "message" => "Seules les demandes en attente peuvent être supprimées"], 400);
}

// Delete the credit
$deleteStmt = $conn->prepare("DELETE FROM credits WHERE id = ?");
$deleteStmt->bind_param("i", $creditId);

if ($deleteStmt->execute()) {
    sendResponse(["success" => true, "message" => "Demande de crédit supprimée avec succès"]);
} else {
    sendResponse(["success" => false, "message" => "Erreur lors de la suppression"], 500);
}
?>
