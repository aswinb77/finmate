import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'welcome_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  OnboardingScreen — 4 slides, Finny the dragon mascot
// ─────────────────────────────────────────────────────────────────────────────

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  static const int _totalPages = 4;

  late AnimationController _mascotController;
  late AnimationController _contentController;
  late Animation<double> _mascotBounce;
  late Animation<double> _contentFade;
  late Animation<Offset> _contentSlide;

  @override
  void initState() {
    super.initState();

    _mascotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _mascotBounce = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _mascotController, curve: Curves.elasticOut),
    );
    _contentFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOut),
    );
    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOutCubic),
    );

    _mascotController.forward();
    _contentController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _mascotController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finish();
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (ctx, a1, a2) => const WelcomeScreen(),
          transitionsBuilder: (ctx, anim, a2, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
    _mascotController.forward(from: 0);
    _contentController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _currentPage == _totalPages - 1;
    return Scaffold(
      backgroundColor: const Color(0xFFF5EFE0),
      body: Stack(
        children: [
          // Ambient background blobs
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  const Color(0xFFE8C84A).withValues(alpha: 0.10),
                  const Color(0xFFE8C84A).withValues(alpha: 0.0),
                ]),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -60,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  const Color(0xFFD4826A).withValues(alpha: 0.10),
                  const Color(0xFFD4826A).withValues(alpha: 0.0),
                ]),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Skip button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: _finish,
                        child: Text(
                          'Skip',
                          style: GoogleFonts.rubik(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF9C8878),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Page content
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    children: [
                      _OnboardingPage(
                        illustration: const _HappyVisual(),
                        title: 'Meet Finny',
                        subtitle:
                            'Your friendly finance dragon.\nHe\'ll help you track every rupee — no spreadsheets needed.',
                        mascotBounce: _mascotBounce,
                        contentFade: _contentFade,
                        contentSlide: _contentSlide,
                      ),
                      _OnboardingPage(
                        illustration: const _ChatVisual(),
                        title: 'Just say it',
                        subtitle:
                            'Type "chai 15 rupees" and Finny logs it instantly.\nNo forms, no dropdowns — just chat.',
                        mascotBounce: _mascotBounce,
                        contentFade: _contentFade,
                        contentSlide: _contentSlide,
                      ),
                      _OnboardingPage(
                        illustration: const _RingVisual(),
                        title: 'Every day is a story ring',
                        subtitle:
                            'Each spend fills your daily ring.\nSee your whole day\'s shape at a glance.',
                        mascotBounce: _mascotBounce,
                        contentFade: _contentFade,
                        contentSlide: _contentSlide,
                      ),
                      _OnboardingPage(
                        illustration: const _RatingVisual(),
                        title: 'Rate it, feel it',
                        subtitle:
                            'One tap after every spend — worth it, meh, or regret it.\nFind out what actually makes you happy.',
                        mascotBounce: _mascotBounce,
                        contentFade: _contentFade,
                        contentSlide: _contentSlide,
                      ),
                    ],
                  ),
                ),

                // Dot indicators
                Padding(
                  padding: const EdgeInsets.only(bottom: 28),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_totalPages, (i) {
                      final isActive = i == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xFFE07B54)
                              : const Color(0xFFD4C4B0),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                ),

                // Bottom nav row
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                  child: Row(
                    children: [
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 250),
                        opacity: _currentPage > 0 ? 1.0 : 0.0,
                        child: GestureDetector(
                          onTap: _prevPage,
                          child: Container(
                            width: 48,
                            height: 56,
                            alignment: Alignment.center,
                            child: const Icon(Icons.arrow_back_rounded,
                                color: Color(0xFF7C6A55)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _nextPage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2A1F14),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              child: Text(
                                isLast ? 'Get started' : 'Next',
                                key: ValueKey<String>(
                                    isLast ? 'get_started' : 'next'),
                                style: GoogleFonts.rubik(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFE8C84A),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Generic onboarding page layout
// ─────────────────────────────────────────────────────────────────────────────

class _OnboardingPage extends StatelessWidget {
  final Widget illustration;
  final String title;
  final String subtitle;
  final Animation<double> mascotBounce;
  final Animation<double> contentFade;
  final Animation<Offset> contentSlide;

  const _OnboardingPage({
    required this.illustration,
    required this.title,
    required this.subtitle,
    required this.mascotBounce,
    required this.contentFade,
    required this.contentSlide,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const Spacer(flex: 1),
          ScaleTransition(scale: mascotBounce, child: illustration),
          const Spacer(flex: 2),
          SlideTransition(
            position: contentSlide,
            child: FadeTransition(
              opacity: contentFade,
              child: Column(
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.rubik(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF2A1F14),
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.rubik(
                      fontSize: 15,
                      color: const Color(0xFF8C7E72),
                      height: 1.65,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(flex: 3),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Dragon expression enum
// ─────────────────────────────────────────────────────────────────────────────

enum DragonExpression { happy, curious, excited, silly }

// ─────────────────────────────────────────────────────────────────────────────
//  Dragon mascot CustomPaint — expressions from the 35 Expression Exercise
// ─────────────────────────────────────────────────────────────────────────────

class DragonMascot extends StatelessWidget {
  final DragonExpression expression;
  final double size;
  const DragonMascot({
    super.key,
    required this.expression,
    this.size = 200,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _DragonPainter(expression: expression)),
    );
  }
}

class _DragonPainter extends CustomPainter {
  final DragonExpression expression;
  const _DragonPainter({required this.expression});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final bodyFill = Paint()..color = const Color(0xFFE07B54);
    final scaleFill = Paint()..color = const Color(0xFF3464B4);
    final belly = Paint()..color = const Color(0xFFF5C8A8);
    final snoutFill = Paint()..color = const Color(0xFFF0A070);
    final outline = Paint()
      ..color = const Color(0xFF2A1F14)
      ..strokeWidth = 3.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final eyeWhite = Paint()..color = Colors.white;
    final darkPupil = Paint()..color = const Color(0xFF1A1008);
    final blushPaint = Paint()
      ..color = const Color(0xFFF2A68C).withValues(alpha: 0.65);
    final teethFill = Paint()..color = Colors.white;
    final gold = Paint()..color = const Color(0xFFE8C84A);
    final dimLine = Paint()
      ..color = const Color(0xFFD4C4B0)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    // ── Body ──
    final bodyOval =
        Rect.fromCenter(center: Offset(cx, cy + 22), width: 128, height: 108);
    canvas.drawOval(bodyOval, bodyFill);
    canvas.drawOval(bodyOval, outline);

    // ── Belly ──
    final bellyOval =
        Rect.fromCenter(center: Offset(cx, cy + 28), width: 76, height: 68);
    canvas.drawOval(bellyOval, belly);
    canvas.drawOval(bellyOval, outline);

    // ── Spine scales ──
    for (int i = 0; i < 5; i++) {
      final sx = cx - 50 + i * 8.0;
      final sy = cy - 28 - i * 6.0;
      final sp = Path()
        ..moveTo(sx, sy)
        ..quadraticBezierTo(sx - 8, sy - 18, sx - 14, sy - 30)
        ..quadraticBezierTo(sx - 20, sy - 18, sx - 10, sy)
        ..close();
      canvas.drawPath(sp, scaleFill);
      canvas.drawPath(sp, outline);
    }

    // ── Head ──
    final headC = Offset(cx + 14, cy - 38);
    canvas.drawCircle(headC, 46, bodyFill);
    canvas.drawCircle(headC, 46, outline);

    // ── Snout ──
    final snoutRR = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx + 46, cy - 32), width: 40, height: 26),
        const Radius.circular(13));
    canvas.drawRRect(snoutRR, snoutFill);
    canvas.drawRRect(snoutRR, outline);
    canvas.drawCircle(Offset(cx + 37, cy - 34), 3.5, darkPupil);
    canvas.drawCircle(Offset(cx + 47, cy - 34), 3.5, darkPupil);

    // ── Eye socket ──
    canvas.drawOval(
        Rect.fromCenter(center: Offset(cx + 4, cy - 46), width: 26, height: 22),
        eyeWhite);
    canvas.drawOval(
        Rect.fromCenter(center: Offset(cx + 4, cy - 46), width: 26, height: 22),
        outline);

    // ── Expression-specific eyes, brows, mouth ──
    _drawExpression(canvas, cx, cy, outline, darkPupil, blushPaint, teethFill, gold, dimLine);

    // ── Arm with prop ──
    _drawArm(canvas, cx, cy, outline, gold);

    // ── Tail ──
    final tail = Path()
      ..moveTo(cx + 45, cy + 54)
      ..quadraticBezierTo(cx + 82, cy + 78, cx + 70, cy + 98)
      ..quadraticBezierTo(cx + 60, cy + 112, cx + 50, cy + 106);
    canvas.drawPath(tail, outline);

    // ── Legs & feet ──
    canvas.drawLine(Offset(cx - 28, cy + 64), Offset(cx - 36, cy + 88), outline);
    canvas.drawLine(Offset(cx + 28, cy + 64), Offset(cx + 36, cy + 88), outline);
    canvas.drawLine(Offset(cx - 36, cy + 88), Offset(cx - 50, cy + 88), outline);
    canvas.drawLine(Offset(cx + 36, cy + 88), Offset(cx + 50, cy + 88), outline);
  }

  void _drawExpression(Canvas canvas, double cx, double cy,
      Paint ol, Paint pupil, Paint blush, Paint teeth, Paint gold, Paint dim) {
    switch (expression) {
      // ── HAPPY ── big round eyes, wide arc smile, rosy cheeks
      case DragonExpression.happy:
        canvas.drawOval(
            Rect.fromCenter(center: Offset(cx + 4, cy - 46), width: 14, height: 14),
            pupil);
        canvas.drawCircle(
            Offset(cx + 9, cy - 51), 3, Paint()..color = Colors.white);

        // Smile arc
        final smile = Path()
          ..moveTo(cx + 28, cy - 20)
          ..quadraticBezierTo(cx + 42, cy - 8, cx + 58, cy - 20);
        canvas.drawPath(smile, ol);

        // Blush
        canvas.drawOval(
            Rect.fromCenter(center: Offset(cx - 5, cy - 30), width: 18, height: 11),
            blush);
        canvas.drawOval(
            Rect.fromCenter(center: Offset(cx + 25, cy - 32), width: 18, height: 11),
            blush);

        // Happy brow arc
        final brow = Path()
          ..moveTo(cx - 3, cy - 59)
          ..quadraticBezierTo(cx + 5, cy - 66, cx + 14, cy - 60);
        canvas.drawPath(brow, ol);
        break;

      // ── CURIOUS ── one squint + one wide eye, open-O mouth, thought dots
      case DragonExpression.curious:
        // Wide eye
        canvas.drawOval(
            Rect.fromCenter(center: Offset(cx + 4, cy - 46), width: 14, height: 16),
            pupil);
        canvas.drawCircle(
            Offset(cx + 9, cy - 52), 3, Paint()..color = Colors.white);

        // Squint (arc closed eye on left side of head)
        final squint = Path()
          ..moveTo(cx - 9, cy - 51)
          ..quadraticBezierTo(cx + 1, cy - 43, cx + 13, cy - 51);
        canvas.drawPath(squint, ol..strokeWidth = 3.0);

        // Open mouth "o"
        canvas.drawOval(
            Rect.fromCenter(center: Offset(cx + 42, cy - 22), width: 14, height: 10),
            Paint()..color = const Color(0xFF2A1F14));

        // Tilted brow
        final brow = Path()
          ..moveTo(cx - 5, cy - 62)
          ..quadraticBezierTo(cx + 3, cy - 70, cx + 13, cy - 66);
        canvas.drawPath(brow, ol..strokeWidth = 3.2);

        // Thought dots
        canvas.drawCircle(Offset(cx + 32, cy - 78), 3.5, dim..style = PaintingStyle.fill);
        canvas.drawCircle(Offset(cx + 42, cy - 90), 5.5, dim);
        canvas.drawCircle(Offset(cx + 54, cy - 104), 7.5, dim);
        break;

      // ── EXCITED ── huge eyes with stars, big grin & teeth, flushed cheeks
      case DragonExpression.excited:
        canvas.drawOval(
            Rect.fromCenter(center: Offset(cx + 4, cy - 46), width: 18, height: 18),
            pupil);
        canvas.drawCircle(
            Offset(cx + 9, cy - 52), 4, Paint()..color = Colors.white);

        // Star sparks
        _drawStar(canvas, Offset(cx - 12, cy - 66), 6, gold);
        _drawStar(canvas, Offset(cx + 26, cy - 70), 5, gold);

        // Grin arc
        final grin = Path()
          ..moveTo(cx + 26, cy - 18)
          ..quadraticBezierTo(cx + 42, cy - 2, cx + 60, cy - 18);
        canvas.drawPath(grin, ol..strokeWidth = 3.2);

        // Teeth
        for (int t = 0; t < 4; t++) {
          final tx = cx + 32.0 + t * 6.0;
          canvas.drawRect(Rect.fromLTWH(tx, cy - 17, 5, 7), teeth);
          canvas.drawRect(Rect.fromLTWH(tx, cy - 17, 5, 7),
              ol..strokeWidth = 1.4);
        }

        // Blush
        canvas.drawOval(
            Rect.fromCenter(center: Offset(cx - 5, cy - 30), width: 20, height: 12),
            blush);
        canvas.drawOval(
            Rect.fromCenter(center: Offset(cx + 26, cy - 32), width: 20, height: 12),
            blush);
        break;

      // ── SILLY ── wink + open eye, lopsided grin, tongue out
      case DragonExpression.silly:
        // Wink (closed squiggle)
        final wink = Path()
          ..moveTo(cx - 7, cy - 51)
          ..quadraticBezierTo(cx + 1, cy - 43, cx + 11, cy - 51);
        canvas.drawPath(wink, ol..strokeWidth = 3.0);

        // Open eye (offset right on the head)
        canvas.drawOval(
            Rect.fromCenter(center: Offset(cx + 16, cy - 46), width: 16, height: 14),
            Paint()..color = Colors.white);
        canvas.drawOval(
            Rect.fromCenter(center: Offset(cx + 16, cy - 46), width: 16, height: 14),
            ol..strokeWidth = 2.5);
        canvas.drawOval(
            Rect.fromCenter(center: Offset(cx + 16, cy - 46), width: 10, height: 10),
            pupil);
        canvas.drawCircle(
            Offset(cx + 20, cy - 50), 3, Paint()..color = Colors.white);

        // Lopsided grin
        final lopsided = Path()
          ..moveTo(cx + 26, cy - 22)
          ..quadraticBezierTo(cx + 44, cy - 12, cx + 60, cy - 24);
        canvas.drawPath(lopsided, ol..strokeWidth = 3.2);

        // Tongue
        canvas.drawOval(
            Rect.fromCenter(center: Offset(cx + 48, cy - 16), width: 14, height: 9),
            Paint()..color = const Color(0xFFE05870));

        // Raised brow on open side
        final brow = Path()
          ..moveTo(cx + 8, cy - 61)
          ..quadraticBezierTo(cx + 16, cy - 69, cx + 24, cy - 65);
        canvas.drawPath(brow, ol..strokeWidth = 3.2);

        // Motion lines
        canvas.drawLine(
            Offset(cx - 22, cy - 80), Offset(cx - 32, cy - 90), dim..style = PaintingStyle.stroke..strokeWidth = 2.5);
        canvas.drawLine(
            Offset(cx - 26, cy - 75), Offset(cx - 38, cy - 82), dim);
        break;
    }
  }

  void _drawArm(Canvas canvas, double cx, double cy, Paint ol, Paint gold) {
    if (expression == DragonExpression.happy ||
        expression == DragonExpression.excited) {
      // Arm holding a coin
      final arm = Path()
        ..moveTo(cx - 30, cy + 30)
        ..quadraticBezierTo(cx - 60, cy + 58, cx - 50, cy + 78);
      canvas.drawPath(arm, ol);
      canvas.drawCircle(Offset(cx - 50, cy + 80), 11, gold);
      canvas.drawCircle(Offset(cx - 50, cy + 80), 11, ol);
      canvas.drawCircle(Offset(cx - 50, cy + 80), 5,
          Paint()..color = const Color(0xFFC8A000));
    } else if (expression == DragonExpression.curious) {
      // Arm holding a tiny chat bubble
      final arm = Path()
        ..moveTo(cx - 30, cy + 30)
        ..quadraticBezierTo(cx - 55, cy + 54, cx - 52, cy + 76);
      canvas.drawPath(arm, ol);
      final bubbleR = RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(cx - 66, cy + 72), width: 28, height: 18),
          const Radius.circular(8));
      canvas.drawRRect(bubbleR, Paint()..color = const Color(0xFF2A1F14));
      for (int i = 0; i < 3; i++) {
        canvas.drawCircle(Offset(cx - 72 + i * 6.0, cy + 72), 2,
            Paint()..color = Colors.white);
      }
    }
  }

  void _drawStar(Canvas canvas, Offset c, double r, Paint paint) {
    final path = Path();
    for (int i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      final radius = i.isEven ? r : r * 0.4;
      final x = c.dx + radius * math.cos(angle - math.pi / 2);
      final y = c.dy + radius * math.sin(angle - math.pi / 2);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_DragonPainter old) => old.expression != expression;
}

// ─────────────────────────────────────────────────────────────────────────────
//  Page 1: Happy dragon (just the mascot)
// ─────────────────────────────────────────────────────────────────────────────

class _HappyVisual extends StatelessWidget {
  const _HappyVisual();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/finny_animated.gif',
      width: 220,
      height: 220,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Image.asset(
          'assets/finny.png',
          width: 220,
          height: 220,
          fit: BoxFit.contain,
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Page 2: Curious dragon + chat bubbles
// ─────────────────────────────────────────────────────────────────────────────

class _ChatVisual extends StatelessWidget {
  const _ChatVisual();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF2A1F14),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Text(
              'chai 15 rupees',
              style: GoogleFonts.rubik(
                fontSize: 15,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE8DFD5)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C6A55).withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              'Got it — logged ₹15 under Food ☕',
              style: GoogleFonts.rubik(
                fontSize: 15,
                color: const Color(0xFF2A1F14),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Page 3: Excited dragon + animated story ring
// ─────────────────────────────────────────────────────────────────────────────

class _RingVisual extends StatefulWidget {
  const _RingVisual();

  @override
  State<_RingVisual> createState() => _RingVisualState();
}

class _RingVisualState extends State<_RingVisual>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _sweepAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1300));
    _sweepAnim = Tween<double>(begin: 0.0, end: 0.72).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _sweepAnim,
      builder: (ctx, w) => SizedBox(
        width: 220,
        height: 220,
        child: CustomPaint(
          painter: _RingPainter(sweep: _sweepAnim.value),
          child: Center(
            child: Text(
              '₹1,240',
              style: GoogleFonts.rubik(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF2A1F14),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double sweep;
  const _RingPainter({required this.sweep});

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 12;
    canvas.drawCircle(
        c,
        r,
        Paint()
          ..color = const Color(0xFFE8DFD5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 18
          ..strokeCap = StrokeCap.round);
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -math.pi / 2,
      sweep * 2 * math.pi,
      false,
      Paint()
        ..color = const Color(0xFFE07B54)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 18
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.sweep != sweep;
}

// ─────────────────────────────────────────────────────────────────────────────
//  Page 4: Silly dragon + interactive emoji rating
// ─────────────────────────────────────────────────────────────────────────────

class _RatingVisual extends StatefulWidget {
  const _RatingVisual();

  @override
  State<_RatingVisual> createState() => _RatingVisualState();
}

class _RatingVisualState extends State<_RatingVisual> {
  int _selected = 1;

  @override
  Widget build(BuildContext context) {
    const ratings = [
      ('😍', 'Worth it'),
      ('😐', 'Meh'),
      ('😩', 'Regret it'),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(ratings.length, (i) {
            final isSel = _selected == i;
            return GestureDetector(
              onTap: () => setState(() => _selected = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                width: isSel ? 80 : 64,
                height: isSel ? 80 : 64,
                decoration: BoxDecoration(
                  color: isSel
                      ? const Color(0xFF2A1F14)
                      : const Color(0xFFEDE5D8),
                  shape: BoxShape.circle,
                  boxShadow: isSel
                      ? [
                          BoxShadow(
                            color: const Color(0xFF2A1F14).withValues(alpha: 0.25),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          )
                        ]
                      : [],
                ),
                child: Center(
                  child: Text(
                    ratings[i].$1,
                    style: TextStyle(fontSize: isSel ? 38 : 28),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            ratings[_selected].$2,
            key: ValueKey<int>(_selected),
            style: GoogleFonts.rubik(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF9C8878),
            ),
          ),
        ),
      ],
    );
  }
}
