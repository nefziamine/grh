<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");
header("Content-Type: application/json; charset=UTF-8");
date_default_timezone_set('Africa/Tunis');

if (isset($_SERVER['REQUEST_METHOD']) && $_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

$host = "localhost";
$db_name = "gestion_rh";
$username = "root";
$password = "";

$conn = new mysqli($host, $username, $password, $db_name);

if ($conn->connect_error) {
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Database connection failed: " . $conn->connect_error]);
    exit();
}

$conn->set_charset("utf8mb4");

// Helper: get authenticated user from token
function getAuthUser($conn) {
    $headers = getallheaders();
    $token = null;
    
    if (isset($headers['Authorization'])) {
        $token = str_replace('Bearer ', '', $headers['Authorization']);
    }
    
    if (!$token) {
        http_response_code(401);
        echo json_encode(["success" => false, "message" => "Token manquant"]);
        exit();
    }
    
    $stmt = $conn->prepare("SELECT id, matricule, email, role, nom, prenom, departement, poste FROM users WHERE token = ? AND token_expiry > NOW() AND is_active = 1");
    $stmt->bind_param("s", $token);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows === 0) {
        http_response_code(401);
        echo json_encode(["success" => false, "message" => "Token invalide ou expiré"]);
        exit();
    }
    
    return $result->fetch_assoc();
}

// Helper: require specific role
function requireRole($user, $roles) {
    if (!in_array($user['role'], $roles)) {
        http_response_code(403);
        echo json_encode(["success" => false, "message" => "Accès non autorisé"]);
        exit();
    }
}

// Helper: send JSON response
function sendResponse($data, $code = 200) {
    http_response_code($code);
    echo json_encode($data, JSON_UNESCAPED_UNICODE);
    exit();
}
?>
