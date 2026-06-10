<?php
require_once __DIR__ . '/../config/db_connect.php';
require_once __DIR__ . '/../config/attendance_helpers.php';

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
$status = $data['status'];

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

$conn->begin_transaction();

try {
    $stmt = $conn->prepare("UPDATE pointages SET status = ?, valide_par = ? WHERE id = ?");
    $stmt->bind_param("sii", $status, $authUser['id'], $id);
    $stmt->execute();

    if ($status === 'valide') {
        if ($pointage['type_action'] === 'retard') {
            $existingRetard = $conn->prepare(
                "SELECT id FROM retards WHERE user_id = ? AND date_retard = ? LIMIT 1"
            );
            $existingRetard->bind_param("is", $pointage['user_id'], $pointage['date_pointage']);
            $existingRetard->execute();
            $existing = $existingRetard->get_result()->fetch_assoc();

            if ($existing) {
                $upd = $conn->prepare("UPDATE retards SET is_confirmed = 1 WHERE id = ?");
                $upd->bind_param("i", $existing['id']);
                $upd->execute();
            } else {
                $openingTimeRes = $conn->query("SELECT key_value FROM settings WHERE key_name = 'opening_time'");
                $openingTime = $openingTimeRes->fetch_assoc()['key_value'] ?? '08:00:00';

                $diff = (strtotime($pointage['heure_pointage']) - strtotime($openingTime)) / 60;
                $duree = max(0, intval($diff));

                $ins = $conn->prepare(
                    "INSERT INTO retards (user_id, date_retard, heure_arrivee, duree_minutes, motif, is_confirmed) VALUES (?, ?, ?, ?, 'Généré par pointage automatique', 1)"
                );
                $ins->bind_param("issi", $pointage['user_id'], $pointage['date_pointage'], $pointage['heure_pointage'], $duree);
                $ins->execute();
            }

            applyRetardPenalty($conn, intval($pointage['user_id']));

            $notifTitle = "Pointage validé (Retard)";
            $notifContent = "Votre retard du " . $pointage['date_pointage'] . " a été officiellement enregistré.";
            $notifType = 'retard';
        } else if ($pointage['type_action'] === 'absence') {
            ensureAbsenceRecord(
                $conn,
                intval($pointage['user_id']),
                $pointage['date_pointage'],
                'Absence automatique (aucun pointage)',
                true
            );

            $notifTitle = "Absence validée";
            $notifContent = "Votre absence du " . $pointage['date_pointage'] . " a été confirmée par la RH.";
            $notifType = 'absence';
        } else {
            $notifTitle = "Pointage validé";
            $notifContent = "Votre présence du " . $pointage['date_pointage'] . " est validée.";
            $notifType = 'retard';
        }

        $notif = $conn->prepare("INSERT INTO notifications (user_id, titre, message, type_notif) VALUES (?, ?, ?, ?)");
        $notif->bind_param("isss", $pointage['user_id'], $notifTitle, $notifContent, $notifType);
        $notif->execute();
    } else if ($status === 'rejete') {
        if ($pointage['type_action'] === 'absence') {
            $notifTitle = "Absence non confirmée";
            $notifContent = "Votre absence signalée du " . $pointage['date_pointage'] . " a été rejetée par la RH.";
            $notifType = 'absence';
        } else {
            $ins = $conn->prepare(
                "INSERT INTO absences (user_id, date_absence, type_absence, motif, is_confirmed) VALUES (?, ?, 'injustifiee', 'Pointage rejeté par la RH', 1)"
            );
            $ins->bind_param("is", $pointage['user_id'], $pointage['date_pointage']);
            $ins->execute();

            $notifTitle = "Pointage rejeté (Absence enregistrée)";
            $notifContent = "Votre pointage du " . $pointage['date_pointage'] . " a été rejeté par la RH. Une absence a été enregistrée.";
            $notifType = 'absence';
        }

        $notif = $conn->prepare("INSERT INTO notifications (user_id, titre, message, type_notif) VALUES (?, ?, ?, ?)");
        $notif->bind_param("isss", $pointage['user_id'], $notifTitle, $notifContent, $notifType);
        $notif->execute();
    }

    $conn->commit();
    sendResponse(["success" => true, "message" => "Pointage " . ($status === 'valide' ? 'validé' : 'rejeté') . " avec succès."]);

} catch (Exception $e) {
    $conn->rollback();
    sendResponse(["success" => false, "message" => "Erreur : " . $e->getMessage()], 500);
}
?>
