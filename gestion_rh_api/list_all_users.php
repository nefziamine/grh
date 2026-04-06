<?php
require_once 'config/db_connect.php';
$result = $conn->query("SELECT id, matricule, nom, prenom, role FROM users");
while($row = $result->fetch_assoc()) {
    echo "ID: " . $row['id'] . " | " . $row['prenom'] . " " . $row['nom'] . " | Role: " . $row['role'] . "\n";
}
?>
