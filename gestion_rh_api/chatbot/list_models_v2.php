<?php
$apiKey = 'AIzaSyAdoBGhLYAgneCL0NJU3du40nzcs19li_E';
$url = "https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey";
$ch = curl_init($url);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
$res = curl_exec($ch);
curl_close($ch);
file_put_contents('models_full.json', $res);
echo "Full models list saved to models_full.json\n";
?>
