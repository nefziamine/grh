<?php
require_once __DIR__ . '/../config/db_connect.php';

$authUser = getAuthUser($conn);
requireRole($authUser, ['admin', 'rh']);

$search = isset($_GET['search']) ? $conn->real_escape_string($_GET['search']) : '';
$department = isset($_GET['department']) ? $conn->real_escape_string($_GET['department']) : '';
$page = isset($_GET['page']) ? max(1, intval($_GET['page'])) : 1;
$limit = isset($_GET['limit']) ? min(500, max(1, intval($_GET['limit']))) : null; // null = no limit for admin
$offset = ($page - 1) * ($limit ?? 0);

$where = "WHERE 1=1";
if ($search) {
    $where .= " AND (nom LIKE '%$search%' OR prenom LIKE '%$search%' OR matricule LIKE '%$search%' OR email LIKE '%$search%')";
}
if ($department) {
    $where .= " AND departement = '$department'";
}

// Count total
$countResult = $conn->query("SELECT COUNT(*) as total FROM users $where");
$total = $countResult->fetch_assoc()['total'];

$sql = "SELECT id, matricule, email, role, nom, prenom, telephone, departement, poste, date_embauche, solde_conge, avatar, is_active, created_at FROM users $where ORDER BY nom ASC";
if ($limit !== null) {
    $sql .= " LIMIT $limit OFFSET $offset";
}
$result = $conn->query($sql);

$employees = [];
while ($row = $result->fetch_assoc()) {
    if (isset($row['solde_conge'])) {
        $row['solde_conge'] = round($row['solde_conge'] / 24, 1);
    }
    $employees[] = $row;
}

sendResponse([
    "success" => true,
    "data" => $employees,
    "pagination" => [
        "total" => intval($total),
        "page" => $limit !== null ? $page : 1,
        "limit" => $limit ?? $total, // Show total when no limit
        "pages" => $limit !== null ? ceil($total / $limit) : 1,
        "unlimited" => $limit === null
    ]
]);
?>
