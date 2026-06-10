<?php
require_once __DIR__ . '/../config/db_connect.php';

$authUser = getAuthUser($conn);
requireRole($authUser, ['admin', 'rh']);

$month = isset($_GET['month']) ? intval($_GET['month']) : intval(date('m'));
$year = isset($_GET['year']) ? intval($_GET['year']) : intval(date('Y'));
$includeAllPending = isset($_GET['all_pending']) && $_GET['all_pending'] === '1';

$absences = [];

$pendingSql = "SELECT p.id AS pointage_id, p.user_id, p.date_pointage AS date_absence,
        'injustifiee' AS type_absence,
        'Absence automatique (aucun pointage avant 10:00)' AS motif,
        NULL AS justification, p.created_at,
        u.nom, u.prenom, u.matricule, u.departement,
        'en_attente' AS statut
        FROM pointages p
        JOIN users u ON p.user_id = u.id
        WHERE p.type_action = 'absence' AND p.status = 'en_attente'";

if (!$includeAllPending) {
    $pendingSql .= " AND MONTH(p.date_pointage) = ? AND YEAR(p.date_pointage) = ?";
}

$pendingStmt = $conn->prepare($pendingSql);
if ($includeAllPending) {
    $pendingStmt->execute();
} else {
    $pendingStmt->bind_param("ii", $month, $year);
    $pendingStmt->execute();
}
$pendingResult = $pendingStmt->get_result();
while ($row = $pendingResult->fetch_assoc()) {
    $row['id'] = intval($row['pointage_id']);
    $absences[] = $row;
}

$hasConfirmedCol = $conn->query("SHOW COLUMNS FROM absences LIKE 'is_confirmed'");
$confirmedFilter = ($hasConfirmedCol && $hasConfirmedCol->num_rows > 0)
    ? "AND COALESCE(a.is_confirmed, 1) = 1"
    : "";

$confirmedSql = "SELECT a.id, a.user_id, a.date_absence, a.type_absence, a.motif, a.justification, a.created_at,
        u.nom, u.prenom, u.matricule, u.departement,
        'confirme' AS statut, NULL AS pointage_id
        FROM absences a
        JOIN users u ON a.user_id = u.id
        WHERE MONTH(a.date_absence) = ? AND YEAR(a.date_absence) = ?
        $confirmedFilter
        ORDER BY a.date_absence DESC";

$confirmedStmt = $conn->prepare($confirmedSql);
$confirmedStmt->bind_param("ii", $month, $year);
$confirmedStmt->execute();
$confirmedResult = $confirmedStmt->get_result();
while ($row = $confirmedResult->fetch_assoc()) {
    $absences[] = $row;
}

usort($absences, function ($a, $b) {
    $order = ['en_attente' => 0, 'confirme' => 1];
    $aOrder = $order[$a['statut']] ?? 2;
    $bOrder = $order[$b['statut']] ?? 2;
    if ($aOrder !== $bOrder) {
        return $aOrder <=> $bOrder;
    }
    return strcmp($b['date_absence'], $a['date_absence']);
});

sendResponse(["success" => true, "data" => $absences]);
?>
