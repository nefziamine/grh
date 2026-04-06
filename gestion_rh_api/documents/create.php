<?php
require_once __DIR__ . '/../config/db_connect.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendResponse(["success" => false, "message" => "Méthode non autorisée"], 405);
}

$authUser = getAuthUser($conn);
requireRole($authUser, ['admin', 'rh']);

$data = json_decode(file_get_contents("php://input"), true);

$required = ['titre', 'description', 'url', 'categorie'];
foreach ($required as $field) {
    if (!isset($data[$field]) || empty(trim($data[$field]))) {
        sendResponse(["success" => false, "message" => "Champ requis: $field"], 400);
    }
}

$titre = $conn->real_escape_string($data['titre']);
$description = $conn->real_escape_string($data['description']);
$url = $conn->real_escape_string($data['url']);
$categorie = $conn->real_escape_string($data['categorie']);

$sql = "INSERT INTO documents (titre, description, url, categorie) VALUES ('$titre', '$description', '$url', '$categorie')";

if ($conn->query($sql)) {
    sendResponse(["success" => true, "message" => "Document ajouté avec succès"], 201);
} else {
    sendResponse(["success" => false, "message" => "Erreur lors de l'ajout: " . $conn->error], 500);
}
?>
