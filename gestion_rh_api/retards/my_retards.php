<?php
require_once __DIR__ . '/../config/db_connect.php';

$authUser = getAuthUser($conn);
$userId = intval($authUser['id']);

$sql = "SELECT * FROM retards WHERE user_id = ? ORDER BY date_retard DESC";
$stmt = $conn->prepare($sql);
$stmt->bind_param("i", $userId);
$stmt->execute();
$result = $stmt->get_result();

$retards = [];
while ($row = $result->fetch_assoc()) {
    $retards[] = $row;
}

sendResponse(["success" => true, "data" => $retards]);
?>
