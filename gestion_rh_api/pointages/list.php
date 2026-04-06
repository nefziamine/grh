<?php
require_once __DIR__ . '/../config/db_connect.php';

$authUser = getAuthUser($conn);
requireRole($authUser, ['admin', 'rh']);

$filter = isset($_GET['status']) ? $_GET['status'] : 'en_attente';

$sql = "SELECT p.*, u.nom, u.prenom, u.matricule, u.departement 
        FROM pointages p 
        JOIN users u ON p.user_id = u.id 
        WHERE p.status = ? 
        ORDER BY p.created_at DESC";

$stmt = $conn->prepare($sql);
$stmt->bind_param("s", $filter);
$stmt->execute();
$result = $stmt->get_result();

$pointages = [];
while ($row = $result->fetch_assoc()) { $pointages[] = $row; }

sendResponse(["success" => true, "data" => $pointages]);
?>
