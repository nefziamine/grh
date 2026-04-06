<?php
require_once __DIR__ . '/../config/db_connect.php';

$authUser = getAuthUser($conn);
$userId = intval($authUser['id']);

$sql = "SELECT * FROM credits WHERE user_id = ? ORDER BY created_at DESC";
$stmt = $conn->prepare($sql);
$stmt->bind_param("i", $userId);
$stmt->execute();
$result = $stmt->get_result();

$credits = [];
while ($row = $result->fetch_assoc()) { $credits[] = $row; }

sendResponse(["success" => true, "data" => $credits]);
?>
