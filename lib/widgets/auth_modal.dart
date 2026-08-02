import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/auth_service.dart';
import '../screens/login_screen.dart';
import '../screens/splash_screen.dart';
import 'bug_report_modal.dart';

class AuthModal extends StatefulWidget {
  const AuthModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const AuthModal(),
    );
  }

  @override
  State<AuthModal> createState() => _AuthModalState();
}

class _AuthModalState extends State<AuthModal> {
  final AuthService _auth = AuthService();

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    final isGuest = _auth.isGuest;
    final keyboardSpace = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + keyboardSpace),
      decoration: const BoxDecoration(
        color: Color(0xFFF9F6F0),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your Profile',
                style: GoogleFonts.rubik(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2A1F14),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Color(0xFF8C7E72)),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Profile Card ──
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE8DFD5)),
            ),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isGuest
                        ? const Color(0xFFE8DFD5)
                        : const Color(0xFFD4826A).withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isGuest
                        ? const Icon(Icons.person_outline_rounded,
                            color: Color(0xFF9C8878), size: 24)
                        : Text(
                            (user?.name ?? 'U')[0].toUpperCase(),
                            style: GoogleFonts.rubik(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFD4826A),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isGuest ? 'Guest User' : (user?.name ?? 'User'),
                        style: GoogleFonts.rubik(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF2A1F14),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isGuest
                            ? 'Data saved locally on this device'
                            : user?.email ?? '',
                        style: GoogleFonts.rubik(
                          fontSize: 13,
                          color: const Color(0xFF8C7E72),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Guest Banner ──
          if (isGuest) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8C84A).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFE8C84A).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Text('💡', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sign in to keep your data safe',
                          style: GoogleFonts.rubik(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF2A1F14),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Sync across devices & never lose progress',
                          style: GoogleFonts.rubik(
                            fontSize: 12,
                            color: const Color(0xFF8C7E72),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // ── Action Buttons ──
          if (isGuest)
            // Login / Sign Up button for guests
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) => const LoginScreen(),
                      transitionsBuilder: (_, anim, __, child) =>
                          SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 1),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                            parent: anim, curve: Curves.easeOutCubic)),
                        child: child,
                      ),
                      transitionDuration: const Duration(milliseconds: 450),
                    ),
                  );
                },
                icon: const Icon(Icons.person_outline_rounded, size: 20),
                label: Text(
                  'Login or create account',
                  style: GoogleFonts.rubik(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2A1F14),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),

          if (!isGuest) ...[
            // Bug Report + Logout row for authenticated users
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      BugReportModal.show(context);
                    },
                    icon: const Text('🐛', style: TextStyle(fontSize: 16)),
                    label: Text('Report Bug',
                        style: GoogleFonts.rubik(fontSize: 14)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2A1F14),
                      side: const BorderSide(color: Color(0xFFE8DFD5)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await _auth.logout();
                      if (mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const SplashScreen()),
                          (_) => false,
                        );
                      }
                    },
                    icon: const Icon(Icons.logout_rounded,
                        size: 18, color: Color(0xFFD4826A)),
                    label: Text('Sign Out',
                        style: GoogleFonts.rubik(
                            fontSize: 14, color: const Color(0xFFD4826A))),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFD4826A),
                      side: BorderSide(
                          color: const Color(0xFFD4826A).withValues(alpha: 0.3)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],

          // Bug report for guests too
          if (isGuest) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  BugReportModal.show(context);
                },
                icon: const Text('🐛', style: TextStyle(fontSize: 16)),
                label: Text('Report a Bug',
                    style: GoogleFonts.rubik(fontSize: 14)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2A1F14),
                  side: const BorderSide(color: Color(0xFFE8DFD5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
