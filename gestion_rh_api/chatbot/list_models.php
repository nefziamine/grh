<?php
$apiKey = 'AIzaSyAdoBGhLYAgneCL0NJU3du40nzcs19li_E';
$url = "https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey";
$ch = curl_init($url);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
$res = curl_exec($ch);
$code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

echo "Code: $code\n";
$json = json_decode($res, true);
if (isset($json['models'])) {
    foreach ($json['models'] as $m) {
        echo "- " . $m['name'] . "\n";
    }
} else {
    echo "NO MODELS FOUND or Error: $res\n";
}
?>
