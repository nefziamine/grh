<?php
require_once __DIR__ . '/../config/db_connect.php';

$authUser = getAuthUser($conn);
requireRole($authUser, ['admin', 'rh']);

$month = isset($_GET['month']) ? intval($_GET['month']) : intval(date('m'));
$year = isset($_GET['year']) ? intval($_GET['year']) : intval(date('Y'));

$stats = [];

// Total employees
$r = $conn->query("SELECT COUNT(*) as total FROM users WHERE role = 'employee' AND is_active = 1");
$stats['total_employees'] = intval($r->fetch_assoc()['total']);

// Total users
$r = $conn->query("SELECT COUNT(*) as total FROM users WHERE is_active = 1");
$stats['total_users'] = intval($r->fetch_assoc()['total']);

// Pending leave requests
$r = $conn->query("SELECT COUNT(*) as total FROM conges WHERE statut = 'en_attente'");
$stats['conges_en_attente'] = intval($r->fetch_assoc()['total']);

// Approved leaves this month
$r = $conn->query("SELECT COUNT(*) as total FROM conges WHERE statut = 'approuve' AND MONTH(date_debut) = $month AND YEAR(date_debut) = $year");
$stats['conges_approuves_mois'] = intval($r->fetch_assoc()['total']);

// Absences this month
$r = $conn->query("SELECT COUNT(*) as total FROM absences WHERE MONTH(date_absence) = $month AND YEAR(date_absence) = $year");
$stats['absences_mois'] = intval($r->fetch_assoc()['total']);

// Unjustified absences this month
$r = $conn->query("SELECT COUNT(*) as total FROM absences WHERE type_absence = 'injustifiee' AND MONTH(date_absence) = $month AND YEAR(date_absence) = $year");
$stats['absences_injustifiees'] = intval($r->fetch_assoc()['total']);

// Tardiness this month
$r = $conn->query("SELECT COUNT(*) as total FROM retards WHERE MONTH(date_retard) = $month AND YEAR(date_retard) = $year");
$stats['retards_mois'] = intval($r->fetch_assoc()['total']);

// Average tardiness duration
$r = $conn->query("SELECT AVG(duree_minutes) as avg_dur FROM retards WHERE MONTH(date_retard) = $month AND YEAR(date_retard) = $year");
$avg = $r->fetch_assoc()['avg_dur'];
$stats['retard_moyen_minutes'] = $avg ? round(floatval($avg), 1) : 0;

// Pending credit requests
$r = $conn->query("SELECT COUNT(*) as total FROM credits WHERE statut = 'en_attente'");
$stats['credits_en_attente'] = intval($r->fetch_assoc()['total']);

// Total credit amount in progress
$r = $conn->query("SELECT SUM(montant) as total FROM credits WHERE statut IN ('approuve', 'en_cours')");
$total_credits = $r->fetch_assoc()['total'];
$stats['montant_credits_actifs'] = $total_credits ? floatval($total_credits) : 0;

// Department breakdown
$r = $conn->query("SELECT departement, COUNT(*) as count FROM users WHERE role = 'employee' AND is_active = 1 AND departement IS NOT NULL GROUP BY departement ORDER BY count DESC");
$stats['departements'] = [];
while ($row = $r->fetch_assoc()) { $stats['departements'][] = $row; }

// Monthly absence trend (last 6 months)
$stats['absence_trend'] = [];
for ($i = 5; $i >= 0; $i--) {
    $m = date('m', strtotime("-$i months"));
    $y = date('Y', strtotime("-$i months"));
    $r = $conn->query("SELECT COUNT(*) as total FROM absences WHERE MONTH(date_absence) = $m AND YEAR(date_absence) = $y");
    $stats['absence_trend'][] = [
        'month' => date('M Y', strtotime("-$i months")),
        'count' => intval($r->fetch_assoc()['total'])
    ];
}

// Monthly tardiness trend (last 6 months)
$stats['retard_trend'] = [];
for ($i = 5; $i >= 0; $i--) {
    $m = date('m', strtotime("-$i months"));
    $y = date('Y', strtotime("-$i months"));
    $r = $conn->query("SELECT COUNT(*) as total FROM retards WHERE MONTH(date_retard) = $m AND YEAR(date_retard) = $y");
    $stats['retard_trend'][] = [
        'month' => date('M Y', strtotime("-$i months")),
        'count' => intval($r->fetch_assoc()['total'])
    ];
}

// Leave type distribution
$r = $conn->query("SELECT type_conge, COUNT(*) as count FROM conges WHERE YEAR(created_at) = $year GROUP BY type_conge");
$stats['conge_types'] = [];
while ($row = $r->fetch_assoc()) { $stats['conge_types'][] = $row; }

// Top absent employees
$r = $conn->query("SELECT u.nom, u.prenom, u.matricule, COUNT(a.id) as total_absences 
                    FROM absences a JOIN users u ON a.user_id = u.id 
                    WHERE YEAR(a.date_absence) = $year 
                    GROUP BY a.user_id ORDER BY total_absences DESC LIMIT 5");
$stats['top_absents'] = [];
while ($row = $r->fetch_assoc()) { $stats['top_absents'][] = $row; }

sendResponse(["success" => true, "data" => $stats]);
?>
