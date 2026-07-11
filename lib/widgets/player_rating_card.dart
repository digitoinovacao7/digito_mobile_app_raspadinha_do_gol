import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as dart_math;
import '../models/player_rating.dart';

class PlayerRatingCard extends StatefulWidget {
  final PlayerRating player;
  final double? userRating; // nota já dada pelo usuário (null = não votou ainda)
  final Function(double rating) onRate;

  const PlayerRatingCard({
    super.key,
    required this.player,
    required this.userRating,
    required this.onRate,
  });

  @override
  State<PlayerRatingCard> createState() => _PlayerRatingCardState();
}

class _PlayerRatingCardState extends State<PlayerRatingCard>
    with SingleTickerProviderStateMixin {
  late double _sliderValue;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _sliderValue = widget.userRating ?? 5.0;
  }

  @override
  void didUpdateWidget(PlayerRatingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userRating != widget.userRating && !_isDragging) {
      _sliderValue = widget.userRating ?? _sliderValue;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Color _ratingColor(double v) {
    if (v >= 8) return const Color(0xFF39FF14); // neon green
    if (v >= 6) return const Color(0xFFFFD700); // gold
    if (v >= 4) return const Color(0xFFFF9800); // orange
    return const Color(0xFFFF4444); // red
  }

  String _positionAbbr(String pos) {
    const map = {
      'Goalkeeper': 'GOL',
      'Defender': 'DEF',
      'Midfielder': 'MEI',
      'Attacker': 'ATA',
      'Forward': 'ATA',
    };
    return map[pos] ?? pos.substring(0, dart_math.min(3, pos.length)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final color = _ratingColor(_sliderValue);
    final hasVoted = widget.userRating != null;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _isDragging ? color.withValues(alpha: 0.6) : Colors.white10,
          width: 1.5,
        ),
        boxShadow: _isDragging
            ? [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 12)]
            : [],
      ),
      child: Row(
        children: [
          // Avatar com número da camisa
          Stack(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: color.withValues(alpha: 0.15),
                child: Text(
                  '${widget.player.shirtNumber}',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _positionAbbr(widget.player.position),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 12),

          // Nome e slider
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        widget.player.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Média da torcida
                    if (widget.player.ratingCount > 0)
                      Text(
                        '⭐ ${widget.player.avgRating.toStringAsFixed(1)}',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),

                // Slider
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: color,
                    inactiveTrackColor: Colors.white12,
                    thumbColor: color,
                    overlayColor: color.withValues(alpha: 0.2),
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 10),
                    trackHeight: 5,
                    valueIndicatorColor: color,
                    valueIndicatorTextStyle: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: Slider(
                    value: _sliderValue,
                    min: 1.0,
                    max: 10.0,
                    divisions: 9,
                    label: _sliderValue.toStringAsFixed(0),
                    onChangeStart: (_) {
                      setState(() => _isDragging = true);
                      HapticFeedback.selectionClick();
                    },
                    onChanged: (v) {
                      setState(() => _sliderValue = v);
                      HapticFeedback.selectionClick();
                    },
                    onChangeEnd: (v) {
                      setState(() => _isDragging = false);
                      widget.onRate(v);
                    },
                  ),
                ),

                // Label da nota do usuário
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      hasVoted
                          ? 'Sua nota: ${_sliderValue.toStringAsFixed(0)}'
                          : 'Deslize para avaliar',
                      style: TextStyle(
                        color: hasVoted ? color : Colors.white38,
                        fontSize: 11,
                        fontWeight:
                            hasVoted ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    if (widget.player.ratingCount > 0)
                      Text(
                        '${widget.player.ratingCount} votos',
                        style: const TextStyle(
                          color: Colors.white24,
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
