<?php
require_once __DIR__ . '/../config/db_connect.php';

$authUser = getAuthUser($conn);

$id = isset($_GET['id']) ? intval($_GET['id']) : 0;

// Employees can only read their own profile
if ($authUser['role'] === 'employee' && $id !== intval($authUser['id'])) {
    $id = intval($authUser['id']);
}

if ($id === 0) {
    $id = intval($authUser['id']);
}

$stmt = $conn->prepare("SELECT id, matricule, email, role, nom, prenom, telephone, departement, poste, date_embauche, adresse, solde_conge, avatar, is_active, created_at FROM users WHERE id = ?");
$stmt->bind_param("i", $id);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows === 0) {
    sendResponse(["success" => false, "message" => "Employé non trouvé"], 404);
}

$user = $result->fetch_assoc();
if (isset($user['solde_conge'])) {
    $user['solde_conge'] = round($user['solde_conge'] / 24, 1);
}

sendResponse([
    "success" => true,
    "data" => $user
]);
?>
