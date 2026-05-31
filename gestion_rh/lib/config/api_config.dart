import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  // 10.0.2.2 est l'adresse IP spéciale qui redirige vers le "localhost" de votre PC depuis l'émulateur Android.
  static String get baseUrl {
    // 192.168.1.178 est l'adresse IPv4 de votre PC sur le réseau local.
    // L'émulateur Android peut utiliser 10.0.2.2, mais pour un vrai téléphone, on utilise l'IP WiFi.
    if (kIsWeb) return 'http://localhost/Gestion_RH1/gestion_rh_api';
    return 'http://192.168.1.178/Gestion_RH1/gestion_rh_api';
  }

  // Auth
  static String get login => '$baseUrl/auth/login.php';
  static String get verifyToken => '$baseUrl/auth/verify_token.php';

  // Employees
  static String get employeeList => '$baseUrl/employees/list.php';
  static String get employeeRead => '$baseUrl/employees/read.php';
  static String get employeeCreate => '$baseUrl/employees/create.php';
  static String get employeeUpdate => '$baseUrl/employees/update.php';
  static String get employeeDelete => '$baseUrl/employees/delete.php';

  // Congés
  static String get congeList => '$baseUrl/conges/list.php';
  static String get congeCreate => '$baseUrl/conges/create.php';
  static String get congeUpdateStatus => '$baseUrl/conges/update_status.php';
  static String get congeDelete => '$baseUrl/conges/delete.php';
  static String get myConges => '$baseUrl/conges/my_conges.php';

  // Absences
  static String get absenceList => '$baseUrl/absences/list.php';
  static String get absenceCreate => '$baseUrl/absences/create.php';
  static String get myAbsences => '$baseUrl/absences/my_absences.php';

  // Retards
  static String get retardList => '$baseUrl/retards/list.php';
  static String get retardCreate => '$baseUrl/retards/create.php';
  static String get myRetards => '$baseUrl/retards/my_retards.php';

  // Credits
  static String get creditList => '$baseUrl/credits/list.php';
  static String get creditCreate => '$baseUrl/credits/create.php';
  static String get creditUpdateStatus => '$baseUrl/credits/update_status.php';
  static String get creditDelete => '$baseUrl/credits/delete.php';
  static String get creditCheckEligibility =>
      '$baseUrl/credits/check_eligibility.php';
  static String get myCredits => '$baseUrl/credits/my_credits.php';

  // Notifications
  static String get notificationList => '$baseUrl/notifications/list.php';
  static String get notificationCreate => '$baseUrl/notifications/create.php';
  static String get notificationMarkRead =>
      '$baseUrl/notifications/mark_read.php';
  static String get notificationDelete => '$baseUrl/notifications/delete.php';

  // Dashboard
  static String get dashboardStats => '$baseUrl/dashboard/stats.php';

  // Chatbot
  static String get chatbot => '$baseUrl/chatbot/chat.php';

  // Pointages (Digital Check-in)
  static String get pointageCreate => '$baseUrl/pointages/create.php';
  static String get pointageList => '$baseUrl/pointages/list.php';
  static String get pointageVerify => '$baseUrl/pointages/verify.php';
  static String get pointageGenerateAbsences =>
      '$baseUrl/pointages/generate_absences.php';

  // Documents
  static String get documentList => '$baseUrl/documents/list.php';
  static String get documentCreate => '$baseUrl/documents/create.php';
}
