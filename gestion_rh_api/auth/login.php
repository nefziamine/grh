<?php
require_once __DIR__ . '/../config/db_connect.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendResponse(["success" => false, "message" => "Méthode non autorisée"], 405);
}

$data = json_decode(file_get_contents("php://input"), true);

if (!isset($data['matricule']) || !isset($data['password'])) {
    sendResponse(["success" => false, "message" => "Matricule et mot de passe requis"], 400);
}

$matricule = $conn->real_escape_string($data['matricule']);
$password = $data['password'];

$stmt = $conn->prepare("SELECT id, matricule, email, password_hash, role, nom, prenom, telephone, departement, poste, date_embauche, solde_conge, avatar, is_active FROM users WHERE matricule = ?");
$stmt->bind_param("s", $matricule);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows === 0) {
    sendResponse(["success" => false, "message" => "Matricule ou mot de passe incorrect"], 401);
}

$user = $result->fetch_assoc();

if (!$user['is_active']) {
    sendResponse(["success" => false, "message" => "Compte désactivé. Contactez l'administrateur."], 403);
}

if (!password_verify($password, $user['password_hash'])) {
    sendResponse(["success" => false, "message" => "Matricule ou mot de passe incorrect"], 401);
}

// Generate token
$token = bin2hex(random_bytes(32));
$expiry = date('Y-m-d H:i:s', strtotime('+7 days'));

$stmt = $conn->prepare("UPDATE users SET token = ?, token_expiry = ? WHERE id = ?");
$stmt->bind_param("ssi", $token, $expiry, $user['id']);
$stmt->execute();

unset($user['password_hash']);
$user['token'] = $token;

if (isset($user['solde_conge'])) {
    $user['solde_conge'] = round($user['solde_conge'] / 24, 1);
}

sendResponse([
    "success" => true,
    "message" => "Connexion réussie",
    "data" => $user
]);
?>
