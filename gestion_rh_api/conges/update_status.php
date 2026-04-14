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

$validStatuts = ['approuve', 'refuse'];
if (!in_array($data['statut'], $validStatuts)) {
    sendResponse(["success" => false, "message" => "Statut invalide"], 400);
}

$id = intval($data['id']);
$commentaire = $data['commentaire_rh'] ?? '';

// Get the leave request
$stmt = $conn->prepare("SELECT c.*, u.nom, u.prenom, u.solde_conge FROM conges c JOIN users u ON c.user_id = u.id WHERE c.id = ?");
$stmt->bind_param("i", $id);
$stmt->execute();
$conge = $stmt->get_result()->fetch_assoc();

if (!$conge) {
    sendResponse(["success" => false, "message" => "Demande non trouvée"], 404);
}

if ($conge['statut'] !== 'en_attente') {
    sendResponse(["success" => false, "message" => "Cette demande a déjà été traitée"], 400);
}

// Update status
$stmt = $conn->prepare("UPDATE conges SET statut = ?, commentaire_rh = ?, approved_by = ? WHERE id = ?");
$stmt->bind_param("ssii", $data['statut'], $commentaire, $authUser['id'], $id);
$stmt->execute();

// If approved, deduct leave balance (except for unpaid leave)
if ($data['statut'] === 'approuve' && $conge['type_conge'] !== 'sans_solde') {
    $newSolde = $conge['solde_conge'] - ($conge['nb_jours'] * 24);
    $updateSolde = $conn->prepare("UPDATE users SET solde_conge = ? WHERE id = ?");
    $updateSolde->bind_param("di", $newSolde, $conge['user_id']);
    $updateSolde->execute();
}

// Notify employee
$statusText = $data['statut'] === 'approuve' ? 'approuvée' : 'refusée';
$titre = "Congé $statusText";
$message = "Votre demande de congé du " . $conge['date_debut'] . " au " . $conge['date_fin'] . " a été $statusText.";
if ($commentaire) {
    $message .= " Commentaire: $commentaire";
}

$notifStmt = $conn->prepare("INSERT INTO notifications (user_id, titre, message, type_notif) VALUES (?, ?, ?, 'conge')");
$notifStmt->bind_param("iss", $conge['user_id'], $titre, $message);
$notifStmt->execute();

sendResponse(["success" => true, "message" => "Demande de congé $statusText avec succès"]);
?>
