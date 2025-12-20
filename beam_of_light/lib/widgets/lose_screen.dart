import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';

/// LoseScreen - Displayed when player runs out of hearts
class LoseScreen extends StatefulWidget {
  const LoseScreen({super.key});

  @override
  State<LoseScreen> createState() => _LoseScreenState();
}

class _LoseScreenState extends State<LoseScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        color: Colors.black.withValues(alpha: 0.85),
        child: Center(
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Neon red glow text
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFFFF0044), Color(0xFFFF4466)],
                  ).createShader(bounds),
                  child: const Text(
                    'FAILED',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 64,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 8,
                      shadows: [
                        Shadow(
                          color: Color(0xFFFF0044),
                          blurRadius: 20,
                        ),
                        Shadow(
                          color: Color(0xFFFF0044),
                          blurRadius: 40,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 60),
                // Minimal neon buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _NeonButton(
                      label: 'RETRY',
                      onPressed: () {
                        context.read<GameProvider>().resetLevel();
                      },
                      color: const Color(0xFFFF0044),
                    ),
                    const SizedBox(width: 32),
                    _NeonButton(
                      label: 'MENU',
                      onPressed: () {
                        context.read<GameProvider>().resetLevel();
                      },
                      color: const Color(0xFF666666),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NeonButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Color color;

  const _NeonButton({
    required this.label,
    required this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(
            color: color.withValues(alpha: 0.8),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 14,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w300,
            letterSpacing: 4,
            shadows: [
              Shadow(
                color: color.withValues(alpha: 0.8),
                blurRadius: 6,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
