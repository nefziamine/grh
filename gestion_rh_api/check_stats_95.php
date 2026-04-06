<?php
require_once 'config/db_connect.php';
$id = 95;
$res = mysqli_query($conn, "SELECT SUM(nb_jours) as total FROM conges WHERE user_id=$id AND statut='accepte'");
$taken = mysqli_fetch_assoc($res)['total'] ?? 0;
$res = mysqli_query($conn, "SELECT solde_conge FROM users WHERE id=$id");
$solde = mysqli_fetch_assoc($res)['solde_conge'] ?? 0;
echo "User ID: $id | Current Solde: $solde | Taken Conges: $taken\n";
?>
