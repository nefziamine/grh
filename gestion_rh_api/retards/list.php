<?php
require_once __DIR__ . '/../config/db_connect.php';

$authUser = getAuthUser($conn);
requireRole($authUser, ['admin', 'rh']);

$month = isset($_GET['month']) ? intval($_GET['month']) : intval(date('m'));
$year = isset($_GET['year']) ? intval($_GET['year']) : intval(date('Y'));

$sql = "SELECT r.*, u.nom, u.prenom, u.matricule, u.departement
        FROM retards r
        JOIN users u ON r.user_id = u.id
        WHERE MONTH(r.date_retard) = ? AND YEAR(r.date_retard) = ?
        ORDER BY r.date_retard DESC";

$stmt = $conn->prepare($sql);
$stmt->bind_param("ii", $month, $year);
$stmt->execute();
$result = $stmt->get_result();

$retards = [];
while ($row = $result->fetch_assoc()) {
    $retards[] = $row;
}

sendResponse(["success" => true, "data" => $retards]);
?>
