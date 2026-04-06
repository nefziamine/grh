<?php
require 'c:/xampp/htdocs/Gestion_RH/gestion_rh_api/config/db_connect.php';

$sql = "SELECT * FROM retards";
$res = $conn->query($sql);
while($row = $res->fetch_assoc()) {
    print_r($row);
}
?>
