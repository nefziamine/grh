<?php
require_once 'config/db_connect.php';
$r = mysqli_query($conn, 'SELECT id, prenom, nom, solde_conge FROM users');
while($row = mysqli_fetch_assoc($r)) {
    echo "ID: {$row['id']} | Name: {$row['prenom']} {$row['nom']} | Balance: {$row['solde_conge']}\n";
}
?>
