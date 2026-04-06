import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/stb_theme.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';
import '../../models/user.dart';

class RHNotifications extends StatefulWidget {
  const RHNotifications({super.key});

  @override
  State<RHNotifications> createState() => _RHNotificationsState();
}

class _RHNotificationsState extends State<RHNotifications> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  String? _selectedUserId;
  List<User> _employees = [];
  bool _sendToAll = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    final result = await ApiService.get(ApiConfig.employeeList, params: {'limit': '100'});
    if (result['success'] == true && mounted) {
      setState(() {
        _employees = (result['data'] as List).map((e) => User.fromJson(e)).toList();
        _isLoading = false;
      });
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendNotification() async {
    if (_titleController.text.isEmpty || _messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Titre et message requis')));
      return;
    }
    if (!_sendToAll && _selectedUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sélectionnez un destinataire')));
      return;
    }

    final result = await ApiService.post(ApiConfig.notificationCreate, {
      'user_id': _sendToAll ? 'all' : int.parse(_selectedUserId!),
      'titre': _titleController.text,
      'message': _messageController.text,
      'type_notif': 'system',
    });

    if (result['success'] == true) {
      _titleController.clear();
      _messageController.clear();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? 'Notification envoyée'), backgroundColor: STBColors.success));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Row(mainAxisSize: MainAxisSize.min, children: [ Image.asset('assets/images/Logo_STB.png', height: 40), const SizedBox(width: 12), const Text('Notifications') ])),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: STBColors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Envoyer une notification', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 20),
                        SwitchListTile(
                          title: Text('Envoyer à tous les employés', style: GoogleFonts.inter(fontSize: 14)),
                          value: _sendToAll,
                          activeColor: STBColors.primaryBlue,
                          onChanged: (v) => setState(() => _sendToAll = v),
                          contentPadding: EdgeInsets.zero,
                        ),
                        if (!_sendToAll) ...[
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _selectedUserId,
                            decoration: const InputDecoration(labelText: 'Destinataire'),
                            items: _employees.map((e) => DropdownMenuItem(value: e.id.toString(), child: Text('${e.fullName} (${e.matricule})'))).toList(),
                            onChanged: (v) => setState(() => _selectedUserId = v),
                          ),
                        ],
                        const SizedBox(height: 16),
                        TextFormField(controller: _titleController, decoration: const InputDecoration(labelText: 'Titre')),
                        const SizedBox(height: 12),
                        TextFormField(controller: _messageController, maxLines: 4, decoration: const InputDecoration(labelText: 'Message')),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _sendNotification,
                            icon: const Icon(Icons.send),
                            label: const Text('Envoyer'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
