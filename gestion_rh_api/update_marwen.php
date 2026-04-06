<?php
require_once 'config/db_connect.php';
$r = mysqli_query($conn, "UPDATE users SET solde_conge=30.00 WHERE id=95");
if ($r) echo "Update success for user ID 95\n"; else echo "Update failed\n";
?>
