import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:auto_route/auto_route.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/routing/app_router.dart';
import '../entities/onboarding_item.dart';

@RoutePage()
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingItem> _onboardingItems = const [
    OnboardingItem(
      title: 'Numerous free trial courses',
      description: 'Free courses for you to find your way to learning',
      imagePath: 'assets/illustration.png',
      illustrationBackgroundColor: Color(0xFFE3F2FD),
    ),
    OnboardingItem(
      title: 'Quick and easy learning',
      description: 'Easy and fast learning at any time to help you improve various skills',
      imagePath: 'assets/illustration (1).png',
      illustrationBackgroundColor: Color(0xFFE8F5E9),
    ),
    OnboardingItem(
      title: 'Create your own study plan',
      description: 'Study according to the study plan, make study more motivated',
      imagePath: 'assets/illustration (2).png',
      illustrationBackgroundColor: Color(0xFFE3F2FD),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onSkip() {
    _navigateToAuth();
  }

  void _navigateToAuth() {
    context.router.replace(const SignUpRoute());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            if (_currentPage < _onboardingItems.length - 1)
              Padding(
                padding: const EdgeInsets.only(top: 20.0, left: 20.0, right: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _onSkip,
                      child: Text(
                        'Skip',
                        style: GoogleFonts.poppins(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _onboardingItems.length,
                itemBuilder: (context, index) {
                  return _buildOnboardingScreen(_onboardingItems[index], index);
                },
              ),
            ),
            _buildBottomSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildOnboardingScreen(OnboardingItem item, int index) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double availableHeight = constraints.maxHeight;
        final double topPadding = _currentPage < _onboardingItems.length - 1 ? 20.0 : 60.0;
        final double illustrationSize = (availableHeight * 0.45).clamp(160.0, 260.0);
        final double spacing = (availableHeight * 0.06).clamp(12.0, 32.0);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                flex: 5,
                child: Padding(
                  padding: EdgeInsets.only(top: topPadding),
                  child: _buildIllustration(item, illustrationSize),
                ),
              ),
              SizedBox(height: spacing),
              Flexible(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 200),
                  child: Text(
                    item.title,
                    style: GoogleFonts.poppins(
                      color: AppColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      height: 1.4,
                      letterSpacing: 0,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    softWrap: true,
                  ),
                ),
              ),
              SizedBox(height: spacing * 0.5),
              Flexible(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 250),
                  child: Text(
                    item.description,
                    style: GoogleFonts.poppins(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                      height: 1.8,
                      letterSpacing: 0,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    softWrap: true,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIllustration(OnboardingItem item, double size) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: Image.asset(
          item.imagePath,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildBottomSection() {
    if (_currentPage == _onboardingItems.length - 1) {
      return Container(
        padding: EdgeInsets.only(
          left: 24.0,
          right: 24.0,
          bottom: MediaQuery.of(context).padding.bottom + 10.0,
          top: 16.0,
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => context.router.replace(const SignUpRoute()),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Sign Up',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () => context.router.replace(const LoginRoute()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Log in',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: EdgeInsets.only(
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 100.0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          _onboardingItems.length,
          (index) => _buildDot(index == _currentPage),
        ),
      ),
    );
  }

  Widget _buildDot(bool isActive) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 28 : 8,
      height: 5,
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary : AppColors.dotInactive,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

