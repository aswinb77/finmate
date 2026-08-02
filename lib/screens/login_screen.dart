import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/auth_service.dart';
import '../main.dart';
import 'admin_dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  final bool isAdminMode;

  const LoginScreen({super.key, this.isAdminMode = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _auth = AuthService();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passphraseController = TextEditingController();

  bool _isLogin = true; // true = login mode, false = signup mode
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();

    if (widget.isAdminMode) {
      _isLogin = true;
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passphraseController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please fill in all fields');
      return;
    }
    if (!email.contains('@')) {
      setState(() => _errorMessage = 'Please enter a valid email');
      return;
    }
    if (password.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      bool success = false;

      if (widget.isAdminMode) {
        final passphrase = _passphraseController.text.trim();
        if (passphrase.isEmpty) {
          setState(() {
            _errorMessage = 'Admin passphrase is required';
            _isLoading = false;
          });
          return;
        }
        success = await _auth.adminLogin(email, password, passphrase);
        if (!success) {
          setState(() {
            _errorMessage = 'Invalid admin passphrase';
            _isLoading = false;
          });
          return;
        }
      } else if (_isLogin) {
        success = await _auth.login(email, password);
      } else {
        final name = _nameController.text.trim();
        if (name.isEmpty) {
          setState(() {
            _errorMessage = 'Please enter your name';
            _isLoading = false;
          });
          return;
        }
        success = await _auth.signup(name, email, password);
      }

      setState(() => _isLoading = false);

      if (success && mounted) {
        if (widget.isAdminMode && _auth.isAdmin) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
            (_) => false,
          );
        } else {
          Navigator.of(context).pushAndRemoveUntil(
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => const MainShell(),
              transitionsBuilder: (_, anim, __, child) =>
                  FadeTransition(opacity: anim, child: child),
              transitionDuration: const Duration(milliseconds: 500),
            ),
            (_) => false,
          );
        }
      } else if (!success) {
        setState(() {
          _errorMessage = _auth.lastError ?? 'Something went wrong. Please try again.';
        });
      }
    } catch (e) {
      debugPrint('Login/Signup error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error: ${e.toString().replaceAll('Exception: ', '')}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = widget.isAdminMode;
    final title = isAdmin
        ? 'Admin Access'
        : (_isLogin ? 'Welcome back' : 'Create account');
    final subtitle = isAdmin
        ? 'Authorized personnel only'
        : (_isLogin
            ? 'Sign in to sync your data across devices'
            : 'Start tracking your spending journey');

    return Scaffold(
      backgroundColor: const Color(0xFFF5EFE0),
      body: Stack(
        children: [
          // Background circles
          Positioned(
            top: -60,
            left: -80,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    (isAdmin
                            ? const Color(0xFFD4826A)
                            : const Color(0xFF9BAFD6))
                        .withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFE8C84A).withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),

                    // Back button
                    if (!isAdmin)
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back_rounded,
                            color: Color(0xFF2A1F14)),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    if (isAdmin)
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded,
                            color: Color(0xFF8C7E72)),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),

                    const SizedBox(height: 32),

                    // Logo
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: isAdmin
                            ? const Color(0xFFD4826A)
                            : const Color(0xFF2A1F14),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: isAdmin
                            ? const Icon(Icons.shield_rounded,
                                color: Colors.white, size: 26)
                            : const Text('◆',
                                style: TextStyle(
                                    fontSize: 24, color: Color(0xFFE8C84A))),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Title
                    Text(
                      title,
                      style: GoogleFonts.rubik(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF2A1F14),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: GoogleFonts.rubik(
                        fontSize: 15,
                        color: const Color(0xFF9C8878),
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 36),

                    // ── Form Fields ──
                    // Name (signup only)
                    if (!_isLogin && !isAdmin) ...[
                      _buildLabel('Your Name'),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _nameController,
                        hint: 'e.g. Aswin',
                        icon: Icons.person_outline_rounded,
                      ),
                      const SizedBox(height: 20),
                    ],

                    _buildLabel('Email'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _emailController,
                      hint: 'your@email.com',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 20),

                    _buildLabel('Password'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _passwordController,
                      hint: '••••••••',
                      icon: Icons.lock_outline_rounded,
                      obscure: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: const Color(0xFFB5A99B),
                          size: 20,
                        ),
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),

                    // Admin passphrase field
                    if (isAdmin) ...[
                      const SizedBox(height: 20),
                      _buildLabel('Admin Passphrase'),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _passphraseController,
                        hint: 'Enter admin passphrase',
                        icon: Icons.key_rounded,
                        obscure: true,
                      ),
                    ],

                    // Error message
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD4826A).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded,
                                color: Color(0xFFD4826A), size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: GoogleFonts.rubik(
                                  fontSize: 13,
                                  color: const Color(0xFFD4826A),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isAdmin
                              ? const Color(0xFFD4826A)
                              : const Color(0xFF2A1F14),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(0xFFD4C4B0),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                isAdmin
                                    ? 'Authenticate'
                                    : (_isLogin ? 'Sign In' : 'Create Account'),
                                style: GoogleFonts.rubik(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),

                    // Toggle login/signup (not for admin)
                    if (!isAdmin) ...[
                      const SizedBox(height: 20),
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _isLogin = !_isLogin;
                              _errorMessage = null;
                            });
                          },
                          child: RichText(
                            text: TextSpan(
                              style: GoogleFonts.rubik(
                                fontSize: 14,
                                color: const Color(0xFF9C8878),
                              ),
                              children: [
                                TextSpan(
                                  text: _isLogin
                                      ? "Don't have an account? "
                                      : 'Already have an account? ',
                                ),
                                TextSpan(
                                  text: _isLogin ? 'Sign Up' : 'Sign In',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF2A1F14),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.rubik(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF2A1F14),
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: GoogleFonts.rubik(
        fontSize: 15,
        color: const Color(0xFF2A1F14),
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.rubik(
          color: const Color(0xFFCCC0AE),
          fontSize: 15,
        ),
        prefixIcon: Icon(icon, color: const Color(0xFFB5A99B), size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE8DFD5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE8DFD5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              const BorderSide(color: Color(0xFF2A1F14), width: 1.5),
        ),
      ),
    );
  }
}
