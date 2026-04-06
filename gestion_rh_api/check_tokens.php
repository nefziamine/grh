<?php
require_once 'config/db_connect.php';
$result = $conn->query("SELECT id, nom, prenom, token FROM users WHERE id IN (18, 107)");
while($row = $result->fetch_assoc()) {
    echo "ID: " . $row['id'] . " | " . $row['prenom'] . " " . $row['nom'] . " | Token: " . ($row['token'] ?? 'NULL') . "\n";
}
?>
