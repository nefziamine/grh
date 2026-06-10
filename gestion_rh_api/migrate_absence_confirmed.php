<?php
require_once __DIR__ . '/config/db_connect.php';

$queries = [
    "ALTER TABLE absences ADD COLUMN is_confirmed TINYINT(1) NOT NULL DEFAULT 1",
    "ALTER TABLE retards ADD COLUMN is_confirmed TINYINT(1) NOT NULL DEFAULT 1",
];

$results = [];
foreach ($queries as $sql) {
    if ($conn->query($sql)) {
        $results[] = ['sql' => $sql, 'status' => 'ok'];
    } else {
        $results[] = ['sql' => $sql, 'status' => 'skip', 'error' => $conn->error];
    }
}

sendResponse(['success' => true, 'message' => 'Migration terminée', 'results' => $results]);
