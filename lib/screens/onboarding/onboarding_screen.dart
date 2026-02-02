import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _precached = false;

  final List<Map<String, String>> _pages = [
    {
      'image': 'assets/img/leaf1.jpg',
      'title': 'Welcome to PD App',
      'body': 'Your AI-powered plant disease detector',
    },
    {
      'image': 'assets/img/leaf5.jpg',
      'title': 'Scan Leaves Instantly',
      'body': 'Take a photo – detect 51+ diseases offline',
    },
    {
      'image': 'assets/img/leaf10.jpg',
      'title': 'Get Treatment Tips',
      'body': 'Bilingual recommendations in English & Nepali',
    },
    {
      'image': 'assets/img/leaf15.jpg',
      'title': 'Set Care Reminders',
      'body': 'Never miss watering or checks – works offline',
    },
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_precached) {
      _loadImages();
      _precached = true;
    }
  }

  Future<void> _loadImages() async {
    try {
      for (var page in _pages) {
        await precacheImage(AssetImage(page['image']!), context);
      }
    } catch (e) {
      // Handle error if needed
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('firstLaunch', false);
    if (mounted) context.go('/');
  }

  Widget _buildPage(int index) {
    final page = _pages[index];
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(page['image']!, fit: BoxFit.cover, cacheWidth: 800),
        Container(color: Colors.white.withOpacity(0.25)), // Brighter overlay
        SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    page['title']!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[800],
                      shadows: [
                        Shadow(
                          blurRadius: 6,
                          color: Colors.white70,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 30),
                  Text(
                    page['body']!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.black87,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
              SizedBox(height: 20),
              Text(
                'Loading...',
                style: TextStyle(fontSize: 18, color: Colors.green[700]),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            physics:
                const NeverScrollableScrollPhysics(), // No swipe – buttons only
            itemCount: _pages.length,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (context, index) => _buildPage(index),
          ),
          // Bottom controls: Dots + Back/Next/Done
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (i) => AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      margin: EdgeInsets.symmetric(horizontal: 6),
                      height: 12,
                      width: _currentIndex == i ? 28 : 12,
                      decoration: BoxDecoration(
                        color: _currentIndex == i
                            ? Colors.green[700]
                            : Colors.green[200],
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_currentIndex > 0)
                      TextButton.icon(
                        onPressed: () => _controller.previousPage(
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        ),
                        icon: Icon(
                          Icons.arrow_back_ios,
                          color: Colors.green[700],
                        ),
                        label: Text(
                          'Back',
                          style: TextStyle(
                            color: Colors.green[700],
                            fontSize: 18,
                          ),
                        ),
                      )
                    else
                      SizedBox(width: 80),
                    ElevatedButton(
                      onPressed: () {
                        if (_currentIndex == _pages.length - 1) {
                          _finishOnboarding();
                        } else {
                          _controller.nextPage(
                            duration: Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        padding: EdgeInsets.symmetric(
                          horizontal: 60,
                          vertical: 20,
                        ),
                      ),
                      child: Text(
                        _currentIndex == _pages.length - 1
                            ? 'Get Started'
                            : 'Next',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
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
