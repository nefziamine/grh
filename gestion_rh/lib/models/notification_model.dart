class NotificationModel {
  final int id;
  final int userId;
  final String titre;
  final String message;
  final String typeNotif;
  final bool isRead;
  final String? createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.titre,
    required this.message,
    required this.typeNotif,
    required this.isRead,
    this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      userId: int.tryParse(json['user_id'].toString()) ?? 0,
      titre: json['titre'] ?? '',
      message: json['message'] ?? '',
      typeNotif: json['type_notif'] ?? 'system',
      isRead: json['is_read'] == '1' || json['is_read'] == 1 || json['is_read'] == true,
      createdAt: json['created_at'],
    );
  }
}
