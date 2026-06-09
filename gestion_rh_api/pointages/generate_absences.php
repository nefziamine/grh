<?php
require_once __DIR__ . '/../config/db_connect.php';
require_once __DIR__ . '/../config/attendance_helpers.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendResponse(["success" => false, "message" => "Méthode non autorisée"], 405);
}

$authUser = getAuthUser($conn);
requireRole($authUser, ['admin', 'rh']);

if (!isPastCutoff()) {
    sendResponse([
        "success" => false,
        "message" => "Les absences automatiques ne sont disponibles qu'après 10:00.",
    ], 400);
}

$count = processAutoAbsencesForAll($conn);

sendResponse([
    "success" => true,
    "message" => "$count absence(s) automatique(s) détectée(s) et mise(s) en attente.",
    "count" => $count,
]);

?>
