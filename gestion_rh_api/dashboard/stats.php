<?php
require_once __DIR__ . '/../config/db_connect.php';

$authUser = getAuthUser($conn);
$userId = intval($authUser['id']);
$isRH = in_array($authUser['role'], ['admin', 'rh']);
$userFilter = $isRH ? "" : " AND user_id = $userId";

$month = isset($_GET['month']) ? intval($_GET['month']) : intval(date('m'));
$year = isset($_GET['year']) ? intval($_GET['year']) : intval(date('Y'));

$confirmedAbsenceFilter = "COALESCE(is_confirmed, 1) = 1";

$stats = [
    'is_rh' => $isRH,
    'conges_en_attente' => 0,
    'credits_en_attente' => 0,
    'absences_mois' => 0,
    'absences_en_attente' => 0,
    'pointages_en_attente' => 0,
    'retards_mois' => 0,
    'retard_moyen_minutes' => 0,
    'absence_trend' => [],
    'retard_trend' => [],
    'conge_types' => []
];

if ($isRH) {
    // Global Summary
    $r = $conn->query("SELECT COUNT(*) as total FROM conges WHERE statut = 'en_attente'");
    if($r) $stats['conges_en_attente'] = intval($r->fetch_assoc()['total']);

    $r = $conn->query("SELECT COUNT(*) as total FROM credits WHERE statut = 'en_attente'");
    if($r) $stats['credits_en_attente'] = intval($r->fetch_assoc()['total']);

    $r = $conn->query(
        "SELECT COUNT(*) as total FROM absences
         WHERE MONTH(date_absence) = $month AND YEAR(date_absence) = $year
         AND $confirmedAbsenceFilter"
    );
    if($r) $stats['absences_mois'] = intval($r->fetch_assoc()['total']);

    $r = $conn->query(
        "SELECT COUNT(*) as total FROM pointages
         WHERE type_action = 'absence' AND status = 'en_attente'"
    );
    if($r) $stats['absences_en_attente'] = intval($r->fetch_assoc()['total']);

    $r = $conn->query("SELECT COUNT(*) as total FROM pointages WHERE status = 'en_attente'");
    if($r) $stats['pointages_en_attente'] = intval($r->fetch_assoc()['total']);

    $r = $conn->query("SELECT COUNT(*) as total FROM retards WHERE MONTH(date_retard) = $month AND YEAR(date_retard) = $year");
    if($r) $stats['retards_mois'] = intval($r->fetch_assoc()['total']);

    $r = $conn->query("SELECT AVG(duree_minutes) as avg_dur FROM retards WHERE MONTH(date_retard) = $month AND YEAR(date_retard) = $year");
    if($r) {
        $avg = $r->fetch_assoc()['avg_dur'];
        $stats['retard_moyen_minutes'] = $avg ? round(floatval($avg), 1) : 0;
    }
} else {
    // Personal Summary
    $r = $conn->query("SELECT COUNT(*) as total FROM conges WHERE user_id = $userId AND statut = 'en_attente'");
    if($r) $stats['conges_en_attente'] = intval($r->fetch_assoc()['total']);

    $r = $conn->query("SELECT COUNT(*) as total FROM credits WHERE user_id = $userId AND statut = 'en_attente'");
    if($r) $stats['credits_en_attente'] = intval($r->fetch_assoc()['total']);

    $r = $conn->query(
        "SELECT COUNT(*) as total FROM absences
         WHERE user_id = $userId AND MONTH(date_absence) = $month AND YEAR(date_absence) = $year
         AND $confirmedAbsenceFilter"
    );
    if($r) $stats['absences_mois'] = intval($r->fetch_assoc()['total']);

    $r = $conn->query(
        "SELECT COUNT(*) as total FROM pointages
         WHERE user_id = $userId AND type_action = 'absence' AND status = 'en_attente'"
    );
    if($r) $stats['absences_en_attente'] = intval($r->fetch_assoc()['total']);

    $r = $conn->query("SELECT COUNT(*) as total FROM retards WHERE user_id = $userId AND MONTH(date_retard) = $month AND YEAR(date_retard) = $year");
    if($r) $stats['retards_mois'] = intval($r->fetch_assoc()['total']);

    $r = $conn->query("SELECT AVG(duree_minutes) as avg_dur FROM retards WHERE user_id = $userId AND MONTH(date_retard) = $month AND YEAR(date_retard) = $year");
    if($r) {
        $avg = $r->fetch_assoc()['avg_dur'];
        $stats['retard_moyen_minutes'] = $avg ? round(floatval($avg), 1) : 0;
    }
}

// Trends (Work for both)
for ($i = 5; $i >= 0; $i--) {
    $m = date('m', strtotime("-$i months"));
    $y = date('Y', strtotime("-$i months"));
    $label = date('M Y', strtotime("-$i months"));

    $absenceUserFilter = $isRH ? "" : " AND user_id = $userId";
    $r = $conn->query(
        "SELECT COUNT(*) as total FROM absences
         WHERE MONTH(date_absence) = $m AND YEAR(date_absence) = $y
         AND $confirmedAbsenceFilter $absenceUserFilter"
    );
    $stats['absence_trend'][] = [
        'month' => $label,
        'count' => $r ? intval($r->fetch_assoc()['total']) : 0
    ];

    $r = $conn->query("SELECT COUNT(*) as total FROM retards WHERE MONTH(date_retard) = $m AND YEAR(date_retard) = $y $userFilter");
    $stats['retard_trend'][] = [
        'month' => $label,
        'count' => $r ? intval($r->fetch_assoc()['total']) : 0
    ];
}

// Leave type distribution (Work for both)
$r = $conn->query("SELECT type_conge, COUNT(*) as count FROM conges WHERE YEAR(created_at) = $year $userFilter GROUP BY type_conge");
if($r) {
    while ($row = $r->fetch_assoc()) {
        $stats['conge_types'][] = [
            'type_conge' => $row['type_conge'],
            'count' => intval($row['count'])
        ];
    }
}

// RH Exclusive Detailed View
if ($isRH) {
    // Department breakdown
    $r = $conn->query("SELECT departement, COUNT(*) as count FROM users WHERE role = 'employee' AND is_active = 1 AND departement IS NOT NULL GROUP BY departement ORDER BY count DESC");
    $stats['departements'] = [];
    if($r) {
        while ($row = $r->fetch_assoc()) { $stats['departements'][] = $row; }
    }

    // Top absent employees
    $r = $conn->query("SELECT u.nom, u.prenom, u.matricule, COUNT(a.id) as total_absences 
                        FROM absences a JOIN users u ON a.user_id = u.id 
                        WHERE YEAR(a.date_absence) = $year AND COALESCE(a.is_confirmed, 1) = 1
                        GROUP BY a.user_id ORDER BY total_absences DESC LIMIT 5");
    $stats['top_absents'] = [];
    if($r) {
        while ($row = $r->fetch_assoc()) { $stats['top_absents'][] = $row; }
    }
}

sendResponse(["success" => true, "version" => "2.0_debug", "data" => $stats]);
?>
