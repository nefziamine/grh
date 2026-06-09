<?php
require_once __DIR__ . '/../config/db_connect.php';
require_once __DIR__ . '/../config/attendance_helpers.php';

if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    sendResponse(["success" => false, "message" => "Méthode non autorisée"], 405);
}

$authUser = getAuthUser($conn);
$userId = intval($authUser['id']);
$today = date('Y-m-d');
$now = date('H:i:s');

if (isPastCutoff($now)) {
    recordAutoAbsenceForUser($conn, $userId, $today, true);
}

$stmt = $conn->prepare(
    "SELECT id, type_action, status, heure_pointage FROM pointages WHERE user_id = ? AND date_pointage = ? LIMIT 1"
);
$stmt->bind_param("is", $userId, $today);
$stmt->execute();
$pointage = $stmt->get_result()->fetch_assoc();

sendResponse([
    "success" => true,
    "has_pointed" => $pointage !== null,
    "pointage" => $pointage,
    "past_cutoff" => isPastCutoff($now),
    "on_leave" => isUserOnApprovedLeave($conn, $userId, $today),
]);

?>
