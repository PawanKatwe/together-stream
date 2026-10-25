import 'dart:math';
import 'package:flutter/material.dart';

class FloatingEmojiData {
  final String id;
  final String emoji;
  final double startX; // 0.0 to 1.0 (horizontal position)
  final double sway; // horizontal drift in pixels
  final double scale;
  final DateTime createdAt;

  FloatingEmojiData({
    required this.id,
    required this.emoji,
    required this.startX,
    required this.sway,
    required this.scale,
    required this.createdAt,
  });
}

class FloatingEmojiOverlay extends StatelessWidget {
  final List<FloatingEmojiData> emojis;

  const FloatingEmojiOverlay({super.key, required this.emojis});

  @override
  Widget build(BuildContext context) {
    if (emojis.isEmpty) return const SizedBox.shrink();

    final size = MediaQuery.of(context).size;

    return IgnorePointer(
      child: Stack(
        children: emojis.map((item) {
          return _SingleFloatingEmoji(
            key: ValueKey(item.id),
            data: item,
            screenSize: size,
          );
        }).toList(),
      ),
    );
  }
}

class _SingleFloatingEmoji extends StatefulWidget {
  final FloatingEmojiData data;
  final Size screenSize;

  const _SingleFloatingEmoji({
    super.key,
    required this.data,
    required this.screenSize,
  });

  @override
  State<_SingleFloatingEmoji> createState() => _SingleFloatingEmojiState();
}

class _SingleFloatingEmojiState extends State<_SingleFloatingEmoji>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _progress = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _progress,
      builder: (context, child) {
        final t = _progress.value;
        // Float upwards from bottom (80% down) to top (15% down)
        final startBottom = widget.screenSize.height * 0.20;
        final endBottom = widget.screenSize.height * 0.85;
        final currentBottom = startBottom + (endBottom - startBottom) * t;

        // Gentle sinusoidal sway
        final currentX = (widget.data.startX * widget.screenSize.width) +
            (sin(t * pi * 3) * widget.data.sway);

        // Fade in quickly, then fade out near end
        double opacity = 1.0;
        if (t < 0.15) {
          opacity = t / 0.15;
        } else if (t > 0.65) {
          opacity = (1.0 - t) / 0.35;
        }
        opacity = opacity.clamp(0.0, 1.0);

        // Slight pop scale
        final currentScale = widget.data.scale * (0.8 + 0.4 * sin(t * pi));

        return Positioned(
          left: currentX,
          bottom: currentBottom,
          child: Opacity(
            opacity: opacity,
            child: Transform.scale(
              scale: currentScale,
              child: child,
            ),
          ),
        );
      },
      child: Text(
        widget.data.emoji,
        style: const TextStyle(fontSize: 34),
      ),
    );
  }
}

class ReactionPickerBar extends StatelessWidget {
  final ValueChanged<String> onSelectEmoji;
  final VoidCallback? onClose;

  static const List<String> availableEmojis = ['❤️', '💋', '😂', '🥺', '🔥', '👏'];

  const ReactionPickerBar({
    super.key,
    required this.onSelectEmoji,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xF01D171E),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFE2849C).withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.6),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: availableEmojis.map((emoji) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: InkWell(
              onTap: () => onSelectEmoji(emoji),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 26),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
