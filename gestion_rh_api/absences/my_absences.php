<?php
require_once __DIR__ . '/../config/db_connect.php';

$authUser = getAuthUser($conn);
$userId = intval($authUser['id']);

$sql = "SELECT * FROM absences WHERE user_id = ? AND COALESCE(is_confirmed, 1) = 1 ORDER BY date_absence DESC";
$stmt = $conn->prepare($sql);
$stmt->bind_param("i", $userId);
$stmt->execute();
$result = $stmt->get_result();

$absences = [];
while ($row = $result->fetch_assoc()) {
    $absences[] = $row;
}

sendResponse(["success" => true, "data" => $absences]);
?>
