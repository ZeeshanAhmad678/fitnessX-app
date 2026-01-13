import 'package:fitness_app/features/auth/login_screen.dart';
import 'package:fitness_app/features/home/home_screen.dart';
import 'package:fitness_app/features/auth/signup_screen.dart';
import 'package:fitness_app/features/onboarding/onboarding_screen.dart';
import 'package:go_router/go_router.dart';

final GoRouter router = GoRouter(
  initialLocation: '/onboarding',
  routes: [
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    //  Signup Route
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignupScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
  ],
);