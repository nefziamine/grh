<?php
$apiKey = 'AIzaSyAdoBGhLYAgneCL0NJU3du40nzcs19li_E';
$models = ['gemini-1.5-flash', 'gemini-1.5-pro', 'gemini-pro', 'gemini-1.5-flash-8b'];
echo "Testing Models...\n\n";

foreach (['v1', 'v1beta'] as $v) {
    foreach ($models as $m) {
        $url = "https://generativelanguage.googleapis.com/$v/models/$m:generateContent?key=$apiKey";
        $payload = json_encode(["contents" => [["parts" => [["text" => "hi"]]]]]);
        
        $ch = curl_init($url);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
        curl_setopt($ch, CURLOPT_POSTFIELDS, $payload);
        curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
        $res = curl_exec($ch);
        $code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);
        
        echo "[$v] $m: $code\n";
        if ($code !== 200) {
            $err = json_decode($res, true);
            echo "Msg: " . ($err['error']['message'] ?? 'Unknown') . "\n";
        } else {
            echo "SUCCESS!\n";
        }
        echo "-------------------\n";
    }
}
?>
