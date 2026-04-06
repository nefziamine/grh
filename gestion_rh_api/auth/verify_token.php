<?php
require_once __DIR__ . '/../config/db_connect.php';

$authUser = getAuthUser($conn);

sendResponse([
    "success" => true,
    "data" => $authUser
]);
?>
