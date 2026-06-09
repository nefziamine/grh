<?php

const ATTENDANCE_CUTOFF_TIME = '10:00:00';
const ATTENDANCE_LATE_THRESHOLD = '09:00:00';
const RETARD_PENALTY_HOURS = 12;
const RETARDS_PER_PENALTY = 5;

function isPastCutoff($time = null) {
    $time = $time ?? date('H:i:s');
    return strtotime($time) > strtotime(ATTENDANCE_CUTOFF_TIME);
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

function recordAutoAbsenceForUser($conn, $userId, $date = null, $notify = true) {
    $date = $date ?? date('Y-m-d');
    $now = date('H:i:s');

    if (!isPastCutoff($now)) {
        return ['recorded' => false, 'reason' => 'before_cutoff'];
    }

    if (isUserOnApprovedLeave($conn, $userId, $date)) {
        return ['recorded' => false, 'reason' => 'on_leave'];
    }

    if (userHasPointageToday($conn, $userId, $date)) {
        return ['recorded' => false, 'reason' => 'already_pointed'];
    }

    $checkAbsence = $conn->prepare(
        "SELECT id FROM absences WHERE user_id = ? AND date_absence = ?"
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
        $msg = "Absence automatique enregistrée pour le $date (aucun pointage avant 10:00).";
        $notif = $conn->prepare(
            "INSERT INTO notifications (user_id, titre, message, type_notif) VALUES (?, 'Absence automatique', ?, 'absence')"
        );
        $notif->bind_param("is", $userId, $msg);
        $notif->execute();
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
