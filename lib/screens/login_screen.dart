import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../core/theme.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const CustomPaint(painter: _FootballFieldPainter()),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withValues(alpha: 0.18),
                  AppTheme.primaryGreen.withValues(alpha: 0.32),
                  Colors.black.withValues(alpha: 0.28),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // App Title
                          Text(
                            'Raspadinha do Gol',
                            style: Theme.of(context).textTheme.displayLarge
                                ?.copyWith(
                                  color: AppTheme.textLight,
                                  fontWeight: FontWeight.w900,
                                  shadows: [
                                    const Shadow(
                                      color: Colors.black26,
                                      offset: Offset(0, 2),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Diversão com segurança garantida!',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: Colors.white70),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 48),

                          // Login Card
                          Container(
                            width: 320,
                            height: 320,
                            padding: const EdgeInsets.all(24.0),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 20,
                                  offset: Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.sports_soccer,
                                  color: AppTheme.primaryGreen,
                                  size: 36,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Acesse sua conta',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textDark,
                                      ),
                                ),
                                const SizedBox(height: 24),
                                const AnimatedGoogleLoginButton(),
                                const SizedBox(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.lock_outline,
                                      color: Colors.grey,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    const Flexible(
                                      child: Text(
                                        'Ambiente 100% Seguro',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Footer Info at the very bottom
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: TextButton(
                    onPressed: () async {
                      final url = Uri.parse('https://raspadinhadogol.web.app');
                      try {
                        await launchUrl(
                          url,
                          mode: LaunchMode.externalApplication,
                        );
                      } catch (e) {
                        debugPrint('Could not launch $url: $e');
                      }
                    },
                    child: const Text(
                      'Visite nosso site',
                      style: TextStyle(
                        color: Colors.white70,
                        decoration: TextDecoration.underline,
                        fontSize: 16,
                      ),
                    ),
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

class _FootballFieldPainter extends CustomPainter {
  const _FootballFieldPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final basePaint = Paint()..color = const Color(0xFF075C2B);
    canvas.drawRect(Offset.zero & size, basePaint);

    final stripePaint = Paint()..color = Colors.white.withValues(alpha: 0.04);
    final stripeHeight = size.height / 9;
    for (var i = 0; i < 9; i += 2) {
      canvas.drawRect(
        Rect.fromLTWH(0, i * stripeHeight, size.width, stripeHeight),
        stripePaint,
      );
    }

    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final margin = size.width * 0.08;
    final fieldRect = Rect.fromLTWH(
      margin,
      size.height * 0.08,
      size.width - margin * 2,
      size.height * 0.84,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(fieldRect, const Radius.circular(8)),
      linePaint,
    );

    final middleY = fieldRect.center.dy;
    canvas.drawLine(
      Offset(fieldRect.left, middleY),
      Offset(fieldRect.right, middleY),
      linePaint,
    );
    canvas.drawCircle(fieldRect.center, size.width * 0.17, linePaint);
    canvas.drawCircle(fieldRect.center, 3, Paint()..color = linePaint.color);

    final boxWidth = fieldRect.width * 0.52;
    final boxHeight = fieldRect.height * 0.13;
    final sixYardWidth = fieldRect.width * 0.28;
    final sixYardHeight = fieldRect.height * 0.055;

    final topPenalty = Rect.fromCenter(
      center: Offset(fieldRect.center.dx, fieldRect.top + boxHeight / 2),
      width: boxWidth,
      height: boxHeight,
    );
    final bottomPenalty = Rect.fromCenter(
      center: Offset(fieldRect.center.dx, fieldRect.bottom - boxHeight / 2),
      width: boxWidth,
      height: boxHeight,
    );
    final topSix = Rect.fromCenter(
      center: Offset(fieldRect.center.dx, fieldRect.top + sixYardHeight / 2),
      width: sixYardWidth,
      height: sixYardHeight,
    );
    final bottomSix = Rect.fromCenter(
      center: Offset(fieldRect.center.dx, fieldRect.bottom - sixYardHeight / 2),
      width: sixYardWidth,
      height: sixYardHeight,
    );

    canvas.drawRect(topPenalty, linePaint);
    canvas.drawRect(bottomPenalty, linePaint);
    canvas.drawRect(topSix, linePaint);
    canvas.drawRect(bottomSix, linePaint);

    final glowPaint = Paint()
      ..color = AppTheme.accentGold.withValues(alpha: 0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28);
    canvas.drawCircle(
      Offset(size.width * 0.82, size.height * 0.18),
      92,
      glowPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.18, size.height * 0.82),
      120,
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class AnimatedGoogleLoginButton extends ConsumerStatefulWidget {
  const AnimatedGoogleLoginButton({super.key});

  @override
  ConsumerState<AnimatedGoogleLoginButton> createState() =>
      _AnimatedGoogleLoginButtonState();
}

class _AnimatedGoogleLoginButtonState
    extends ConsumerState<AnimatedGoogleLoginButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.03,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              elevation: 4,
            ),
            onPressed: _isLoading
                ? null
                : () async {
                    setState(() => _isLoading = true);
                    final navigator = Navigator.of(context);
                    final messenger = ScaffoldMessenger.of(context);
                    final authService = ref.read(authServiceProvider);
                    final user = await authService.signInWithGoogle();

                    if (user != null) {
                      if (mounted) {
                        ref.read(currentUserProvider.notifier).state = user;
                        ref.invalidate(appUserFutureProvider(user.id));
                        setState(() => _isLoading = false);
                        navigator.popUntil((route) => route.isFirst);
                      }
                    } else {
                      if (mounted) {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Falha ao fazer login.'),
                          ),
                        );
                        setState(() => _isLoading = false);
                      }
                    }
                  },
            child: _isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.network(
                        'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/240px-Google_%22G%22_logo.svg.png',
                        height: 24,
                        width: 24,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.login),
                      ),
                      const SizedBox(width: 12),
                      const Flexible(
                        child: Text(
                          'Continuar com Google',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}
