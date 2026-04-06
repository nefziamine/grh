<?php
require_once __DIR__ . '/../config/db_connect.php';

// List all documents
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    getAuthUser($conn); // Optional: add auth if necessary

    $sql = "SELECT * FROM documents ORDER BY created_at DESC";
    $result = $conn->query($sql);
    $docs = [];
    while ($row = $result->fetch_assoc()) {
        $docs[] = $row;
    }

    sendResponse(["success" => true, "data" => $docs]);
} else {
    sendResponse(["success" => false, "message" => "Méthode non autorisée"], 405);
}
?>
