<?php
require_once __DIR__ . '/../config/db_connect.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendResponse(["success" => false, "message" => "Méthode non autorisée"], 405);
}

$authUser = getAuthUser($conn);

$data = json_decode(file_get_contents("php://input"), true);

$required = ['type_credit', 'montant', 'duree_mois'];
foreach ($required as $field) {
    if (!isset($data[$field])) {
        sendResponse(["success" => false, "message" => "Champ requis: $field"], 400);
    }
}

$userId = intval($authUser['id']);
$taux = $data['taux_interet'] ?? 0;
$mensualite = 0;
if ($taux > 0 && $data['duree_mois'] > 0) {
    $tauxMensuel = ($taux / 100) / 12;
    $mensualite = ($data['montant'] * $tauxMensuel) / (1 - pow(1 + $tauxMensuel, -$data['duree_mois']));
}
$motif = $data['motif'] ?? '';

$stmt = $conn->prepare("INSERT INTO credits (user_id, type_credit, montant, duree_mois, taux_interet, mensualite, motif) VALUES (?, ?, ?, ?, ?, ?, ?)");
$stmt->bind_param("isdidds", $userId, $data['type_credit'], $data['montant'], $data['duree_mois'], $taux, $mensualite, $motif);

if ($stmt->execute()) {
    // Notify RH
    $rhUsers = $conn->query("SELECT id FROM users WHERE role = 'rh' AND is_active = 1");
    $titre = "Nouvelle demande de crédit";
    $message = $authUser['nom'] . " " . $authUser['prenom'] . " a demandé un crédit " . $data['type_credit'] . " de " . number_format($data['montant'], 2) . " TND";
    while ($rh = $rhUsers->fetch_assoc()) {
        $n = $conn->prepare("INSERT INTO notifications (user_id, titre, message, type_notif) VALUES (?, ?, ?, 'credit')");
        $n->bind_param("iss", $rh['id'], $titre, $message);
        $n->execute();
    }
    
    sendResponse(["success" => true, "message" => "Demande de crédit soumise", "id" => $conn->insert_id], 201);
} else {
    sendResponse(["success" => false, "message" => "Erreur"], 500);
}
?>
