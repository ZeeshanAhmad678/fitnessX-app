import 'package:fitness_app/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  bool isLastPage = false;

  final List<Map<String, String>> _pages = [
    {
      "image": "assets/images/IntroScreen1.png", 
      "title": "Track Your Goal",
      "desc": "Don't worry if you have trouble determining your goals. We can help you determine your goals and track them."
    },
    {
      "image": "assets/images/IntroScreen2.png",
      "title": "Get Burn",
      "desc": "Let’s keep burning to achieve your goals. It hurts only temporarily, but giving up hurts forever."
    },
    {
      "image": "assets/images/IntroScreen3.png",
      "title": "Eat Well",
      "desc": "Start a healthy lifestyle with us. We can determine your diet everyday. Healthy eating is fun!"
    },
    {
      "image": "assets/images/IntroScreen4.png",
      "title": "Improve Sleep Quality",
      "desc": "Improve the quality of your sleep with us, good quality sleep can bring a good mood in the morning."
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. THE PAGE VIEW (Images & Text)
          PageView.builder(
            controller: _controller,
            itemCount: _pages.length,
            onPageChanged: (index) {
              setState(() {
                isLastPage = index == _pages.length - 1;
              });
            },
            itemBuilder: (context, index) {
              return Column(
                children: [
                  // Top Image Section with Curved Background
                  Expanded(
                    flex: 6,
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryBlue, 
                        borderRadius: BorderRadius.only(
                          bottomRight: Radius.circular(50), 
                          bottomLeft: Radius.circular(50)
                        )
                      ),
                        // Ensure you have these images in your assets folder
                        child: Image.asset(_pages[index]['image']!, fit: BoxFit.cover),
                      
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(30.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          Text(
                            _pages[index]['title']!,
                            style: const TextStyle(
                              fontSize: 24, 
                              fontWeight: FontWeight.bold, 
                              color: AppColors.blackText
                            ),
                          ),
                          const SizedBox(height: 15),
                          Text(
                            _pages[index]['desc']!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14, 
                              color: AppColors.grayText,
                              height: 1.5
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              );
            },
          ),

          // 2. SKIP BUTTON (Bottom Left)
          // We hide it on the last page since the user is about to finish anyway
          if (!isLastPage)
            Positioned(
              bottom: 50,
              left: 30,
              child: TextButton(
                onPressed: () {
                  // Jump directly to Login
                  context.go('/login');
                },
                child: const Text(
                  "Skip",
                  style: TextStyle(
                    color: AppColors.grayText,
                    fontSize: 16,
                  ),
                ),
              ),
            ),

          // 3. NEXT / GET STARTED BUTTON (Bottom Right)
          Positioned(
            bottom: 50,
            right: 30,
            child: isLastPage
                ? SizedBox(
                    height: 60,
                    width: 60,
                    child: FloatingActionButton(
                      onPressed: () => context.go('/login'),
                      backgroundColor: AppColors.secondaryBlue,
                      elevation: 0,
                      child: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
                    ),
                  )
                : Container(
                    height: 60,
                    width: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.secondaryBlue, width: 2),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_forward_ios, color: AppColors.secondaryBlue, size: 20),
                      onPressed: () {
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeIn,
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}