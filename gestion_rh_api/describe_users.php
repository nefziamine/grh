<?php
require_once 'config/db_connect.php';
$result = $conn->query("DESCRIBE users");
while($row = $result->fetch_assoc()) {
    print_r($row);
}
?>
