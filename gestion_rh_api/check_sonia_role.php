<?php
require_once 'config/db_connect.php';
$result = $conn->query("SELECT id, nom, prenom, role FROM users WHERE id=107");
$row = $result->fetch_assoc();
echo "ID: " . $row['id'] . " | " . $row['prenom'] . " " . $row['nom'] . " | Role: " . $row['role'] . "\n";
?>
