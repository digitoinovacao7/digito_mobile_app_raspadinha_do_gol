import 'package:flutter/material.dart';
import '../core/auth_wrapper.dart';

/// Tela Splash Animada e Dinâmica com Movimento Suave, Respiração e Aura Radiante
class SplashScreen extends StatefulWidget {
  final bool standalone;
  final VoidCallback? onInitializationComplete;

  const SplashScreen({
    super.key,
    this.standalone = false,
    this.onInitializationComplete,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Animação de entrada elástica e elegante para o escudo/logo e títulos
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutBack,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeIn,
    );

    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic),
    );

    // 2. Animação contínua de pulsação, aura brilhante e ondulação de energia do estádio
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.97, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 18.0, end: 42.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rotationAnimation = Tween<double>(begin: -0.02, end: 0.02).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );

    _entranceController.forward();

    // Navegação automática para o AuthWrapper após a exibição animada
    if (!widget.standalone) {
      Future.delayed(const Duration(milliseconds: 2400), () {
        if (!mounted) return;
        if (widget.onInitializationComplete != null) {
          widget.onInitializationComplete!();
        } else {
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              transitionDuration: const Duration(milliseconds: 700),
              pageBuilder: (context, animation, secondaryAnimation) => const AuthWrapper(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
            ),
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF020E08),
      body: Stack(
        children: [
          // FUNDO COM GRADIENTE RADIAL PROFUNDO DO GRAMADO AO OBSIDIAN
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.25),
                radius: 1.25,
                colors: [
                  Color(0xFF0F472A), // Verde esmeralda vibrante no centro
                  Color(0xFF072415), // Verde fechado
                  Color(0xFF020E08), // Obsidian grafite escuro nas bordas
                ],
              ),
            ),
          ),

          // ANÉIS CONCÊNTRICOS DE ENERGIA DO ESTÁDIO EM SEGUNDO PLANO
          Center(
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, _) {
                return CustomPaint(
                  size: Size(size.width, size.width),
                  painter: _StadiumEnergyRingsPainter(
                    pulseProgress: _pulseController.value,
                  ),
                );
              },
            ),
          ),

          // CONTEÚDO CENTRAL: LOGO, MARCA, BADGE E CARREGADOR
          SafeArea(
            child: Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 3),

                    // LOGOTIPO COM SCALE ELÁSTICO, GLOW DINÂMICO E PULSO
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, _) {
                          return Transform.rotate(
                            angle: _rotationAnimation.value,
                            child: Transform.scale(
                              scale: _pulseAnimation.value,
                              child: Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(32),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF00E676).withValues(alpha: 0.35),
                                      blurRadius: _glowAnimation.value,
                                      spreadRadius: 3,
                                      offset: const Offset(0, 10),
                                    ),
                                    BoxShadow(
                                      color: const Color(0xFFFBBF24).withValues(alpha: 0.25),
                                      blurRadius: 50,
                                      spreadRadius: -2,
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(32),
                                  child: Image.asset(
                                    'assets/logo_transparent.png',
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Image.asset(
                                        'assets/logo.png',
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                colors: [Color(0xFF006400), Color(0xFF003800)],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              borderRadius: BorderRadius.circular(32),
                                            ),
                                            child: const Icon(
                                              Icons.sports_soccer,
                                              size: 64,
                                              color: Colors.white,
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 32),

                    // NOME DA MARCA COM SLIDE E BRILHO
                    AnimatedBuilder(
                      animation: _entranceController,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _slideAnimation.value),
                          child: child,
                        );
                      },
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Raspadinha ',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              Text(
                                'do Gol',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFFFBBF24),
                                  letterSpacing: -0.5,
                                  shadows: [
                                    Shadow(
                                      color: const Color(0xFFFBBF24).withValues(alpha: 0.65),
                                      blurRadius: 18,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'QUIZZES AO VIVO, RASPAGENS & PRÊMIOS',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF86EFAC),
                              letterSpacing: 2.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(flex: 3),

                    // BADGE DE CONFIANÇA & ENTRETENIMENTO
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 36),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.14),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.stars, color: Color(0xFFFBBF24), size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Prêmios Físicos Oficiais & Entrega Garantida',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // BARRA DE PROGRESSO RADIANTE ESTILIZADA
                    SizedBox(
                      width: 150,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: const LinearProgressIndicator(
                          minHeight: 3.5,
                          backgroundColor: Color(0xFF0F3820),
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00E676)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      'Preparando a emoção da rodada...',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 32),
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

/// Pintor customizado para desenhar ondas e anéis concêntricos pulsantes de energia do estádio
class _StadiumEnergyRingsPainter extends CustomPainter {
  final double pulseProgress;

  _StadiumEnergyRingsPainter({required this.pulseProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 - 50);

    final greenGlow = Paint()
      ..color = const Color(0xFF00E676).withValues(alpha: 0.05 + (pulseProgress * 0.04))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final goldGlow = Paint()
      ..color = const Color(0xFFFBBF24).withValues(alpha: 0.03 + (pulseProgress * 0.03))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final outerRing = Paint()
      ..color = const Color(0xFF00E676).withValues(alpha: 0.02 + (pulseProgress * 0.02))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(center, 95 + (pulseProgress * 18), greenGlow);
    canvas.drawCircle(center, 160 + (pulseProgress * 28), goldGlow);
    canvas.drawCircle(center, 225 + (pulseProgress * 36), outerRing);
  }

  @override
  bool shouldRepaint(covariant _StadiumEnergyRingsPainter oldDelegate) {
    return oldDelegate.pulseProgress != pulseProgress;
  }
}
