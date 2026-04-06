<?php
require_once __DIR__ . '/../config/db_connect.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendResponse(["success" => false, "message" => "Méthode non autorisée"], 405);
}

$authUser = getAuthUser($conn);
$data = json_decode(file_get_contents("php://input"), true);
$userId = intval($authUser['id']);

if (isset($data['id'])) {
    $stmt = $conn->prepare("UPDATE notifications SET is_read = 1 WHERE id = ? AND user_id = ?");
    $stmt->bind_param("ii", $data['id'], $userId);
    $stmt->execute();
} elseif (isset($data['all']) && $data['all'] === true) {
    $stmt = $conn->prepare("UPDATE notifications SET is_read = 1 WHERE user_id = ?");
    $stmt->bind_param("i", $userId);
    $stmt->execute();
}

sendResponse(["success" => true, "message" => "Notification(s) marquée(s) comme lue(s)"]);
?>
