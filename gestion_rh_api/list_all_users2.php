<?php
require_once 'config/db_connect.php';
$result = $conn->query("SELECT id, matricule, nom, prenom, solde_conge FROM users ORDER BY prenom, nom");
echo "All users:\n";
while($row = $result->fetch_assoc()) {
    echo "ID: " . $row['id'] . " | " . $row['prenom'] . " " . $row['nom'] . " | solde: " . $row['solde_conge'] . "\n";
}
?>
