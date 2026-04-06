<?php
require_once 'config/db_connect.php';
$r = mysqli_query($conn, "SELECT id, matricule, prenom, nom, solde_conge, token FROM users WHERE prenom LIKE 'Marwen' AND nom LIKE 'Saidi'");
while($row = mysqli_fetch_assoc($r)) {
    echo "ID: {$row['id']} | Mat: {$row['matricule']} | Name: {$row['prenom']} {$row['nom']} | Bal: {$row['solde_conge']} | Token: " . ($row['token'] ? "EXISTS" : "NULL") . "\n";
}
?>
