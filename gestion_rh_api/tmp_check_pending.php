<?php
require 'c:/xampp/htdocs/Gestion_RH/gestion_rh_api/config/db_connect.php';

$sql = "SELECT id, user_id, type_conge, statut FROM conges WHERE statut = 'en_attente'";
$res = $conn->query($sql);
while($row = $res->fetch_assoc()) {
    print_r($row);
}
?>
