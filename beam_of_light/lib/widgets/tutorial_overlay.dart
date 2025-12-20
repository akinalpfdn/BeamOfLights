import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// TutorialOverlay - Shows game instructions on first launch
class TutorialOverlay extends StatefulWidget {
  final VoidCallback onDismiss;

  const TutorialOverlay({
    super.key,
    required this.onDismiss,
  });

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();

  /// Check if tutorial should be shown
  static Future<bool> shouldShow() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool('tutorial_seen') ?? false);
  }

  /// Mark tutorial as seen
  static Future<void> markAsSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tutorial_seen', true);
  }
}

class _TutorialOverlayState extends State<TutorialOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() async {
    await TutorialOverlay.markAsSeen();
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        color: const Color(0xF0000000), // 95% black overlay
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Title
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFF00FF88), Color(0xFF00FFFF)],
                    ).createShader(bounds),
                    child: const Text(
                      'HOW TO PLAY',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 6,
                        shadows: [
                          Shadow(
                              color: Color(0xFF00FF88), blurRadius: 20),
                          Shadow(
                              color: Color(0xFF00FF88), blurRadius: 40),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Instructions
                  _buildInstruction(
                    icon: Icons.touch_app,
                    title: 'TAP THE BEAMS',
                    description:
                        'Tap on a neon beam to slide it in the direction of its arrow',
                  ),

                  const SizedBox(height: 32),

                  _buildInstruction(
                    icon: Icons.timeline,
                    title: 'CLEAR ALL BEAMS',
                    description:
                        'Remove all beams from the grid to complete the level',
                  ),

                  const SizedBox(height: 32),

                  _buildInstruction(
                    icon: Icons.warning_amber_rounded,
                    title: 'AVOID COLLISIONS',
                    description:
                        'Beams cannot cross paths. Collisions will cost you a heart',
                  ),

                  const SizedBox(height: 32),

                  _buildInstruction(
                    icon: Icons.favorite,
                    title: 'LIMITED HEARTS',
                    description:
                        'You have limited hearts per level. Lose them all and the level resets',
                  ),

                  const SizedBox(height: 64),

                  // Start button
                  _NeonButton(
                    label: 'START PLAYING',
                    onPressed: _dismiss,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstruction({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color(0xFF00FF88).withValues(alpha: 0.3),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: const Color(0xFF00FF88),
            size: 32,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF00FF88),
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(
                    color: Color(0xFFCCCCCC),
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                    height: 1.4,
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

/// Neon-styled button
class _NeonButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _NeonButton({
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(
            color: const Color(0xFF00FF88),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              color: Color(0x4000FF88),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF00FF88),
            fontSize: 18,
            fontWeight: FontWeight.w400,
            letterSpacing: 3,
          ),
        ),
      ),
    );
  }
}
