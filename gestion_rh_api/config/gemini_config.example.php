<?php

/**
 * Copy this file to gemini_config.php and add your Gemini API keys.
 * Keys are tried in order until one succeeds (quota/errors trigger fallback).
 */
function getGeminiApiKeys(): array {
    $keys = [
        'YOUR_GEMINI_API_KEY_PRIMARY',
        'YOUR_GEMINI_API_KEY_FALLBACK',
    ];

    return array_values(array_unique(array_filter(array_map('trim', $keys))));
}

function shouldTryNextGeminiKey(int $httpCode): bool {
    return in_array($httpCode, [0, 400, 401, 403, 429], true);
}
