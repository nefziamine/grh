<?php
require_once __DIR__ . '/../config/db_connect.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendResponse(["success" => false, "message" => "Méthode non autorisée"], 405);
}

$authUser = getAuthUser($conn);
requireRole($authUser, ['admin']);

$data = json_decode(file_get_contents("php://input"), true);

if (!isset($data['id'])) {
    sendResponse(["success" => false, "message" => "ID employé requis"], 400);
}

$id = intval($data['id']);

// Prevent deleting yourself
if ($id === intval($authUser['id'])) {
    sendResponse(["success" => false, "message" => "Vous ne pouvez pas supprimer votre propre compte"], 400);
}

$stmt = $conn->prepare("DELETE FROM users WHERE id = ?");
$stmt->bind_param("i", $id);

if ($stmt->execute()) {
    if ($stmt->affected_rows > 0) {
        sendResponse(["success" => true, "message" => "Employé supprimé avec succès"]);
    } else {
        sendResponse(["success" => false, "message" => "Employé non trouvé"], 404);
    }
} else {
    sendResponse(["success" => false, "message" => "Erreur lors de la suppression"], 500);
}
?>
