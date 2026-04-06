import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/stb_theme.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';
import '../../models/notification_model.dart';

class EmployeeNotifications extends StatefulWidget {
  const EmployeeNotifications({super.key});

  @override
  State<EmployeeNotifications> createState() => _EmployeeNotificationsState();
}

class _EmployeeNotificationsState extends State<EmployeeNotifications> {
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    final result = await ApiService.get(ApiConfig.notificationList);
    if (result['success'] == true && mounted) {
      setState(() {
        _notifications = (result['data'] as List).map((e) => NotificationModel.fromJson(e)).toList();
        _isLoading = false;
      });
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAllRead() async {
    await ApiService.post(ApiConfig.notificationMarkRead, {'all': true});
    _loadNotifications();
  }

  Future<void> _markRead(int id) async {
    await ApiService.post(ApiConfig.notificationMarkRead, {'id': id});
    _loadNotifications();
  }

  Future<void> _deleteNotification(int id) async {
    final result = await ApiService.post(ApiConfig.notificationDelete, {'id': id});
    if (result['success'] == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notification supprimée')));
      _loadNotifications();
    }
  }

  Future<void> _deleteAllNotifications() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Supprimer toutes les notifications'),
        content: const Text('Êtes-vous sûr de vouloir tout supprimer ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Supprimer', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      final result = await ApiService.post(ApiConfig.notificationDelete, {'all': true});
      if (result['success'] == true && mounted) {
        _loadNotifications();
      }
    }
  }

  IconData _getNotifIcon(String type) {
    switch (type) {
      case 'conge': return Icons.calendar_today;
      case 'absence': return Icons.person_off;
      case 'retard': return Icons.schedule;
      case 'credit': return Icons.account_balance;
      case 'message': return Icons.email;
      default: return Icons.notifications;
    }
  }

  Color _getNotifColor(String type) {
    switch (type) {
      case 'conge': return STBColors.primaryBlue;
      case 'absence': return STBColors.danger;
      case 'retard': return STBColors.warning;
      case 'credit': return STBColors.primaryGreen;
      default: return STBColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            onPressed: _deleteAllNotifications,
            icon: const Icon(Icons.delete_sweep_outlined, color: Colors.white),
            tooltip: 'Tout supprimer',
          ),
          TextButton(
            onPressed: _markAllRead,
            child: Text('Tout lire', style: GoogleFonts.inter(color: Colors.white, fontSize: 13)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadNotifications,
              child: _notifications.isEmpty
                  ? Center(child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_none, size: 60, color: STBColors.textSecondary.withValues(alpha: 0.3)),
                        const SizedBox(height: 12),
                        Text('Aucune notification', style: GoogleFonts.inter(color: STBColors.textSecondary)),
                      ],
                    ))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _notifications.length,
                      itemBuilder: (c, i) {
                        final notif = _notifications[i];
                        return GestureDetector(
                          onTap: () => notif.isRead ? null : _markRead(notif.id),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: notif.isRead ? STBColors.white : STBColors.primaryBlue.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(14),
                              border: notif.isRead ? null : Border.all(color: STBColors.primaryBlue.withValues(alpha: 0.2)),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6)],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: _getNotifColor(notif.typeNotif).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(_getNotifIcon(notif.typeNotif), color: _getNotifColor(notif.typeNotif), size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(notif.titre, style: GoogleFonts.inter(fontSize: 14, fontWeight: notif.isRead ? FontWeight.w500 : FontWeight.w600)),
                                      const SizedBox(height: 4),
                                      Text(notif.message, style: GoogleFonts.inter(fontSize: 12, color: STBColors.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 6),
                                      Text(notif.createdAt ?? '', style: GoogleFonts.inter(fontSize: 11, color: STBColors.textSecondary.withValues(alpha: 0.7))),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (!notif.isRead)
                                      Container(width: 8, height: 8, margin: const EdgeInsets.only(bottom: 4), decoration: BoxDecoration(color: STBColors.primaryBlue, shape: BoxShape.circle)),
                                    IconButton(
                                      icon: Icon(Icons.delete_outline, size: 20, color: STBColors.textSecondary.withValues(alpha: 0.4)),
                                      onPressed: () => _deleteNotification(notif.id),
                                      constraints: const BoxConstraints(),
                                      padding: EdgeInsets.zero,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
