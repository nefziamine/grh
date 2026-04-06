<?php
require_once __DIR__ . '/../config/db_connect.php';

$authUser = getAuthUser($conn);
requireRole($authUser, ['admin', 'rh']);

$month = isset($_GET['month']) ? intval($_GET['month']) : intval(date('m'));
$year = isset($_GET['year']) ? intval($_GET['year']) : intval(date('Y'));

$sql = "SELECT a.*, u.nom, u.prenom, u.matricule, u.departement
        FROM absences a
        JOIN users u ON a.user_id = u.id
        WHERE MONTH(a.date_absence) = ? AND YEAR(a.date_absence) = ?
        ORDER BY a.date_absence DESC";

$stmt = $conn->prepare($sql);
$stmt->bind_param("ii", $month, $year);
$stmt->execute();
$result = $stmt->get_result();

$absences = [];
while ($row = $result->fetch_assoc()) {
    $absences[] = $row;
}

sendResponse(["success" => true, "data" => $absences]);
?>
