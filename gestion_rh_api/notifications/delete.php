<?php
require_once __DIR__ . '/../config/db_connect.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendResponse(["success" => false, "message" => "Méthode non autorisée"], 405);
}

$authUser = getAuthUser($conn);
$userId = intval($authUser['id']);

$data = json_decode(file_get_contents("php://input"), true);

if (isset($data['id'])) {
    $id = intval($data['id']);
    $stmt = $conn->prepare("DELETE FROM notifications WHERE id = ? AND user_id = ?");
    $stmt->bind_param("ii", $id, $userId);
} else if (isset($data['all']) && $data['all'] === true) {
    $stmt = $conn->prepare("DELETE FROM notifications WHERE user_id = ?");
    $stmt->bind_param("i", $userId);
} else {
    sendResponse(["success" => false, "message" => "ID manquant"], 400);
}

if ($stmt->execute()) {
    sendResponse(["success" => true, "message" => "Notification supprimée"]);
} else {
    sendResponse(["success" => false, "message" => "Erreur lors de la suppression"], 500);
}
?>
