<?php
require_once __DIR__ . '/../config/db_connect.php';

 ini_set('display_errors', '0');
 ini_set('log_errors', '1');
 error_reporting(E_ALL);

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendResponse(["success" => false, "message" => "Méthode non autorisée"], 405);
}

$authUser = getAuthUser($conn);
$userId = intval($authUser['id']);
$userRole = $authUser['role'];
$data = json_decode(file_get_contents("php://input"), true);

if (!isset($data['message']) || empty(trim($data['message']))) {
    sendResponse(["success" => false, "message" => "Message requis"], 400);
}

$userMessage = trim($data['message']);

// Determine whether chatbot_history table exists (avoid fatal error)
$hasChatHistoryTable = false;
try {
    $tRes = $conn->query("SHOW TABLES LIKE 'chatbot_history'");
    if ($tRes && $tRes->num_rows > 0) {
        $hasChatHistoryTable = true;
    }
} catch (Throwable $e) {
    $hasChatHistoryTable = false;
    error_log('Chatbot: failed to check chatbot_history table: ' . $e->getMessage());
}

// 1) Persist message history if table exists; otherwise rely on client-provided history.
$history = [];
if ($hasChatHistoryTable) {
    try {
        // Save user message to database history
        $stmtSave = $conn->prepare("INSERT INTO chatbot_history (user_id, role, message) VALUES (?, 'user', ?)");
        $stmtSave->bind_param("is", $userId, $userMessage);
        $stmtSave->execute();

        // Fetch recent persistent history from DB (source of truth)
        $dbHistory = [];
        $hStmt = $conn->prepare("SELECT role, message FROM chatbot_history WHERE user_id = ? ORDER BY created_at DESC LIMIT 10");
        $hStmt->bind_param("i", $userId);
        $hStmt->execute();
        $hRes = $hStmt->get_result();
        while ($row = $hRes->fetch_assoc()) {
            $dbHistory[] = ['role' => ($row['role'] == 'bot' ? 'model' : 'user'), 'text' => $row['message']];
        }
        $history = array_reverse($dbHistory); // Restore chronological order
        array_pop($history); // Remove the current user message (since it's added separately later)
    } catch (Throwable $e) {
        error_log('Chatbot: history table exists but history operations failed: ' . $e->getMessage());
        $history = [];
        $hasChatHistoryTable = false;
    }
} else {
    // Use history provided by client (Flutter sends it)
    if (isset($data['history']) && is_array($data['history'])) {
        foreach ($data['history'] as $msg) {
            if (is_array($msg) && isset($msg['role']) && isset($msg['text'])) {
                $role = ($msg['role'] === 'model' || $msg['role'] === 'bot') ? 'model' : 'user';
                $history[] = ['role' => $role, 'text' => strval($msg['text'])];
            }
        }
        // Remove current user message if it is last in the provided history
        if (!empty($history)) {
            $last = $history[count($history) - 1];
            if (($last['role'] ?? '') === 'user' && trim($last['text'] ?? '') === $userMessage) {
                array_pop($history);
            }
        }
    }
}

// --- FETCH CONTEXT DATA ---
// 1. Solde Congé
$soldeStmt = $conn->prepare("SELECT solde_conge FROM users WHERE id = ?");
$soldeStmt->bind_param("i", $userId);
$soldeStmt->execute();
$solde = intval($soldeStmt->get_result()->fetch_assoc()['solde_conge'] ?? 0);

// Fetch actual user data to provide real context
$myAbsences = [];
$abStmt = $conn->prepare("SELECT id, date_absence, type_absence, motif FROM absences WHERE user_id = ? ORDER BY date_absence DESC LIMIT 10");
$abStmt->bind_param("i", $userId);
$abStmt->execute();
$abRes = $abStmt->get_result();
while ($r = $abRes->fetch_assoc()) { 
    $status = ($r['motif'] != null && trim($r['motif']) != '') ? "Justifiée" : "⚠️ NON JUSTIFIÉE";
    $myAbsences[] = "- ID:{$r['id']} | Date: {$r['date_absence']} | Type: {$r['type_absence']} | Statut: $status"; 
}

$myCredits = [];
$crStmt = $conn->prepare("SELECT type_credit, montant, statut, created_at FROM credits WHERE user_id = ? ORDER BY id DESC LIMIT 5");
$crStmt->bind_param("i", $userId);
$crStmt->execute();
$crRes = $crStmt->get_result();
while ($r = $crRes->fetch_assoc()) { 
    $st = "⏳ En attente";
    if ($r['statut'] == 'accepte') $st = "✅ Accepté";
    if ($r['statut'] == 'refuse') $st = "❌ Refusé";
    $myCredits[] = "- {$r['type_credit']} {$r['montant']} TND | Statut: $st (Soumis le {$r['created_at']})"; 
}

$myConges = [];
$cngStmt = $conn->prepare("SELECT id, type_conge, date_debut, date_fin, statut, nb_jours FROM conges WHERE user_id = ? ORDER BY date_debut DESC LIMIT 10");
$cngStmt->bind_param("i", $userId);
$cngStmt->execute();
$cngRes = $cngStmt->get_result();
while ($r = $cngRes->fetch_assoc()) {
    $st = "⏳ En attente";
    if ($r['statut'] == 'accepte') $st = "✅ Accepté";
    if ($r['statut'] == 'refuse') $st = "❌ Refusé";
    $myConges[] = "- ID:{$r['id']} | {$r['type_conge']} ({$r['nb_jours']}j) de {$r['date_debut']} au {$r['date_fin']} | Statut: $st";
}

$myRetards = [];
$retLimitStmt = $conn->prepare("SELECT date_retard, heure_arrivee, duree_minutes FROM retards WHERE user_id = ? ORDER BY date_retard DESC LIMIT 10");
$retLimitStmt->bind_param("i", $userId);
$retLimitStmt->execute();
$retRes = $retLimitStmt->get_result();
while ($r = $retRes->fetch_assoc()) {
    $myRetards[] = "- {$r['date_retard']} à {$r['heure_arrivee']} (Durée: {$r['duree_minutes']} min)";
}

// Get TOTAL retards count for policy calculation
$totalRetards = 0;
$countStmt = $conn->prepare("SELECT COUNT(*) as total FROM retards WHERE user_id = ?");
$countStmt->bind_param("i", $userId);
$countStmt->execute();
$totalRetards = intval($countStmt->get_result()->fetch_assoc()['total'] ?? 0);
$impactConges = floor($totalRetards / 5);

// 2. Context for RH or Admin (Global data access)
$rhDataSummary = "";
if ($userRole === 'rh' || $userRole === 'admin') {
    $empStmt = $conn->query("SELECT matricule, nom, prenom FROM users WHERE role = 'employee' AND is_active = 1");
    $emps = [];
    while ($e = $empStmt->fetch_assoc()) {
        $emps[] = "{$e['prenom']} {$e['nom']} (Matricule: {$e['matricule']})";
    }
    
    // Aggregated recent absences for RH (crucial for department questions)
    $absG = [];
    $absStmt = $conn->query("SELECT u.departement, COUNT(*) as total FROM absences a JOIN users u ON a.user_id = u.id WHERE a.date_absence >= DATE_SUB(CURDATE(), INTERVAL 90 DAY) GROUP BY u.departement");
    while ($a = $absStmt->fetch_assoc()) {
        $absG[] = "Dép. {$a['departement']}: {$a['total']} absence(s)";
    }

    $rhDataSummary = "LISTE DES EMPLOYÉS:\n- " . implode("\n- ", $emps) . "\nSTATISTIQUES ABSENCES (3 derniers mois):\n- " . implode("\n- ", $absG);
}

$apiKey = trim('AIzaSyDxFqU5bfTzNQ6Zd_EQWeasYqDeDEwCk78');
$currentDate = date('Y-m-d');

$userName = ($authUser['prenom'] ?? '') . ' ' . ($authUser['nom'] ?? '');
$userDept = $authUser['departement'] ?? 'Non assigné';
$userPoste = $authUser['poste'] ?? 'RH Manager';

$strAbs = empty($myAbsences) ? "Aucune absence enregistrée." : implode("\n", $myAbsences);
$strCr = empty($myCredits) ? "Aucune demande de crédit enregistrée." : implode("\n", $myCredits);
$strCng = empty($myConges) ? "Aucune demande de congé enregistrée." : implode("\n", $myConges);
$strRet = empty($myRetards) ? "Aucun retard enregistré." : implode("\n", $myRetards);

$promptMdPath = realpath(__DIR__ . '/../../HR_Chatbot_System_Prompt.md');
$basePrompt = '';
if ($promptMdPath && is_readable($promptMdPath)) {
    $basePrompt = file_get_contents($promptMdPath);
}

$commonContext = "### CONTEXT DATA:\n" .
    "Utilisateur: $userName | Département: $userDept | Poste: $userPoste\n" .
    "Date actuelle: $currentDate\n\n" .
    "1. SOLDE DE CONGÉ: $solde jours.\n" .
    "2. HISTORIQUE DES DEMANDES DE CONGÉ:\n$strCng\n\n" .
    "3. HISTORIQUE DES ABSENCES:\n$strAbs\n\n" .
    "4. RETARDS:\n$strRet\n\n" .
    "5. DEMANDES DE CRÉDIT:\n$strCr\n";

if ($userRole === 'rh' || $userRole === 'admin') {
    $commonContext .= "\n### RH SUMMARY:\n" . $rhDataSummary . "\n";
}

if (!empty($basePrompt)) {
    $systemPrompt = trim($basePrompt . "\n\n" . $commonContext);
} else {
    $systemPrompt = "Tu es l'assistant intelligent OFFICIEL de la STB Bank. " .
        "Tu AS UN ACCÈS TOTAL ET CONFIDENTIEL aux bases de données RH de la banque. NE DIS JAMAIS « je n'ai pas accès ». \n\n" .
        "TES INFOS (CONTEXTE):\n" .
        "- Utilisateur : $userName\n" .
        "- Poste : $userPoste ($userDept)\n" .
        "- Solde de congé : $solde jours.\n" .
        "- Nombre de retards : $totalRetards (Impact : -$impactConges jours de congé).\n" .
        "- Absences: " . str_replace("\n", ", ", $strAbs) . "\n" .
        "- Crédits: " . str_replace("\n", ", ", $strCr) . "\n\n" .
        "DIRECTIVES :\n" .
        "- RÈGLE DES RETARDS : Chaque série de 5 retards entraîne la retenue d'un jour de congé. Si l'utilisateur demande son nombre de retards ou l'impact sur ses congés, explique cette règle.\n" .
        "- DEMANDE DE CONGÉ : Dès que l'utilisateur veut un congé, EXTRAIS LES DATES et GÉNÈRE : `[ACTION:CREATE_CONGE:{\"type_conge\":\"annuel\",\"date_debut\":\"YYYY-MM-DD\",\"date_fin\":\"YYYY-MM-DD\",\"nb_jours\":X,\"motif\":\"Via Chatbot\"}]`.\n" .
        "- DEMANDE DE CRÉDIT : Dès que l'utilisateur veut un crédit, EXTRAIS LES INFOS et GÉNÈRE : `[ACTION:CREATE_CREDIT:{\"type_credit\":\"...\",\"montant\":X,\"duree_mois\":X,\"motif\":\"Via Chatbot\"}]`.\n" .
        "Aujourd'hui nous sommes le $currentDate.\n" .
        "- Langue : Français.";
}

// Prepare messages for Gemini with alternating roles requirement
$contents = [];
$lastRole = null;

// History is already processed from DB
foreach ($history as $msg) {
    if (isset($msg['role']) && isset($msg['text'])) {
        $role = ($msg['role'] === 'model' || $msg['role'] === 'bot') ? 'model' : 'user';
        
        // Skip or merge if roles repeat (Gemini requires alternation)
        if ($role === $lastRole) {
            if (!empty($contents)) {
                $contents[count($contents)-1]['parts'][0]['text'] .= "\n" . $msg['text'];
            }
            continue;
        }
        
        $contents[] = [
            "role" => $role,
            "parts" => [["text" => $msg['text']]]
        ];
        $lastRole = $role;
    }
}

// Ensure the first message is 'user' and roles alternate 
while (!empty($contents) && $contents[0]['role'] === 'model') {
    array_shift($contents); // Remove initial model messages
}

// PREPEND SYSTEM INSTRUCTION AS FIRST CONTENT (Standard compatibility)
array_unshift($contents, [
    "role" => "user",
    "parts" => [["text" => "SYSTEM_INSTRUCTION : " . $systemPrompt]]
], [
    "role" => "model",
    "parts" => [["text" => "Bien reçu. Je suis prêt à agir en tant qu'assistant STB."]]
]);

// Add current user message (ensuring role alternation)
$lastRole = (empty($contents)) ? null : $contents[count($contents)-1]['role'];
if ($lastRole === 'user') {
    $contents[count($contents)-1]['parts'][0]['text'] .= "\n" . $userMessage;
} else {
    $contents[] = ["role" => "user", "parts" => [["text" => $userMessage]]];
}

$payloadData = [
    "contents" => $contents,
    "generationConfig" => ["temperature" => 0.4]
];

$payload = json_encode($payloadData);

function listGeminiModels($version, $apiKey) {
    $url = "https://generativelanguage.googleapis.com/$version/models?key=$apiKey";
    $ch = curl_init($url);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
    curl_setopt($ch, CURLOPT_CONNECTTIMEOUT, 6);
    curl_setopt($ch, CURLOPT_TIMEOUT, 12);
    $res = curl_exec($ch);
    $code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $error = curl_error($ch);
    curl_close($ch);
    if ($res === false) {
        error_log("Gemini ListModels failed - Version: $version, Error: $error");
        return null;
    }
    if ($code !== 200) {
        error_log("Gemini ListModels HTTP error - Version: $version, HTTP Code: $code, Response: " . substr($res, 0, 500));
        return null;
    }
    $json = json_decode($res, true);
    if (!is_array($json) || !isset($json['models']) || !is_array($json['models'])) {
        return null;
    }
    return $json['models'];
}

function pickBestGeminiModel($apiKey) {
    $cacheFile = sys_get_temp_dir() . DIRECTORY_SEPARATOR . 'stb_gemini_model_cache.json';
    $now = time();
    if (is_file($cacheFile)) {
        $cached = json_decode(@file_get_contents($cacheFile), true);
        if (is_array($cached) && isset($cached['ts'], $cached['model'], $cached['version'])) {
            if (($now - intval($cached['ts'])) < 3600) {
                return ['model' => $cached['model'], 'version' => $cached['version']];
            }
        }
    }

    $versions = ['v1beta', 'v1'];
    $preferred = [
        'gemini-2.5-flash',
        'gemini-2.0-flash',
        'gemini-2.0-flash-lite',
        'gemini-1.5-flash',
        'gemini-1.5-pro',
        'gemini-pro'
    ];

    $candidates = [];
    foreach ($versions as $v) {
        $models = listGeminiModels($v, $apiKey);
        if (!is_array($models)) continue;
        foreach ($models as $m) {
            $name = $m['name'] ?? '';
            if (!is_string($name) || $name === '') continue;
            $methods = $m['supportedGenerationMethods'] ?? [];
            if (!is_array($methods) || !in_array('generateContent', $methods, true)) continue;
            $short = str_starts_with($name, 'models/') ? substr($name, 7) : $name;
            $candidates[] = ['model' => $short, 'version' => $v];
        }
        if (!empty($candidates)) break;
    }

    if (empty($candidates)) {
        error_log('Chatbot: no Gemini models available for this API key (ListModels returned none supporting generateContent).');
        return null;
    }

    $best = null;
    foreach ($preferred as $p) {
        foreach ($candidates as $c) {
            if (stripos($c['model'], $p) !== false) {
                $best = $c;
                break 2;
            }
        }
    }
    if ($best === null) {
        $best = $candidates[0];
    }

    @file_put_contents($cacheFile, json_encode(['ts' => $now, 'model' => $best['model'], 'version' => $best['version']]));
    return $best;
}

function callGemini($m, $k, $p, $preferredVersion = null) {
    // Keep the endpoint fast to avoid Flutter client timeouts.
    // Try the preferred API version first when known (ListModels returns it), then fallback.
    $versions = ['v1beta', 'v1'];
    if (is_string($preferredVersion) && $preferredVersion !== '') {
        $versions = array_values(array_unique(array_merge([$preferredVersion], $versions)));
    }
    foreach ($versions as $v) {
        $url = "https://generativelanguage.googleapis.com/$v/models/$m:generateContent?key=$k";
        $ch = curl_init($url);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
        curl_setopt($ch, CURLOPT_POSTFIELDS, $p);
        curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
        curl_setopt($ch, CURLOPT_CONNECTTIMEOUT, 6);
        curl_setopt($ch, CURLOPT_TIMEOUT, 12);
        $res = curl_exec($ch);
        $code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        $error = curl_error($ch);
        curl_close($ch);

        if ($res === false) {
            error_log("Gemini API curl_exec failed - Model: $m, Version: $v, Error: $error");
            continue;
        }

        if ($code === 200 || $code === 429 || $code === 400 || $code === 401 || $code === 403) {
            return ['res' => $res, 'code' => $code, 'model' => $m, 'version' => $v];
        }

        error_log("Gemini API Error - Model: $m, Version: $v, HTTP Code: $code, Error: $error, Response: " . substr($res, 0, 500));
    }
    return ['res' => '', 'code' => 0, 'model' => $m, 'version' => 'failed'];
}

$finalResponse = null;
$resp = null;

$picked = pickBestGeminiModel($apiKey);
if (is_array($picked) && isset($picked['model'])) {
    $preferredV = $picked['version'] ?? null;
    $resp = callGemini($picked['model'], $apiKey, $payload, $preferredV);
    if ($resp['code'] === 200) {
        $finalResponse = $resp;
    }
}

// If ListModels cannot find any usable model for this key, don't spam generateContent with hardcoded models.
// We'll fall back to a clean "service unavailable" message below.

$httpCode = $finalResponse['code'] ?? ($resp['code'] ?? 0);
$result = $finalResponse['res'] ?? ($resp['res'] ?? '');

$aiResponse = "";
if ($httpCode === 200) {
    $json = json_decode($result, true);
    if (isset($json['candidates'][0]['content']['parts'][0]['text'])) {
        $aiResponse = trim($json['candidates'][0]['content']['parts'][0]['text']);
        
        // Save AI response to database history only if table exists
        if ($hasChatHistoryTable) {
            try {
                $stmtSaveBot = $conn->prepare("INSERT INTO chatbot_history (user_id, role, message) VALUES (?, 'bot', ?)");
                $stmtSaveBot->bind_param("is", $userId, $aiResponse);
                $stmtSaveBot->execute();
            } catch (Throwable $e) {
                error_log('Chatbot: failed to save bot message: ' . $e->getMessage());
            }
        }
    }
}

if (empty($aiResponse)) {
    if ($httpCode === 429) {
        $aiResponse = "⚠️ Le service est temporairement saturé (quota dépassé). Veuillez réessayer plus tard ou contacter l'administrateur. ⏳";
    } else if ($httpCode === 400) {
        $aiResponse = "❌ Clé API invalide. Veuillez contacter l'administrateur.";
    } else if ($httpCode === 401 || $httpCode === 403) {
        $aiResponse = "❌ Accès non autorisé au service IA. Veuillez contacter l'administrateur.";
    } else if ($result === false) {
        $aiResponse = "❌ Erreur de connexion au serveur IA.";
    } else if ($httpCode === 0) {
        $aiResponse = "❌ Impossible de contacter le service IA. Veuillez réessayer.";
    } else {
        $aiResponse = "❌ Une erreur s'est produite ($httpCode). Détails : " . substr($result, 0, 200) . "... Veuillez réessayer plus tard.";
    }
}

// --- POST-PROCESSING ---
$finalMessage = $aiResponse;
$actionExecuted = false;
$actionStatus = "";

// 1. Handle Congé
if (preg_match('/\[ACTION:CREATE_CONGE:(.*?)\]/', $aiResponse, $matches)) {
    $actionData = json_decode($matches[1], true);
    if ($actionData) {
        $stmt = $conn->prepare("INSERT INTO conges (user_id, type_conge, date_debut, date_fin, nb_jours, motif) VALUES (?, ?, ?, ?, ?, ?)");
        if ($stmt) {
            $stmt->bind_param("isssis", $userId, $actionData['type_conge'], $actionData['date_debut'], $actionData['date_fin'], $actionData['nb_jours'], $actionData['motif']);
            if ($stmt->execute()) {
                $actionExecuted = true;
                $actionStatus = "\n\n✅ Demande de congé enregistrée !";
            }
        }
    }
    $finalMessage = trim(str_replace($matches[0], '', $finalMessage)) . $actionStatus;
}

// 1.1 Handle Absence Justification
if (preg_match('/\[ACTION:JUSTIFY_ABSENCE:(.*?)\]/', $aiResponse, $matches)) {
    $actionData = json_decode($matches[1], true);
    if ($actionData && isset($actionData['id']) && isset($actionData['motif'])) {
        $absId = intval($actionData['id']);
        $stmt = $conn->prepare("UPDATE absences SET motif = ? WHERE id = ? AND user_id = ?");
        if ($stmt) {
            $stmt->bind_param("sii", $actionData['motif'], $absId, $userId);
            if ($stmt->execute()) {
                $actionExecuted = true;
                $actionStatus = "\n\n✅ Justification de l'absence (ID:$absId) enregistrée !";
            }
        }
    }
    $finalMessage = trim(str_replace($matches[0], '', $finalMessage)) . $actionStatus;
}

// 1.2 Handle Credit Request
if (preg_match('/\[ACTION:CREATE_CREDIT:(.*?)\]/', $aiResponse, $matches)) {
    $actionData = json_decode($matches[1], true);
    if ($actionData && isset($actionData['type_credit']) && isset($actionData['montant'])) {
        $type = $actionData['type_credit'];
        $amt = floatval($actionData['montant']);
        $dur = intval($actionData['duree_mois'] ?? 12);
        $motif = $actionData['motif'] ?? 'Via Chatbot';
        
        $stmt = $conn->prepare("INSERT INTO credits (user_id, type_credit, montant, duree_mois, motif) VALUES (?, ?, ?, ?, ?)");
        if ($stmt) {
            $stmt->bind_param("isdis", $userId, $type, $amt, $dur, $motif);
            if ($stmt->execute()) {
                $actionExecuted = true;
                $actionStatus = "\n\n✅ Demande de crédit enregistrée !";
            }
        }
    }
    $finalMessage = trim(str_replace($matches[0], '', $finalMessage)) . $actionStatus;
}

// 2. Handle Absence (RH only)
if ($userRole === 'rh' && preg_match('/\[ACTION:CREATE_ABSENCE:(.*?)\]/', $aiResponse, $matches)) {
    $actionData = json_decode($matches[1], true);
    if ($actionData) {
        $m = $actionData['matricule'];
        $uStmt = $conn->prepare("SELECT id FROM users WHERE matricule = ?");
        $uStmt->bind_param("s", $m);
        $uStmt->execute();
        $res = $uStmt->get_result()->fetch_assoc();
        $targetId = $res['id'] ?? null;
        
        if ($targetId) {
            $stmt = $conn->prepare("INSERT INTO absences (user_id, date_absence, type_absence, motif) VALUES (?, ?, ?, ?)");
            $stmt->bind_param("isss", $targetId, $actionData['date'], $actionData['type'], $actionData['motif']);
            if ($stmt->execute()) {
                $actionExecuted = true;
                $actionStatus = "\n\n✅ Absence de l'employé ($m) enregistrée !";
            } else {
                $actionStatus = "\n\n❌ Erreur lors de l'enregistrement de l'absence.";
            }
        } else {
            $actionStatus = "\n\n❌ Employé avec le matricule $m non trouvé.";
        }
    }
    $finalMessage = trim(str_replace($matches[0], '', $finalMessage)) . $actionStatus;
}

// 3. Handle Retard (RH only)
if ($userRole === 'rh' && preg_match('/\[ACTION:CREATE_RETARD:(.*?)\]/', $aiResponse, $matches)) {
    $actionData = json_decode($matches[1], true);
    if ($actionData) {
        $m = $actionData['matricule'];
        $uStmt = $conn->prepare("SELECT id FROM users WHERE matricule = ?");
        $uStmt->bind_param("s", $m);
        $uStmt->execute();
        $res = $uStmt->get_result()->fetch_assoc();
        $targetId = $res['id'] ?? null;
        
        if ($targetId) {
            $stmt = $conn->prepare("INSERT INTO retards (user_id, date_retard, heure_arrivee, duree_minutes, motif) VALUES (?, ?, ?, ?, ?)");
            $stmt->bind_param("isssis", $targetId, $actionData['date'], $actionData['heure'], $actionData['duree'], $actionData['motif']);
            if ($stmt->execute()) {
                $actionExecuted = true;
                $actionStatus = "\n\n✅ Retard de l'employé ($m) enregistré !";
                
                // Add notification
                $notifStmt = $conn->prepare("INSERT INTO notifications (user_id, titre, message, type_notif) VALUES (?, 'Retard enregistré', ?, 'retard')");
                $msg = "Un retard de " . $actionData['duree'] . " minutes a été enregistré le " . $actionData['date'];
                $notifStmt->bind_param("is", $targetId, $msg);
                $notifStmt->execute();
            } else {
                $actionStatus = "\n\n❌ Erreur lors de l'enregistrement du retard.";
            }
        } else {
            $actionStatus = "\n\n❌ Employé avec le matricule $m non trouvé.";
        }
    }
    $finalMessage = trim(str_replace($matches[0], '', $finalMessage)) . $actionStatus;
}

sendResponse([
    "success" => true,
    "data" => ["response" => $finalMessage, "action_executed" => $actionExecuted, "timestamp" => date('Y-m-d H:i:s')]
]);
?>