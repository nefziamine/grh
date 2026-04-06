<?php
require_once 'config/db_connect.php';
$r = mysqli_query($conn, "SELECT id, prenom, nom, solde_conge FROM users WHERE prenom LIKE '%Marwen%'");
while($row = mysqli_fetch_assoc($r)) {
    print_r($row);
}
?>
