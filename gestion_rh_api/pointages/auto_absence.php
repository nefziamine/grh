<?php
require_once __DIR__ . '/../config/db_connect.php';
require_once __DIR__ . '/../config/attendance_helpers.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendResponse(["success" => false, "message" => "Méthode non autorisée"], 405);
}

$authUser = getAuthUser($conn);
$data = json_decode(file_get_contents("php://input"), true) ?? [];

if (!empty($data['all']) && in_array($authUser['role'], ['admin', 'rh'])) {
    $count = processAutoAbsencesForAll($conn);
    sendResponse([
        "success" => true,
        "message" => "$count absence(s) automatique(s) enregistrée(s).",
        "count" => $count,
    ]);
}

$userId = intval($authUser['id']);
$outcome = recordAutoAbsenceForUser($conn, $userId, null, true, true);

if ($outcome['recorded']) {
    sendResponse([
        "success" => true,
        "message" => "Absence automatique soumise à la validation RH.",
        "recorded" => true,
        "auto_absence" => true,
        "reason" => $outcome['reason'],
    ]);
}

$messages = [
    'before_cutoff' => "Le délai de pointage n'est pas encore expiré.",
    'on_leave' => "Vous êtes en congé approuvé aujourd'hui.",
    'already_pointed' => "Vous avez déjà pointé aujourd'hui.",
    'absence_exists' => "Une absence est déjà confirmée pour aujourd'hui.",
    'absence_pending' => "Absence déjà soumise — en attente de validation RH.",
    'absence_converted' => "Absence automatique soumise à la validation RH.",
];

$alreadyAbsent = in_array($outcome['reason'], ['absence_exists', 'absence_pending'], true);

sendResponse([
    "success" => true,
    "message" => $messages[$outcome['reason']] ?? "Aucune action requise.",
    "recorded" => $alreadyAbsent,
    "auto_absence" => $alreadyAbsent,
    "reason" => $outcome['reason'],
]);

?>
