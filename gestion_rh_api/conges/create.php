<?php
require_once __DIR__ . '/../config/db_connect.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendResponse(["success" => false, "message" => "Méthode non autorisée"], 405);
}

$authUser = getAuthUser($conn);

$data = json_decode(file_get_contents("php://input"), true);

$required = ['type_conge', 'date_debut', 'date_fin', 'nb_jours'];
foreach ($required as $field) {
    if (!isset($data[$field]) || empty($data[$field])) {
        sendResponse(["success" => false, "message" => "Champ requis manquant: $field"], 400);
    }
}

$userId = intval($authUser['id']);
$motif = $data['motif'] ?? '';

// Check leave balance for annual leaves
if ($data['type_conge'] === 'annuel') {
    $stmt = $conn->prepare("SELECT solde_conge FROM users WHERE id = ?");
    $stmt->bind_param("i", $userId);
    $stmt->execute();
    $solde = $stmt->get_result()->fetch_assoc()['solde_conge'];
    
    if (intval($data['nb_jours']) > $solde) {
        sendResponse(["success" => false, "message" => "Solde insuffisant"], 400);
    }
}

// Check for overlapping leaves
$stmt = $conn->prepare("SELECT id FROM conges WHERE user_id = ? AND statut != 'refuse' AND ((date_debut <= ? AND date_fin >= ?) OR (date_debut <= ? AND date_fin >= ?))");
$stmt->bind_param("issss", $userId, $data['date_fin'], $data['date_debut'], $data['date_debut'], $data['date_debut']);
$stmt->execute();
if ($stmt->get_result()->num_rows > 0) {
    sendResponse(["success" => false, "message" => "Chevauchement avec une demande existante"], 409);
}

$stmt = $conn->prepare("INSERT INTO conges (user_id, type_conge, date_debut, date_fin, nb_jours, motif) VALUES (?, ?, ?, ?, ?, ?)");
$stmt->bind_param("isssis", $userId, $data['type_conge'], $data['date_debut'], $data['date_fin'], $data['nb_jours'], $motif);

if ($stmt->execute()) {
    // Notify RH users
    $rhUsers = $conn->query("SELECT id FROM users WHERE role = 'rh' AND is_active = 1");
    $titre = "Nouvelle demande de congé";
    $message = $authUser['nom'] . " " . $authUser['prenom'] . " a soumis une demande de congé du " . $data['date_debut'] . " au " . $data['date_fin'];
    
    while ($rh = $rhUsers->fetch_assoc()) {
        $notifStmt = $conn->prepare("INSERT INTO notifications (user_id, titre, message, type_notif) VALUES (?, ?, ?, 'conge')");
        $notifStmt->bind_param("iss", $rh['id'], $titre, $message);
        $notifStmt->execute();
    }
    
    // Notify the employee
    $selfNotif = $conn->prepare("INSERT INTO notifications (user_id, titre, message, type_notif) VALUES (?, 'Demande soumise', 'Votre demande de congé a été soumise avec succès et est en attente de validation.', 'conge')");
    $selfNotif->bind_param("i", $userId);
    $selfNotif->execute();
    
    sendResponse(["success" => true, "message" => "Demande de congé soumise avec succès", "id" => $conn->insert_id], 201);
} else {
    sendResponse(["success" => false, "message" => "Erreur lors de la soumission"], 500);
}
?>
