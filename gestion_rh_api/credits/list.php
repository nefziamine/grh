<?php
require_once __DIR__ . '/../config/db_connect.php';

$authUser = getAuthUser($conn);
requireRole($authUser, ['admin', 'rh']);

// Additional security check - ensure only admin/rh can access
if (!in_array($authUser['role'], ['admin', 'rh'])) {
    sendResponse(["success" => false, "message" => "Accès non autorisé"], 403);
    exit;
}

$statut = isset($_GET['statut']) ? $conn->real_escape_string($_GET['statut']) : '';

$where = "WHERE 1=1";
if ($statut) { $where .= " AND c.statut = '$statut'"; }

$sql = "SELECT c.*, u.nom, u.prenom, u.matricule, u.departement
        FROM credits c
        JOIN users u ON c.user_id = u.id
        $where
        ORDER BY c.created_at DESC";

$result = $conn->query($sql);
$credits = [];
while ($row = $result->fetch_assoc()) { $credits[] = $row; }

sendResponse(["success" => true, "data" => $credits]);
?>
