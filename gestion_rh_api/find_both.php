<?php
require_once 'config/db_connect.php';
$result = $conn->query("SELECT id, nom, prenom, email FROM users WHERE (prenom LIKE '%Sonia%' AND nom LIKE '%Abid%') OR (prenom LIKE '%Nader%' AND nom LIKE '%Saidi%')");
while($row = $result->fetch_assoc()) {
    echo "ID: " . $row['id'] . " | Name: " . $row['prenom'] . " " . $row['nom'] . " | Email: " . $row['email'] . "\n";
}
?>
