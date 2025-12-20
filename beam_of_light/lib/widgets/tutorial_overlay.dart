import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// TutorialOverlay - Shows game instructions on first launch with page slider
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
  final PageController _pageController = PageController();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  int _currentPage = 0;

  final List<_TutorialPage> _pages = [
    _TutorialPage(
      icon: Icons.touch_app,
      title: 'TAP BEAMS',
      description: 'Tap on a neon beam to slide it in the direction of its arrow',
      accentColor: Color(0xFF00CED1), // Cyan
    ),
    _TutorialPage(
      icon: Icons.timeline,
      title: 'CLEAR GRID',
      description: 'Remove all beams from the grid to complete the level',
      accentColor: Color(0xFFFF69B4), // Pink
    ),
    _TutorialPage(
      icon: Icons.warning_amber_rounded,
      title: 'AVOID COLLISIONS',
      description: 'Beams cannot cross paths - collisions cost you hearts',
      accentColor: Color(0xFFFFA500), // Orange
    ),
    _TutorialPage(
      icon: Icons.favorite,
      title: 'LIMITED HEARTS',
      description: 'Lose all hearts and the level resets',
      accentColor: Color(0xFF9370DB), // Purple
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _dismiss() async {
    await TutorialOverlay.markAsSeen();
    await _fadeController.reverse();
    widget.onDismiss();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _dismiss();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        color: const Color(0xFF000000),
        child: SafeArea(
          child: Column(
            children: [
              // Header with logo/title
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      _pages[_currentPage].accentColor,
                      _pages[_currentPage].accentColor.withValues(alpha: 0.6),
                    ],
                  ).createShader(bounds),
                  child: const Text(
                    'BEAM OF LIGHTS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w200,
                      letterSpacing: 8,
                    ),
                  ),
                ),
              ),

              // Page view
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    return _buildPage(_pages[index]);
                  },
                ),
              ),

              // Page indicators
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_pages.length, (index) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? _pages[_currentPage].accentColor
                            : Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: _currentPage == index
                            ? [
                                BoxShadow(
                                  color: _pages[_currentPage]
                                      .accentColor
                                      .withValues(alpha: 0.5),
                                  blurRadius: 8,
                                ),
                              ]
                            : null,
                      ),
                    );
                  }),
                ),
              ),

              // Next/Start button
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: _NeonButton(
                  label: _currentPage == _pages.length - 1 ? 'START' : 'NEXT',
                  color: _pages[_currentPage].accentColor,
                  onPressed: _nextPage,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage(_TutorialPage page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon with glow effect
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: page.accentColor.withValues(alpha: 0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: page.accentColor.withValues(alpha: 0.3),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Icon(
                    page.icon,
                    size: 80,
                    color: page.accentColor,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 60),

          // Title
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [
                page.accentColor,
                page.accentColor.withValues(alpha: 0.8),
              ],
            ).createShader(bounds),
            child: Text(
              page.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w300,
                letterSpacing: 6,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Description
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFCCCCCC),
              fontSize: 16,
              fontWeight: FontWeight.w300,
              height: 1.6,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _TutorialPage {
  final IconData icon;
  final String title;
  final String description;
  final Color accentColor;

  _TutorialPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.accentColor,
  });
}

/// Neon-styled button
class _NeonButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _NeonButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          border: Border.all(
            color: color.withValues(alpha: 0.8),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.w300,
            letterSpacing: 6,
          ),
        ),
      ),
    );
  }
}
