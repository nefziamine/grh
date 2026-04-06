<?php
require_once __DIR__ . '/../config/db_connect.php';

$authUser = getAuthUser($conn);
$userId = intval($authUser['id']);

// Check if user has any pending credits
$pendingStmt = $conn->prepare("SELECT COUNT(*) as count FROM credits WHERE user_id = ? AND statut IN ('en_attente', 'en_cours')");
$pendingStmt->bind_param("i", $userId);
$pendingStmt->execute();
$pendingCount = $pendingStmt->get_result()->fetch_assoc()['count'];

// Check if user has any approved credits in the last 3 months
$recentStmt = $conn->prepare("SELECT COUNT(*) as count FROM credits WHERE user_id = ? AND statut = 'approuve' AND created_at >= DATE_SUB(NOW(), INTERVAL 3 MONTH)");
$recentStmt->bind_param("i", $userId);
$recentStmt->execute();
$recentCount = $recentStmt->get_result()->fetch_assoc()['count'];

// Check if user has any rejected credits in the last month
$rejectedStmt = $conn->prepare("SELECT COUNT(*) as count FROM credits WHERE user_id = ? AND statut = 'refuse' AND created_at >= DATE_SUB(NOW(), INTERVAL 1 MONTH)");
$rejectedStmt->bind_param("i", $userId);
$rejectedStmt->execute();
$rejectedCount = $rejectedStmt->get_result()->fetch_assoc()['count'];

$canRequest = true;
$message = "";
$reason = "";

if ($pendingCount > 0) {
    $canRequest = false;
    $message = "Vous avez déjà une demande de crédit en cours de traitement.";
    $reason = "pending_exists";
} elseif ($recentCount >= 2) {
    $canRequest = false;
    $message = "Vous avez atteint la limite de 2 crédits approuvés sur les 3 derniers mois.";
    $reason = "limit_reached";
} elseif ($rejectedCount >= 1) {
    $canRequest = false;
    $message = "Vous devez attendre 1 mois après un refus avant de pouvoir faire une nouvelle demande.";
    $reason = "waiting_period";
}

sendResponse([
    "success" => true,
    "can_request" => $canRequest,
    "message" => $message,
    "reason" => $reason,
    "pending_count" => intval($pendingCount),
    "recent_count" => intval($recentCount),
    "rejected_count" => intval($rejectedCount)
]);
?>
