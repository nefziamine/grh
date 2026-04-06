<?php
require_once __DIR__ . '/../config/db_connect.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendResponse(["success" => false, "message" => "Méthode non autorisée"], 405);
}

$authUser = getAuthUser($conn);
requireRole($authUser, ['admin', 'rh']);

$data = json_decode(file_get_contents("php://input"), true);

$required = ['matricule', 'email', 'password', 'nom', 'prenom', 'role'];
foreach ($required as $field) {
    if (!isset($data[$field]) || empty($data[$field])) {
        sendResponse(["success" => false, "message" => "Champ requis manquant: $field"], 400);
    }
}

// Check uniqueness
$stmt = $conn->prepare("SELECT id FROM users WHERE matricule = ? OR email = ?");
$stmt->bind_param("ss", $data['matricule'], $data['email']);
$stmt->execute();
if ($stmt->get_result()->num_rows > 0) {
    sendResponse(["success" => false, "message" => "Matricule ou email déjà existant"], 409);
}

$password_hash = password_hash($data['password'], PASSWORD_DEFAULT);

$stmt = $conn->prepare("INSERT INTO users (matricule, email, password_hash, role, nom, prenom, telephone, departement, poste, date_embauche, adresse, solde_conge) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");
$telephone = $data['telephone'] ?? '';
$departement = $data['departement'] ?? '';
$poste = $data['poste'] ?? '';
$date_embauche = $data['date_embauche'] ?? date('Y-m-d');
$adresse = $data['adresse'] ?? '';
$solde_conge = $data['solde_conge'] ?? 30;

$stmt->bind_param("sssssssssssi",
    $data['matricule'], $data['email'], $password_hash, $data['role'],
    $data['nom'], $data['prenom'], $telephone, $departement,
    $poste, $date_embauche, $adresse, $solde_conge
);

if ($stmt->execute()) {
    $newId = $conn->insert_id;
    
    // Create welcome notification
    $notifStmt = $conn->prepare("INSERT INTO notifications (user_id, titre, message, type_notif) VALUES (?, 'Bienvenue', 'Bienvenue sur la plateforme Gestion RH de la STB.', 'system')");
    $notifStmt->bind_param("i", $newId);
    $notifStmt->execute();
    
    sendResponse(["success" => true, "message" => "Employé créé avec succès", "id" => $newId], 201);
} else {
    sendResponse(["success" => false, "message" => "Erreur lors de la création: " . $stmt->error], 500);
}
?>
