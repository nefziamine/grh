import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/stb_theme.dart';
import '../services/auth_service.dart';
import 'employee/employee_home.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _matriculeController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _matriculeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });
    final result = await AuthService.login(_matriculeController.text.trim(), _passwordController.text);
    if (!mounted) return;
    setState(() { _isLoading = false; });
    if (result['success'] == true) {
      Navigator.pushReplacement(context, PageRouteBuilder(
        pageBuilder: (context, anim, secondaryAnim) => FadeTransition(opacity: anim, child: const EmployeeHome()),
        transitionDuration: const Duration(milliseconds: 800),
      ));
    } else {
      setState(() { _errorMessage = result['message'] ?? 'Erreur de connexion'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(
        children: [
          // Dynamic gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF002244), STBColors.primaryBlue, Color(0xFF0066CC)],
              ),
            ),
          ),
          
          // Animated decorative Background Orbs
          Positioned(
            top: -100,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [STBColors.primaryGreen.withValues(alpha: 0.15), Colors.transparent],
                ),
              ),
            ).animate(onPlay: (controller) => controller.repeat(reverse: true))
             .move(duration: 8000.ms, begin: const Offset(0, -30), end: const Offset(30, 30)),
          ),
          Positioned(
            bottom: -50,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [STBColors.primaryBlue.withValues(alpha: 0.4), Colors.transparent],
                ),
              ),
            ).animate(onPlay: (controller) => controller.repeat(reverse: true))
             .move(duration: 10000.ms, begin: const Offset(0, 30), end: const Offset(-30, -30)),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: size.height * 0.06,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Premium Official Logo
                    Container(
                      height: 100,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 35, offset: const Offset(0, 15)),
                          BoxShadow(color: Colors.white.withValues(alpha: 0.8), blurRadius: 8, spreadRadius: 2),
                        ],
                      ),
                      child: Image.asset(
                        'assets/images/Logo_STB.png',
                        fit: BoxFit.contain,
                      ),
                    ).animate().scale(delay: 100.ms, duration: 600.ms, curve: Curves.easeOutBack)
                     .fadeIn(duration: 500.ms),

                    const SizedBox(height: 20),
                    
                    Text('Gestion RH', style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -1))
                      .animate().fadeIn(delay: 300.ms, duration: 500.ms).slideY(begin: 0.5, end: 0, curve: Curves.easeOut),
                    
                    const SizedBox(height: 8),
                    
                    Text('L\'excellence à votre service', style: GoogleFonts.inter(fontSize: 15, color: Colors.white.withValues(alpha: 0.8), fontWeight: FontWeight.w500))
                      .animate().fadeIn(delay: 500.ms, duration: 500.ms),
                    
                    const SizedBox(height: 28),

                    // Premium Glassmorphism Form Card
                    ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 1.5),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 30, offset: const Offset(0, 15)),
                            ],
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text('Connexion', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: STBColors.textPrimary), textAlign: TextAlign.center),
                                const SizedBox(height: 28),

                                if (_errorMessage != null)
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    margin: const EdgeInsets.only(bottom: 20),
                                    decoration: BoxDecoration(
                                      color: STBColors.danger.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: STBColors.danger.withValues(alpha: 0.3)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.error_outline, color: STBColors.danger, size: 20),
                                        const SizedBox(width: 12),
                                        Expanded(child: Text(_errorMessage!, style: GoogleFonts.inter(fontSize: 13, color: STBColors.danger, fontWeight: FontWeight.w600))),
                                      ],
                                    ),
                                  ).animate().fadeIn().shake(),

                                TextFormField(
                                  controller: _matriculeController,
                                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                                  decoration: InputDecoration(
                                    labelText: 'Matricule d\'employé',
                                    prefixIcon: const Icon(Icons.badge_rounded, color: STBColors.primaryBlue),
                                    filled: true,
                                    fillColor: STBColors.bgLight.withValues(alpha: 0.5),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                  ),
                                  validator: (v) => v == null || v.isEmpty ? 'Matricule requis' : null,
                                ),
                                const SizedBox(height: 20),

                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, letterSpacing: _obscurePassword ? 2 : 0),
                                  decoration: InputDecoration(
                                    labelText: 'Mot de passe sécurisé',
                                    prefixIcon: const Icon(Icons.lock_rounded, color: STBColors.primaryBlue),
                                    suffixIcon: IconButton(
                                      icon: Icon(_obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: STBColors.textSecondary),
                                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                    ),
                                    filled: true,
                                    fillColor: STBColors.bgLight.withValues(alpha: 0.5),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                  ),
                                  validator: (v) => v == null || v.isEmpty ? 'Mot de passe requis' : null,
                                  onFieldSubmitted: (_) => _login(),
                                ),
                                const SizedBox(height: 32),

                                SizedBox(
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _login,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: STBColors.primaryBlue,
                                      elevation: 8,
                                      shadowColor: STBColors.primaryBlue.withValues(alpha: 0.5),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    ),
                                    child: _isLoading
                                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                        : Text('S\'authentifier', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 700.ms, duration: 800.ms).slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),

                    const SizedBox(height: 24),
                    Text('© 2026 STB - Société Tunisienne de Banque', style: GoogleFonts.inter(fontSize: 11, color: Colors.white.withValues(alpha: 0.6), fontWeight: FontWeight.w500))
                      .animate().fadeIn(delay: 1200.ms, duration: 800.ms),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
