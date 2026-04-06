<?php
require_once 'config/db_connect.php';
$r = mysqli_query($conn, "SELECT id, prenom, nom, solde_conge, token FROM users WHERE prenom='Marwen' AND nom='Saidi'");
while($row = mysqli_fetch_assoc($r)) {
    echo "ID: " . $row['id'] . " | " . $row['prenom'] . " " . $row['nom'] . " | Balance: " . $row['solde_conge'] . " | Token: " . ($row['token'] ? substr($row['token'], 0, 8) . "..." : "NULL") . "\n";
}
?>
