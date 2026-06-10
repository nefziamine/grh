<?php

const ATTENDANCE_CUTOFF_TIME = '10:00:00';
const ATTENDANCE_LATE_THRESHOLD = '09:00:00';
const RETARD_PENALTY_HOURS = 12;
const RETARDS_PER_PENALTY = 5;

function isPastCutoff($time = null) {
    $time = $time ?? date('H:i:s');
    return strtotime($time) >= strtotime(ATTENDANCE_CUTOFF_TIME);
}

function isUserOnApprovedLeave($conn, $userId, $date) {
    $stmt = $conn->prepare(
        "SELECT id FROM conges WHERE user_id = ? AND date_debut <= ? AND date_fin >= ? AND statut = 'approuve'"
    );
    $stmt->bind_param("iss", $userId, $date, $date);
    $stmt->execute();
    return $stmt->get_result()->num_rows > 0;
}

function userHasPointageToday($conn, $userId, $date) {
    $stmt = $conn->prepare("SELECT id FROM pointages WHERE user_id = ? AND date_pointage = ?");
    $stmt->bind_param("is", $userId, $date);
    $stmt->execute();
    return $stmt->get_result()->num_rows > 0;
}

function applyRetardPenalty($conn, $userId) {
    $countStmt = $conn->prepare("SELECT COUNT(*) FROM retards WHERE user_id = ? AND is_confirmed = 1");
    $countStmt->bind_param("i", $userId);
    $countStmt->execute();
    $count = intval($countStmt->get_result()->fetch_row()[0]);

    if ($count > 0 && $count % RETARDS_PER_PENALTY === 0) {
        $updateSolde = $conn->prepare(
            "UPDATE users SET solde_conge = GREATEST(0, solde_conge - ?) WHERE id = ?"
        );
        $hours = RETARD_PENALTY_HOURS;
        $updateSolde->bind_param("ii", $hours, $userId);
        $updateSolde->execute();

        $msg = "Sanction : " . RETARD_PENALTY_HOURS . " heures (0.5 jour) ont été déduites de votre solde pour cause de cumul de $count retards.";
        $notif = $conn->prepare(
            "INSERT INTO notifications (user_id, titre, message, type_notif) VALUES (?, 'Sanction de retard', ?, 'sanction')"
        );
        $notif->bind_param("is", $userId, $msg);
        $notif->execute();

        return true;
    }

    return false;
}

function notifyRhPendingAbsence($conn, $employeeUserId, $date) {
    $empStmt = $conn->prepare("SELECT nom, prenom FROM users WHERE id = ?");
    $empStmt->bind_param("i", $employeeUserId);
    $empStmt->execute();
    $emp = $empStmt->get_result()->fetch_assoc();
    if (!$emp) {
        return;
    }

    $employeeName = trim(($emp['prenom'] ?? '') . ' ' . ($emp['nom'] ?? ''));
    $msg = "Absence automatique à valider : $employeeName le $date (aucun pointage avant 10:00).";
    $title = 'Absence à valider';

    $rhResult = $conn->query(
        "SELECT id FROM users WHERE role IN ('rh', 'admin') AND is_active = 1"
    );
    if (!$rhResult) {
        return;
    }

    $notif = $conn->prepare(
        "INSERT INTO notifications (user_id, titre, message, type_notif) VALUES (?, ?, ?, 'absence')"
    );
    while ($rh = $rhResult->fetch_assoc()) {
        $rhId = intval($rh['id']);
        $notif->bind_param("iss", $rhId, $title, $msg);
        $notif->execute();
    }
}

function convertPointageToAbsence($conn, $userId, $date, $notify = true) {
    $stmt = $conn->prepare(
        "SELECT id, type_action FROM pointages WHERE user_id = ? AND date_pointage = ? LIMIT 1"
    );
    $stmt->bind_param("is", $userId, $date);
    $stmt->execute();
    $row = $stmt->get_result()->fetch_assoc();
    if (!$row || $row['type_action'] === 'absence') {
        return false;
    }

    $now = date('H:i:s');
    $upd = $conn->prepare(
        "UPDATE pointages SET type_action = 'absence', heure_pointage = ?, status = 'en_attente' WHERE id = ?"
    );
    $upd->bind_param("si", $now, $row['id']);
    $upd->execute();

    $del = $conn->prepare("DELETE FROM retards WHERE user_id = ? AND date_retard = ?");
    $del->bind_param("is", $userId, $date);
    $del->execute();

    if ($notify) {
        $msg = "Absence automatique soumise pour le $date. En attente de validation RH.";
        $notif = $conn->prepare(
            "INSERT INTO notifications (user_id, titre, message, type_notif) VALUES (?, 'Absence soumise', ?, 'absence')"
        );
        $notif->bind_param("is", $userId, $msg);
        $notif->execute();
        notifyRhPendingAbsence($conn, $userId, $date);
    }

    return true;
}

function ensureAbsenceRecord($conn, $userId, $date, $motif = 'Absence automatique (aucun pointage avant 10:00)', $confirmed = true) {
    $checkAbsence = $conn->prepare(
        "SELECT id FROM absences WHERE user_id = ? AND date_absence = ?"
    );
    $checkAbsence->bind_param("is", $userId, $date);
    $checkAbsence->execute();
    if ($checkAbsence->get_result()->num_rows > 0) {
        return false;
    }

    $confirmedInt = $confirmed ? 1 : 0;
    $ins = $conn->prepare(
        "INSERT INTO absences (user_id, date_absence, type_absence, motif, is_confirmed) VALUES (?, ?, 'injustifiee', ?, ?)"
    );
    $ins->bind_param("issi", $userId, $date, $motif, $confirmedInt);
    $ins->execute();

    return true;
}

function hasPendingAbsencePointage($conn, $userId, $date) {
    $stmt = $conn->prepare(
        "SELECT id FROM pointages WHERE user_id = ? AND date_pointage = ? AND type_action = 'absence' AND status = 'en_attente' LIMIT 1"
    );
    $stmt->bind_param("is", $userId, $date);
    $stmt->execute();
    return $stmt->get_result()->num_rows > 0;
}

function recordAutoAbsenceForUser($conn, $userId, $date = null, $notify = true, $explicitRequest = false) {
    $date = $date ?? date('Y-m-d');
    $now = date('H:i:s');

    if (!isPastCutoff($now)) {
        return ['recorded' => false, 'reason' => 'before_cutoff'];
    }

    if (isUserOnApprovedLeave($conn, $userId, $date)) {
        return ['recorded' => false, 'reason' => 'on_leave'];
    }

    if (userHasPointageToday($conn, $userId, $date)) {
        $stmt = $conn->prepare(
            "SELECT type_action, heure_pointage FROM pointages WHERE user_id = ? AND date_pointage = ? LIMIT 1"
        );
        $stmt->bind_param("is", $userId, $date);
        $stmt->execute();
        $row = $stmt->get_result()->fetch_assoc();
        if ($row && $row['type_action'] === 'absence') {
            return ['recorded' => false, 'reason' => 'absence_pending'];
        }
        $shouldConvert = isPastCutoff($now) && (
            strtotime($row['heure_pointage']) >= strtotime(ATTENDANCE_CUTOFF_TIME)
            || ($explicitRequest && in_array($row['type_action'], ['retard', 'presence'], true))
        );
        if ($row && $shouldConvert) {
            convertPointageToAbsence($conn, $userId, $date, $notify);
            return ['recorded' => true, 'reason' => 'absence_converted'];
        }
        return ['recorded' => false, 'reason' => 'already_pointed'];
    }

    if (hasPendingAbsencePointage($conn, $userId, $date)) {
        return ['recorded' => false, 'reason' => 'absence_pending'];
    }

    $checkAbsence = $conn->prepare(
        "SELECT id FROM absences WHERE user_id = ? AND date_absence = ? AND COALESCE(is_confirmed, 1) = 1"
    );
    $checkAbsence->bind_param("is", $userId, $date);
    $checkAbsence->execute();
    if ($checkAbsence->get_result()->num_rows > 0) {
        return ['recorded' => false, 'reason' => 'absence_exists'];
    }

    $ins = $conn->prepare(
        "INSERT INTO pointages (user_id, date_pointage, heure_pointage, type_action, status) VALUES (?, ?, ?, 'absence', 'en_attente')"
    );
    $ins->bind_param("iss", $userId, $date, $now);
    $ins->execute();

    if ($notify) {
        $msg = "Absence automatique soumise pour le $date. En attente de validation RH.";
        $notif = $conn->prepare(
            "INSERT INTO notifications (user_id, titre, message, type_notif) VALUES (?, 'Absence soumise', ?, 'absence')"
        );
        $notif->bind_param("is", $userId, $msg);
        $notif->execute();
        notifyRhPendingAbsence($conn, $userId, $date);
    }

    return ['recorded' => true, 'reason' => 'absence_created'];
}

function processAutoAbsencesForAll($conn) {
    $today = date('Y-m-d');

    if (!isPastCutoff()) {
        return 0;
    }

    $sql = "SELECT id FROM users
            WHERE is_active = 1
            AND id NOT IN (SELECT user_id FROM pointages WHERE date_pointage = ?)
            AND id NOT IN (SELECT user_id FROM conges WHERE date_debut <= ? AND date_fin >= ? AND statut = 'approuve')";

    $stmt = $conn->prepare($sql);
    $stmt->bind_param("sss", $today, $today, $today);
    $stmt->execute();
    $result = $stmt->get_result();

    $count = 0;
    while ($user = $result->fetch_assoc()) {
        $outcome = recordAutoAbsenceForUser($conn, intval($user['id']), $today, true);
        if ($outcome['recorded']) {
            $count++;
        }
    }

    return $count;
}

?>
