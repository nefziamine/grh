<?php
require_once __DIR__ . '/../config/db_connect.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendResponse(["success" => false, "message" => "Méthode non autorisée"], 405);
}

$authUser = getAuthUser($conn);
requireRole($authUser, ['admin', 'rh']);

$today = date('Y-m-d');

// Find all active employees who haven't pointed today (and are not on approved leave)
$sql = "SELECT id FROM users 
        WHERE role = 'employee' 
        AND id NOT IN (SELECT user_id FROM pointages WHERE date_pointage = ?)
        AND id NOT IN (SELECT user_id FROM conges WHERE date_debut <= ? AND date_fin >= ? AND statut = 'approuve')";

$stmt = $conn->prepare($sql);
$stmt->bind_param("sss", $today, $today, $today);
$stmt->execute();
$result = $stmt->get_result();

$count = 0;
while ($user = $result->fetch_assoc()) {
    $userId = $user['id'];
    
    // Check if pending absence already exists
    $check = $conn->prepare("SELECT id FROM pointages WHERE user_id = ? AND date_pointage = ? AND type_action = 'absence'");
    $check->bind_param("is", $userId, $today);
    $check->execute();
    
    if ($check->get_result()->num_rows === 0) {
        $ins = $conn->prepare("INSERT INTO pointages (user_id, date_pointage, heure_pointage, type_action, status) VALUES (?, ?, '00:00:00', 'absence', 'en_attente')");
        $ins->bind_param("is", $userId, $today);
        $ins->execute();
        $count++;
    }
}

sendResponse(["success" => true, "message" => "$count absences détectées et mises en attente."]);
?>
