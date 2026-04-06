import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import '../theme/stb_theme.dart';
import '../services/api_service.dart';
import '../config/api_config.dart';

class ChatbotWidget extends StatefulWidget {
  final int? userId;
  const ChatbotWidget({super.key, this.userId});

  @override
  State<ChatbotWidget> createState() => _ChatbotWidgetState();
}

class _ChatbotWidgetState extends State<ChatbotWidget> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _isSending = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'chatbot_history_${widget.userId ?? "guest"}';
    final saved = prefs.getString(key);
    if (saved != null) {
      final List<dynamic> decoded = jsonDecode(saved);
      setState(() {
        _messages = decoded.map((m) => {
          'isBot': m['isBot'],
          'text': m['text'],
          'time': DateTime.parse(m['time']),
          'file_name': m['file_name']
        }).toList();
      });
      _scrollToBottom();
    } else {
      setState(() {
        _messages = [
          {'isBot': true, 'text': 'Bonjour ! 👋 Je suis l\'assistant RH de la STB.\n\nComment puis-je vous aider aujourd\'hui?', 'time': DateTime.now()},
        ];
      });
    }
  }

  Future<void> _saveMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'chatbot_history_${widget.userId ?? "guest"}';
    final toSave = _messages.map((m) => {
      'isBot': m['isBot'],
      'text': m['text'],
      'time': (m['time'] as DateTime).toIso8601String(),
    }).toList();
    await prefs.setString(key, jsonEncode(toSave));
  }

  Future<void> _sendMessage({String? customText}) async {
    final text = customText ?? _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      if (customText == null) {
        _messages.add({'isBot': false, 'text': text, 'time': DateTime.now()});
      }
      _isSending = true;
    });
    
    if (customText == null) _messageController.clear();
    _scrollToBottom();
    _saveMessages();
    
    FocusScope.of(context).unfocus();

    final history = _messages.map((m) => {
      'role': m['isBot'] == true ? 'model' : 'user',
      'text': m['text']
    }).toList();

    final result = await ApiService.post(ApiConfig.chatbot, {
      'message': text,
      'history': history,
    });

    if (mounted) {
      setState(() {
        _isSending = false;
        if (result['success'] == true && result['data'] != null) {
          _messages.add({'isBot': true, 'text': result['data']['response'], 'time': DateTime.now()});
        } else {
          _messages.add({'isBot': true, 'text': '❌ Erreur de communication. Veuillez réessayer.', 'time': DateTime.now()});
        }
      });
      _scrollToBottom();
      _saveMessages();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: STBColors.bgLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [STBColors.gradientStart, STBColors.gradientEnd]),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: STBColors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.smart_toy, color: STBColors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Assistant RH STB', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: STBColors.white)),
                        Text('En ligne • Historique Sauvegardé', style: GoogleFonts.inter(fontSize: 11, color: STBColors.white.withValues(alpha: 0.7))),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_sweep_outlined, color: STBColors.white, size: 20),
                    tooltip: 'Effacer l\'historique',
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      final key = 'chatbot_history_${widget.userId ?? "guest"}';
                      await prefs.remove(key);
                      setState(() {
                         _messages = [
                          {'isBot': true, 'text': 'Historique effacé. Comment puis-je vous aider ?', 'time': DateTime.now()},
                        ];
                      });
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: STBColors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Messages
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length + (_isSending ? 1 : 0),
                itemBuilder: (c, i) {
                  if (i == _messages.length && _isSending) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8, right: 60),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: STBColors.white, borderRadius: BorderRadius.circular(16)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: STBColors.primaryBlue)),
                            const SizedBox(width: 8),
                            Text('En cours...', style: GoogleFonts.inter(fontSize: 13, color: STBColors.textSecondary)),
                          ],
                        ),
                      ),
                    );
                  }
                  final msg = _messages[i];
                  final isBot = msg['isBot'] as bool;
                  return Align(
                    alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
                    child: Container(
                      margin: EdgeInsets.only(bottom: 8, left: isBot ? 0 : 40, right: isBot ? 40 : 0),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isBot ? STBColors.white : STBColors.primaryBlue,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: Radius.circular(isBot ? 4 : 16),
                          bottomRight: Radius.circular(isBot ? 16 : 4),
                        ),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5)],
                      ),
                      child: Text(msg['text'], style: GoogleFonts.inter(fontSize: 14, color: isBot ? STBColors.textPrimary : STBColors.white, height: 1.4)),
                    ),
                  );
                },
              ),
            ),

            // Input
            Container(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
              decoration: BoxDecoration(
                color: STBColors.white,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 5, offset: const Offset(0, -2))],
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: GoogleFonts.inter(fontSize: 14, color: STBColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Tapez votre message...',
                        hintStyle: GoogleFonts.inter(fontSize: 14, color: STBColors.textSecondary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                        filled: true,
                        fillColor: STBColors.bgLight,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(color: STBColors.primaryBlue, borderRadius: BorderRadius.circular(24)),
                    child: IconButton(
                      onPressed: _sendMessage,
                      icon: const Icon(Icons.send, color: STBColors.white, size: 20),
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
