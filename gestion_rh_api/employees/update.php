<?php
require_once __DIR__ . '/../config/db_connect.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendResponse(["success" => false, "message" => "Méthode non autorisée"], 405);
}

$authUser = getAuthUser($conn);
$data = json_decode(file_get_contents("php://input"), true);

if (!isset($data['id'])) {
    sendResponse(["success" => false, "message" => "ID employé requis"], 400);
}

$id = intval($data['id']);

if (!in_array($authUser['role'], ['admin', 'rh']) && $authUser['id'] != $id) {
    sendResponse(["success" => false, "message" => "Accès refusé"], 403);
}

// Build dynamic update
$fields = [];
$types = "";
$values = [];

$allowedFields = ['nom', 'prenom', 'email', 'telephone', 'departement', 'poste', 'date_embauche', 'adresse', 'solde_conge', 'is_active', 'role'];
if (!in_array($authUser['role'], ['admin', 'rh'])) {
    $allowedFields = ['email', 'telephone', 'adresse'];
}

foreach ($allowedFields as $field) {
    if (isset($data[$field])) {
        $fields[] = "$field = ?";
        if ($field === 'solde_conge' || $field === 'is_active') {
            $types .= "i";
        } else {
            $types .= "s";
        }
        $values[] = $data[$field];
    }
}

if (isset($data['password']) && !empty($data['password'])) {
    $fields[] = "password_hash = ?";
    $types .= "s";
    $values[] = password_hash($data['password'], PASSWORD_DEFAULT);
}

if (empty($fields)) {
    sendResponse(["success" => false, "message" => "Aucun champ à mettre à jour"], 400);
}

$types .= "i";
$values[] = $id;

$sql = "UPDATE users SET " . implode(", ", $fields) . " WHERE id = ?";
$stmt = $conn->prepare($sql);
$stmt->bind_param($types, ...$values);

if ($stmt->execute()) {
    sendResponse(["success" => true, "message" => "Employé mis à jour avec succès"]);
} else {
    sendResponse(["success" => false, "message" => "Erreur lors de la mise à jour"], 500);
}
?>
