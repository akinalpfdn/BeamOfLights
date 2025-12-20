import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';

/// WinScreen - Displayed when level is completed
class WinScreen extends StatefulWidget {
  const WinScreen({super.key});

  @override
  State<WinScreen> createState() => _WinScreenState();
}

class _WinScreenState extends State<WinScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
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
                // Neon glow text
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFF00FF88), Color(0xFF00FFFF)],
                  ).createShader(bounds),
                  child: const Text(
                    'COMPLETE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 8,
                      shadows: [
                        Shadow(
                          color: Color(0xFF00FF88),
                          blurRadius: 30,
                        ),
                        Shadow(
                          color: Color(0xFF00FF88),
                          blurRadius: 60,
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
                      label: 'NEXT',
                      onPressed: () {
                        context.read<GameProvider>().nextLevel();
                      },
                    ),
                    const SizedBox(width: 32),
                    _NeonButton(
                      label: 'MENU',
                      onPressed: () {
                        context.read<GameProvider>().resetLevel();
                      },
                      secondary: true,
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
  final bool secondary;

  const _NeonButton({
    required this.label,
    required this.onPressed,
    this.secondary = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = secondary ? const Color(0xFF666666) : const Color(0xFF00FF88);

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
              blurRadius: 15,
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
