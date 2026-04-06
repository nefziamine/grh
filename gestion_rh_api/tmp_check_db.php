<?php
require 'c:/xampp/htdocs/Gestion_RH/gestion_rh_api/config/db_connect.php';

echo "--- Users ---\n";
$sql = "SELECT id, prenom, nom, role, email FROM users WHERE prenom LIKE '%Marwen%' OR nom LIKE '%saidi%'";
$res = $conn->query($sql);
while($row = $res->fetch_assoc()) {
    print_r($row);
}

echo "\n--- Retards ---\n";
$sql = "SELECT r.*, u.prenom, u.nom FROM retards r JOIN users u ON r.user_id = u.id WHERE u.prenom LIKE '%Marwen%' OR u.nom LIKE '%saidi%'";
$res = $conn->query($sql);
while($row = $res->fetch_assoc()) {
    print_r($row);
}

echo "\n--- Absences ---\n";
$sql = "SELECT a.*, u.prenom, u.nom FROM absences a JOIN users u ON a.user_id = u.id WHERE u.prenom LIKE '%Marwen%' OR u.nom LIKE '%saidi%'";
$res = $conn->query($sql);
while($row = $res->fetch_assoc()) {
    print_r($row);
}
?>
