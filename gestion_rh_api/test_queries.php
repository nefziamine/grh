<?php
require 'c:/xampp/htdocs/Gestion_RH/gestion_rh_api/config/db_connect.php';

$month = intval(date('m'));
$year = intval(date('Y'));

echo "Current Month: $month\n";
echo "Current Year: $year\n";

$r = $conn->query("SELECT COUNT(*) as total FROM absences WHERE MONTH(date_absence) = $month AND YEAR(date_absence) = $year");
echo "Absences Count: " . $r->fetch_assoc()['total'] . "\n";

$r = $conn->query("SELECT COUNT(*) as total FROM retards WHERE MONTH(date_retard) = $month AND YEAR(date_retard) = $year");
echo "Retards Count: " . $r->fetch_assoc()['total'] . "\n";

$r = $conn->query("SELECT COUNT(*) as total FROM conges WHERE statut = 'en_attente'");
echo "Congés en attente: " . $r->fetch_assoc()['total'] . "\n";

$r = $conn->query("SELECT * FROM absences");
echo "All Absences:\n";
while($row = $r->fetch_assoc()) print_r($row);

$r = $conn->query("SELECT * FROM retards");
echo "All Retards:\n";
while($row = $r->fetch_assoc()) print_r($row);
?>
