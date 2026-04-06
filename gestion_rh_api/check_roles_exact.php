<?php
require_once 'config/db_connect.php';
$result = $conn->query("SELECT id, prenom, nom, role FROM users WHERE id IN (18, 107)");
while($row = $result->fetch_assoc()) {
    echo "ID: " . $row['id'] . " | Name: " . $row['prenom'] . " " . $row['nom'] . " | Role: [" . $row['role'] . "]\n";
}
?>
