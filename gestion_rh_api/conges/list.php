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
$userId = isset($_GET['user_id']) ? intval($_GET['user_id']) : 0;
$page = isset($_GET['page']) ? max(1, intval($_GET['page'])) : 1;
$limit = isset($_GET['limit']) ? min(50, max(1, intval($_GET['limit']))) : 20;
$offset = ($page - 1) * $limit;

$where = "WHERE 1=1";
if ($statut) {
    $where .= " AND c.statut = '$statut'";
}
if ($userId > 0) {
    $where .= " AND c.user_id = $userId";
}

$sql = "SELECT c.*, u.nom, u.prenom, u.matricule, u.departement,
        CONCAT(a.nom, ' ', a.prenom) as approved_by_name
        FROM conges c
        JOIN users u ON c.user_id = u.id
        LEFT JOIN users a ON c.approved_by = a.id
        $where
        ORDER BY c.created_at DESC
        LIMIT $limit OFFSET $offset";

$result = $conn->query($sql);
$conges = [];
while ($row = $result->fetch_assoc()) {
    $conges[] = $row;
}

$countResult = $conn->query("SELECT COUNT(*) as total FROM conges c JOIN users u ON c.user_id = u.id $where");
$total = $countResult->fetch_assoc()['total'];

sendResponse([
    "success" => true,
    "data" => $conges,
    "pagination" => ["total" => intval($total), "page" => $page, "limit" => $limit]
]);
?>
