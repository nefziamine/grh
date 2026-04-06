<?php
require 'c:/xampp/htdocs/Gestion_RH/gestion_rh_api/config/db_connect.php';

$month = intval(date('m'));
$year = intval(date('Y'));
$tz = date_default_timezone_get();

$out = "Current Timezone: $tz\n";
$out .= "Current Date: " . date('Y-m-d H:i:s') . "\n";
$out .= "Current Month: $month\n";
$out .= "Current Year: $year\n";

$r = $conn->query("SELECT COUNT(*) as total FROM absences WHERE MONTH(date_absence) = $month AND YEAR(date_absence) = $year");
$out .= "Absences Count: " . $r->fetch_assoc()['total'] . "\n";

$r = $conn->query("SELECT COUNT(*) as total FROM retards WHERE MONTH(date_retard) = $month AND YEAR(date_retard) = $year");
$out .= "Retards Count (Monthly): " . $r->fetch_assoc()['total'] . "\n";

$r = $conn->query("SELECT COUNT(*) as total FROM conges WHERE statut = 'en_attente'");
$out .= "Congés en attente: " . $r->fetch_assoc()['total'] . "\n";

$r = $conn->query("SELECT COUNT(*) as total FROM credits WHERE statut = 'en_attente'");
$out .= "Crédits en attente: " . $r->fetch_assoc()['total'] . "\n";

$r = $conn->query("SELECT * FROM absences");
while($row = $r->fetch_assoc()) $out .= json_encode($row) . "\n";

$r = $conn->query("SELECT * FROM retards");
while($row = $r->fetch_assoc()) $out .= json_encode($row) . "\n";

file_put_contents('c:/xampp/htdocs/Gestion_RH/gestion_rh_api/query_output.txt', $out);
?>
