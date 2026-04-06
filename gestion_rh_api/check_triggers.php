<?php
require_once 'config/db_connect.php';
$r = mysqli_query($conn, "SHOW TRIGGERS");
while($row = mysqli_fetch_assoc($r)) {
    print_r($row);
}
?>
