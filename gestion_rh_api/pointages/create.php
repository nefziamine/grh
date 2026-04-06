<?php
require_once __DIR__ . '/../config/db_connect.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendResponse(["success" => false, "message" => "Méthode non autorisée"], 405);
}

$authUser = getAuthUser($conn);
$userId = intval($authUser['id']);
$today = date('Y-m-d');
$now = date('H:i:s');

// 1. Check if already pointed today
$check = $conn->prepare("SELECT id FROM pointages WHERE user_id = ? AND date_pointage = ?");
$check->bind_param("is", $userId, $today);
$check->execute();
if ($check->get_result()->num_rows > 0) {
    sendResponse(["success" => false, "message" => "Vous avez déjà pointé aujourd'hui."], 400);
}

// 2. Get Opening Time
$res = $conn->query("SELECT key_value FROM settings WHERE key_name = 'opening_time'");
$openingTime = $res->fetch_assoc()['key_value'] ?? '08:00:00';

// 3. Determine if Late
$isLate = strtotime($now) > strtotime($openingTime);
$typeAction = $isLate ? 'retard' : 'presence';

// 4. Create Pointage
$stmt = $conn->prepare("INSERT INTO pointages (user_id, date_pointage, heure_pointage, type_action, status) VALUES (?, ?, ?, ?, 'en_attente')");
$stmt->bind_param("isss", $userId, $today, $now, $typeAction);

if ($stmt->execute()) {
    $msg = $isLate ? "Pointage enregistré (Retard détecté, en attente de validation RH)." : "Pointage enregistré avec succès.";
    sendResponse(["success" => true, "message" => $msg, "type" => $typeAction]);
} else {
    sendResponse(["success" => false, "message" => "Erreur lors du pointage"], 500);
}
?>
