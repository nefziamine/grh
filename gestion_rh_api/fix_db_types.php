<?php
require 'c:/xampp/htdocs/Gestion_RH/gestion_rh_api/config/db_connect.php';

$sql = "ALTER TABLE users MODIFY solde_conge DECIMAL(10,2) DEFAULT 30.00";
if($conn->query($sql)) {
    echo "Solde_conge modified to DECIMAL(10,2) successfully.\n";
} else {
    echo "Error: " . $conn->error . "\n";
}
?>
