<?php
require_once 'config/db_connect.php';
$search = "Sonia";
$result = $conn->query("SELECT id, matricule, nom, prenom, role FROM users WHERE prenom LIKE '%$search%' OR nom LIKE '%$search%'");
while($row = $result->fetch_assoc()) {
    echo "ID: " . $row['id'] . " | " . $row['prenom'] . " " . $row['nom'] . " | Role: " . $row['role'] . "\n";
}
?>
