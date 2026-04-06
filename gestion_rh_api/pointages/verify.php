<?php
require_once __DIR__ . '/../config/db_connect.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendResponse(["success" => false, "message" => "Méthode non autorisée"], 405);
}

$authUser = getAuthUser($conn);
requireRole($authUser, ['admin', 'rh']);

$data = json_decode(file_get_contents("php://input"), true);

if (!isset($data['id']) || !isset($data['status'])) {
    sendResponse(["success" => false, "message" => "ID et statut requis"], 400);
}

$id = intval($data['id']);
$status = $data['status']; // 'valide' or 'rejete'

// 1. Get Pointage Details
$stmt = $conn->prepare("SELECT p.*, u.nom, u.prenom FROM pointages p JOIN users u ON p.user_id = u.id WHERE p.id = ?");
$stmt->bind_param("i", $id);
$stmt->execute();
$pointage = $stmt->get_result()->fetch_assoc();

if (!$pointage) {
    sendResponse(["success" => false, "message" => "Pointage non trouvé"], 404);
}

if ($pointage['status'] !== 'en_attente') {
    sendResponse(["success" => false, "message" => "Ce pointage a déjà été traité."], 400);
}

// 2. Validate and Create Real Records
$conn->begin_transaction();

try {
    $stmt = $conn->prepare("UPDATE pointages SET status = ?, valide_par = ? WHERE id = ?");
    $stmt->bind_param("sii", $status, $authUser['id'], $id);
    $stmt->execute();

    if ($status === 'valide') {
        if ($pointage['type_action'] === 'retard') {
            // Create real retard entry
            $openingTimeRes = $conn->query("SELECT key_value FROM settings WHERE key_name = 'opening_time'");
            $openingTime = $openingTimeRes->fetch_assoc()['key_value'] ?? '08:00:00';
            
            $diff = (strtotime($pointage['heure_pointage']) - strtotime($openingTime)) / 60;
            $duree = max(0, intval($diff));

            $ins = $conn->prepare("INSERT INTO retards (user_id, date_retard, heure_arrivee, duree_minutes, motif, is_confirmed) VALUES (?, ?, ?, ?, 'Généré par pointage automatique', 1)");
            $ins->bind_param("issi", $pointage['user_id'], $pointage['date_pointage'], $pointage['heure_pointage'], $duree);
            $ins->execute();
            
            // Apply Penalty Rule (every 5 retards)
            $countStmt = $conn->prepare("SELECT COUNT(*) FROM retards WHERE user_id = ? AND is_confirmed = 1");
            $countStmt->bind_param("i", $pointage['user_id']);
            $countStmt->execute();
            $count = $countStmt->get_result()->fetch_row()[0];

            if ($count > 0 && $count % 5 == 0) {
                 $conn->query("UPDATE users SET solde_conge = solde_conge - 0.5 WHERE id = " . $pointage['user_id']);
                 $notifMsg = "Sanction : 12 heures déduites de votre solde pour cause de cumul de $count retards.";
                 $notif = $conn->prepare("INSERT INTO notifications (user_id, titre, message, type_notif) VALUES (?, 'Sanction de retard', ?, 'sanction')");
                 $notif->bind_param("is", $pointage['user_id'], $notifMsg);
                 $notif->execute();
            }
            
            $notifTitle = "Pointage validé (Retard)";
            $notifContent = "Votre retard du " . $pointage['date_pointage'] . " a été officiellement enregistré.";
        } else if ($pointage['type_action'] === 'absence') {
            // Create real absence entry
            $ins = $conn->prepare("INSERT INTO absences (user_id, date_absence, type_absence, motif, is_confirmed) VALUES (?, ?, 'injustifiee', 'Généré par absence automatique', 1)");
            $ins->bind_param("is", $pointage['user_id'], $pointage['date_pointage']);
            $ins->execute();
            
            $notifTitle = "Absence validée";
            $notifContent = "Votre absence injustifiée du " . $pointage['date_pointage'] . " a été officiellement enregistrée.";
        } else {
            $notifTitle = "Pointage validé";
            $notifContent = "Votre présence du " . $pointage['date_pointage'] . " est validée.";
        }
        
        // Notify employee
        $notif = $conn->prepare("INSERT INTO notifications (user_id, titre, message, type_notif) VALUES (?, ?, ?, 'retard')");
        $notif->bind_param("iss", $pointage['user_id'], $notifTitle, $notifContent);
        $notif->execute();
    } else if ($status === 'rejete') {
        // Any rejected pointage becomes an absence automatically
        $ins = $conn->prepare("INSERT INTO absences (user_id, date_absence, type_absence, motif, is_confirmed) VALUES (?, ?, 'injustifiee', 'Pointage rejeté par la RH', 1)");
        $ins->bind_param("is", $pointage['user_id'], $pointage['date_pointage']);
        $ins->execute();
        
        $notifTitle = "Pointage rejeté (Absence enregistrée)";
        $notifContent = "Votre pointage du " . $pointage['date_pointage'] . " a été rejeté par la RH. Une absence a été enregistrée.";
        
        $notif = $conn->prepare("INSERT INTO notifications (user_id, titre, message, type_notif) VALUES (?, ?, ?, 'absence')");
        $notif->bind_param("iss", $pointage['user_id'], $notifTitle, $notifContent);
        $notif->execute();
    }

    $conn->commit();
    sendResponse(["success" => true, "message" => "Pointage " . ($status === 'valide' ? 'validé' : 'rejeté') . " avec succès."]);

} catch (Exception $e) {
    $conn->rollback();
    sendResponse(["success" => false, "message" => "Erreur : " . $e->getMessage()], 500);
}
?>
