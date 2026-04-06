<?php
require_once __DIR__ . '/../config/db_connect.php';

$apiKey = trim('AIzaSyAdoBGhLYAgneCL0NJU3du40nzcs19li_E');
$model = 'gemini-2.5-flash';
$url = "https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey";

$payload = json_encode([
    "contents" => [[
        "parts" => [["text" => "Réponds par 'OK' si tu reçois ce message."]]
    ]]
]);

$ch = curl_init($url);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
curl_setopt($ch, CURLOPT_POSTFIELDS, $payload);
curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);

$res = curl_exec($ch);
$code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$error = curl_error($ch);
curl_close($ch);

echo json_encode([
    "http_code" => $code,
    "response" => json_decode($res, true),
    "curl_error" => $error
], JSON_PRETTY_PRINT);
?>
