import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _iconPulseController;
  late AnimationController _backgroundController;
  late AnimationController _particleController;
  late Animation<double> _iconPulseAnimation;
  late Animation<double> _iconRotationAnimation;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _particleAnimation;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Welcome to PDF Viewer',
      description:
          'Experience the most beautiful and intuitive PDF viewing experience. Read, navigate, and manage your documents with ease.',
      icon: Icons.picture_as_pdf_rounded,
      color: const Color(0xFF667EEA),
      gradient: [const Color(0xFF667EEA), const Color(0xFF764BA2)],
    ),
    OnboardingPage(
      title: 'Easy File Access',
      description:
          'Quickly open PDF files from your device storage. Browse and select documents in seconds with our streamlined file picker.',
      icon: Icons.folder_open_rounded,
      color: const Color(0xFFF093FB),
      gradient: [const Color(0xFFF093FB), const Color(0xFFF5576C)],
    ),
    OnboardingPage(
      title: 'Smart Bookmarks',
      description:
          'Save your favorite PDFs for quick access. Never lose track of important documents with our intelligent bookmarking system.',
      icon: Icons.bookmark_rounded,
      color: const Color(0xFF4FACFE),
      gradient: [const Color(0xFF4FACFE), const Color(0xFF00F2FE)],
    ),
    OnboardingPage(
      title: 'Recent Files History',
      description:
          'Access your recently opened PDFs instantly. Your reading history is automatically saved for your convenience.',
      icon: Icons.history_rounded,
      color: const Color(0xFF43E97B),
      gradient: [const Color(0xFF43E97B), const Color(0xFF38F9D7)],
    ),
    OnboardingPage(
      title: 'Ready to Start!',
      description:
          'You\'re all set! Start exploring your PDF documents with smooth navigation, zoom controls, and an amazing reading experience.',
      icon: Icons.rocket_launch_rounded,
      color: const Color(0xFFFA709A),
      gradient: [const Color(0xFFFA709A), const Color(0xFFFEE140)],
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Icon pulse animation controller (continuous)
    _iconPulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    // Background gradient animation controller (continuous)
    _backgroundController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat();

    // Particle animation controller (continuous)
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    )..repeat();

    // Icon pulse animation
    _iconPulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _iconPulseController, curve: Curves.easeInOut),
    );

    // Icon rotation animation
    _iconRotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _iconPulseController, curve: Curves.linear),
    );

    // Background animation
    _backgroundAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _backgroundController, curve: Curves.easeInOut),
    );

    // Particle animation
    _particleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _particleController, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _iconPulseController.dispose();
    _backgroundController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreenWrapper()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _backgroundController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(
                    _pages[_currentPage].gradient[0],
                    _pages[_currentPage].gradient[1],
                    _backgroundAnimation.value,
                  )!,
                  Color.lerp(
                    _pages[_currentPage].gradient[1],
                    _pages[_currentPage].gradient[0],
                    _backgroundAnimation.value,
                  )!,
                ],
              ),
            ),
            child: Stack(
              children: [
                // Animated Particles Background
                AnimatedBuilder(
                  animation: _particleController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: OnboardingParticlePainter(
                        _particleAnimation.value,
                        _pages[_currentPage].gradient[0],
                      ),
                      size: Size.infinite,
                    );
                  },
                ),
                SafeArea(
                  child: Column(
                    children: [
                      // Skip button
                      if (_currentPage < _pages.length - 1)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Align(
                            alignment: Alignment.topRight,
                            child: TextButton(
                              onPressed: _completeOnboarding,
                              child: Text(
                                'Skip',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
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

                      // Page indicator
                      _buildPageIndicator(),

                      // Navigation buttons
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Previous button
                            if (_currentPage > 0)
                              TextButton(
                                onPressed: () {
                                  _pageController.previousPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                },
                                child: Text(
                                  'Previous',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              )
                            else
                              const SizedBox(width: 80),

                            // Next/Get Started button
                            ElevatedButton(
                              onPressed: () {
                                if (_currentPage < _pages.length - 1) {
                                  _pageController.nextPage(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                } else {
                                  _completeOnboarding();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: _pages[_currentPage].color,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 5,
                              ),
                              child: Text(
                                _currentPage < _pages.length - 1
                                    ? 'Next'
                                    : 'Get Started',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
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
        },
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Continuously Animated Icon
            AnimatedBuilder(
              animation: _iconPulseController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _iconPulseAnimation.value,
                  child: Transform.rotate(
                    angle: _iconRotationAnimation.value * 0.1,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            Colors.white.withOpacity(0.3),
                            Colors.white.withOpacity(0.1),
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.3),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Glowing effect
                          Container(
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                colors: [
                                  Colors.white.withOpacity(0.2),
                                  Colors.transparent,
                                ],
                              ),
                              shape: BoxShape.circle,
                            ),
                          ),
                          // Icon
                          Icon(page.icon, size: 100, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 60),

            // Title with continuous glow effect
            AnimatedBuilder(
              animation: _iconPulseController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, 2 * (0.5 - _iconPulseAnimation.value)),
                  child: Text(
                    page.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1,
                      shadows: [
                        Shadow(
                          color: Colors.white.withOpacity(
                            0.5 * _iconPulseAnimation.value,
                          ),
                          blurRadius: 20,
                        ),
                        Shadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 30),

            // Description with subtle animation
            Text(
              page.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.95),
                height: 1.6,
                letterSpacing: 0.5,
                shadows: [
                  Shadow(color: Colors.black.withOpacity(0.2), blurRadius: 5),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _pages.length,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentPage == index ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: _currentPage == index
                ? Colors.white
                : Colors.white.withOpacity(0.4),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final List<Color> gradient;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.gradient,
  });
}

// Particle Painter for onboarding background
class OnboardingParticlePainter extends CustomPainter {
  final double animationValue;
  final Color baseColor;

  OnboardingParticlePainter(this.animationValue, this.baseColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Draw floating particles
    for (int i = 0; i < 30; i++) {
      final x =
          (size.width * (i * 0.033) +
              (size.width * 0.1) * (animationValue + i * 0.1) % 1.0) %
          size.width;
      final y =
          (size.height * 0.3 +
          (size.height * 0.4) *
              (0.5 + 0.5 * (animationValue + i * 0.15) % 1.0));
      final radius = 1.5 + (i % 4) * 1.0;
      final opacity = 0.1 + (i % 3) * 0.05;

      paint.color = baseColor.withOpacity(opacity);

      canvas.drawCircle(Offset(x, y), radius, paint);
    }

    // Draw larger floating circles
    for (int i = 0; i < 10; i++) {
      final x =
          (size.width * (i * 0.1) +
              (size.width * 0.05) * (animationValue + i * 0.2) % 1.0) %
          size.width;
      final y =
          (size.height * 0.2 +
          (size.height * 0.6) *
              (0.3 + 0.7 * (animationValue + i * 0.25) % 1.0));
      final radius = 3.0 + (i % 2) * 2.0;

      paint.color = baseColor.withOpacity(0.08);

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
