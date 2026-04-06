<?php
require_once __DIR__ . '/../config/db_connect.php';

$authUser = getAuthUser($conn);
$userId = intval($authUser['id']);

$sql = "SELECT * FROM notifications WHERE user_id = ? ORDER BY created_at DESC LIMIT 50";
$stmt = $conn->prepare($sql);
$stmt->bind_param("i", $userId);
$stmt->execute();
$result = $stmt->get_result();

$notifications = [];
while ($row = $result->fetch_assoc()) { $notifications[] = $row; }

// Count unread
$unreadStmt = $conn->prepare("SELECT COUNT(*) as unread FROM notifications WHERE user_id = ? AND is_read = 0");
$unreadStmt->bind_param("i", $userId);
$unreadStmt->execute();
$unread = $unreadStmt->get_result()->fetch_assoc()['unread'];

sendResponse(["success" => true, "data" => $notifications, "unread_count" => intval($unread)]);
?>
