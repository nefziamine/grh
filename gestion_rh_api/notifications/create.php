<?php
require_once __DIR__ . '/../config/db_connect.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendResponse(["success" => false, "message" => "Méthode non autorisée"], 405);
}

$authUser = getAuthUser($conn);
requireRole($authUser, ['admin', 'rh']);

$data = json_decode(file_get_contents("php://input"), true);

if (!isset($data['user_id']) || !isset($data['titre']) || !isset($data['message'])) {
    sendResponse(["success" => false, "message" => "user_id, titre et message requis"], 400);
}

$type = $data['type_notif'] ?? 'system';

// Support sending to all employees
if ($data['user_id'] === 'all') {
    $users = $conn->query("SELECT id FROM users WHERE role NOT IN ('admin', 'rh') AND is_active = 1");
    $count = 0;
    while ($u = $users->fetch_assoc()) {
        $stmt = $conn->prepare("INSERT INTO notifications (user_id, titre, message, type_notif) VALUES (?, ?, ?, ?)");
        $stmt->bind_param("isss", $u['id'], $data['titre'], $data['message'], $type);
        $stmt->execute();
        $count++;
    }
    sendResponse(["success" => true, "message" => "Notification envoyée à $count employés"], 201);
} else {
    $stmt = $conn->prepare("INSERT INTO notifications (user_id, titre, message, type_notif) VALUES (?, ?, ?, ?)");
    $stmt->bind_param("isss", $data['user_id'], $data['titre'], $data['message'], $type);
    
    if ($stmt->execute()) {
        sendResponse(["success" => true, "message" => "Notification envoyée", "id" => $conn->insert_id], 201);
    } else {
        sendResponse(["success" => false, "message" => "Erreur"], 500);
    }
}
?>
