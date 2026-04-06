<?php
require_once __DIR__ . '/../config/db_connect.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendResponse(["success" => false, "message" => "Méthode non autorisée"], 405);
}

$authUser = getAuthUser($conn);
requireRole($authUser, ['admin', 'rh']);

$data = json_decode(file_get_contents("php://input"), true);

if (!isset($data['id']) || !isset($data['statut'])) {
    sendResponse(["success" => false, "message" => "ID et statut requis"], 400);
}

$validStatuts = ['approuve', 'refuse', 'en_cours', 'termine'];
if (!in_array($data['statut'], $validStatuts)) {
    sendResponse(["success" => false, "message" => "Statut invalide"], 400);
}

$id = intval($data['id']);
$commentaire = $data['commentaire_rh'] ?? '';

$stmt = $conn->prepare("SELECT c.*, u.nom, u.prenom FROM credits c JOIN users u ON c.user_id = u.id WHERE c.id = ?");
$stmt->bind_param("i", $id);
$stmt->execute();
$credit = $stmt->get_result()->fetch_assoc();

if (!$credit) {
    sendResponse(["success" => false, "message" => "Crédit non trouvé"], 404);
}

$updateFields = "statut = ?, commentaire_rh = ?, approved_by = ?";
$params = [$data['statut'], $commentaire, $authUser['id']];
$types = "ssi";

if ($data['statut'] === 'approuve' || $data['statut'] === 'en_cours') {
    $dateDebut = date('Y-m-d');
    $dateFin = date('Y-m-d', strtotime('+' . $credit['duree_mois'] . ' months'));
    $updateFields .= ", date_debut = ?, date_fin = ?";
    $params[] = $dateDebut;
    $params[] = $dateFin;
    $types .= "ss";
}

$params[] = $id;
$types .= "i";

$stmt = $conn->prepare("UPDATE credits SET $updateFields WHERE id = ?");
$stmt->bind_param($types, ...$params);
$stmt->execute();

// Notify employee
$statusText = $data['statut'] === 'approuve' ? 'approuvé' : ($data['statut'] === 'refuse' ? 'refusé' : $data['statut']);
$titre = "Crédit $statusText";
$message = "Votre demande de crédit " . $credit['type_credit'] . " de " . number_format($credit['montant'], 2) . " TND a été $statusText.";

$n = $conn->prepare("INSERT INTO notifications (user_id, titre, message, type_notif) VALUES (?, ?, ?, 'credit')");
$n->bind_param("iss", $credit['user_id'], $titre, $message);
$n->execute();

sendResponse(["success" => true, "message" => "Statut du crédit mis à jour"]);
?>
