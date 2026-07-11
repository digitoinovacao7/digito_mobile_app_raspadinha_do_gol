import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

class SentimentThermometer extends StatefulWidget {
  final int score; // valor atual (pode ser negativo ou positivo, soma cumulativa)
  final int applauseCount;
  final int booCount;
  final Function() onApplause;
  final Function() onBoo;

  const SentimentThermometer({
    super.key,
    required this.score,
    required this.applauseCount,
    required this.booCount,
    required this.onApplause,
    required this.onBoo,
  });

  @override
  State<SentimentThermometer> createState() => _SentimentThermometerState();
}

class _SentimentThermometerState extends State<SentimentThermometer>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _particleController;
  final List<_Particle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  void _spawnParticle(bool isApplause) {
    setState(() {
      _particles.add(_Particle(
        emoji: isApplause
            ? (['👏', '🔥', '⚡'][_random.nextInt(3)])
            : (['😤', '👎', '💔'][_random.nextInt(3)]),
        x: 0.3 + _random.nextDouble() * 0.4,
        isApplause: isApplause,
      ));
    });
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) {
        setState(() {
          _particles.removeWhere((p) => p.emoji ==
              (isApplause ? ['👏', '🔥', '⚡'] : ['😤', '👎', '💔'])[0]);
          if (_particles.isNotEmpty) _particles.removeLast();
        });
      }
    });
  }

  // Normaliza o score (pode ser negativo ou muito grande) para 0.0-1.0
  double get _normalizedLevel {
    final total = widget.applauseCount + widget.booCount;
    if (total == 0) return 0.5;
    return (widget.applauseCount / total).clamp(0.0, 1.0);
  }

  Color get _moodColor {
    final lvl = _normalizedLevel;
    if (lvl > 0.7) return const Color(0xFF39FF14); // verde neon - euforia
    if (lvl > 0.45) return const Color(0xFFFFD700); // dourado - tenso
    return const Color(0xFFFF4444); // vermelho - frustrado
  }

  String get _moodLabel {
    final lvl = _normalizedLevel;
    if (lvl > 0.75) return '🔥 EUFÓRICO';
    if (lvl > 0.6) return '⚡ ANIMADO';
    if (lvl > 0.45) return '😬 TENSO';
    if (lvl > 0.3) return '😤 FRUSTRADO';
    return '💔 REVOLTADO';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _moodColor.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _moodColor.withValues(alpha: 0.15),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          // Cabeçalho
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'HUMOR DA TORCIDA',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, _) {
                  return Opacity(
                    opacity: 0.6 + 0.4 * _pulseController.value,
                    child: Text(
                      _moodLabel,
                      style: TextStyle(
                        color: _moodColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Barra do termômetro
          Stack(
            children: [
              // Track de fundo
              Container(
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              // Preenchimento animado
              AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOut,
                height: 16,
                width: MediaQuery.of(context).size.width *
                    0.75 *
                    _normalizedLevel,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFF4444),
                      const Color(0xFFFFD700),
                      _moodColor,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: _moodColor.withValues(alpha: 0.6),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Frustrado', style: TextStyle(color: Colors.white38, fontSize: 10)),
              Text('Eufórico', style: TextStyle(color: Colors.white38, fontSize: 10)),
            ],
          ),

          const SizedBox(height: 20),

          // Contadores
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _CountBadge(
                label: '${widget.applauseCount}',
                emoji: '👏',
                color: const Color(0xFF39FF14),
              ),
              const SizedBox(width: 16),
              _CountBadge(
                label: '${widget.booCount}',
                emoji: '😤',
                color: const Color(0xFFFF4444),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Botões de interação
          Row(
            children: [
              Expanded(
                child: _InteractionButton(
                  label: 'APLAUDIR',
                  emoji: '👏',
                  color: const Color(0xFF39FF14),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _spawnParticle(true);
                    widget.onApplause();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InteractionButton(
                  label: 'VAIAR',
                  emoji: '😤',
                  color: const Color(0xFFFF4444),
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    _spawnParticle(false);
                    widget.onBoo();
                  },
                ),
              ),
            ],
          ),

          // Partículas flutuantes
          if (_particles.isNotEmpty)
            SizedBox(
              height: 50,
              child: Stack(
                children: _particles.map((p) {
                  return Positioned(
                    left: MediaQuery.of(context).size.width * 0.6 * p.x,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 800),
                      builder: (context, t, child) {
                        return Opacity(
                          opacity: (1.0 - t).clamp(0.0, 1.0),
                          child: Transform.translate(
                            offset: Offset(0, -40 * t),
                            child: Text(
                              p.emoji,
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _Particle {
  final String emoji;
  final double x;
  final bool isApplause;
  _Particle({required this.emoji, required this.x, required this.isApplause});
}

class _InteractionButton extends StatefulWidget {
  final String label;
  final String emoji;
  final Color color;
  final VoidCallback onTap;

  const _InteractionButton({
    required this.label,
    required this.emoji,
    required this.color,
    required this.onTap,
  });

  @override
  State<_InteractionButton> createState() => _InteractionButtonState();
}

class _InteractionButtonState extends State<_InteractionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween<double>(begin: 1.0, end: 0.92).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, child) => Transform.scale(
          scale: _scale.value,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: widget.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: widget.color.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(widget.emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                Text(
                  widget.label,
                  style: TextStyle(
                    color: widget.color,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final String label;
  final String emoji;
  final Color color;

  const _CountBadge(
      {required this.label, required this.emoji, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
