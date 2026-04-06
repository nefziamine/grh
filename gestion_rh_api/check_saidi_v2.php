<?php
require_once 'config/db_connect.php';
$r = mysqli_query($conn, "SELECT id, matricule, prenom, nom, solde_conge, token FROM users WHERE prenom LIKE '%Marwen%' AND nom LIKE '%Saidi%'");
while($row = mysqli_fetch_assoc($r)) {
    print_r($row);
}
?>
