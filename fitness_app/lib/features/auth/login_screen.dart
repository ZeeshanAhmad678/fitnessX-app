import 'package:fitness_app/constants/app_colors.dart';
import 'package:fitness_app/features/auth/auth_service.dart'; // Import Auth Service
import 'package:fitness_app/shared/custom_textfield.dart';
import 'package:fitness_app/shared/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // 1. Controllers to capture user input
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // 2. The Actual Login Logic
  void _handleLogin() async {
    // Validate inputs
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = AuthService();
      // Call Firebase Sign In
      await authService.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      // If successful, navigate to Home
      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      // Show error if password is wrong or user doesn't exist
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Login Failed: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 50.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              const Text(
                "Hey there,",
                style: TextStyle(fontSize: 16, color: AppColors.blackText),
              ),
              const Text(
                "Welcome Back",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.blackText),
              ),
              const SizedBox(height: 40),
              
              // Email Input
              CustomTextField(
                controller: _emailController, // Connect Controller
                hintText: "Email",
                prefixIcon: Icons.email_outlined,
              ),
              const SizedBox(height: 15),
              
              // Password Input
              CustomTextField(
                controller: _passwordController, // Connect Controller
                hintText: "Password",
                prefixIcon: Icons.lock_outline,
                isPassword: true,
              ),
              
              const SizedBox(height: 10),
              const Align(
                alignment: Alignment.centerRight,
                child: Text(
                  "Forgot your password?",
                  style: TextStyle(color: AppColors.grayText, fontSize: 12),
                ),
              ),
              const SizedBox(height: 250), // Spacer
              
              // Login Button
              _isLoading
                  ? const CircularProgressIndicator()
                  : PrimaryButton(
                      text: "Login",
                      onPressed: _handleLogin, // Call the logic
                    ),
              
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Don’t have an account yet? "),
                  GestureDetector(
                    onTap: () => context.go('/signup'),
                    child: const Text(
                      "Register",
                      style: TextStyle(
                        color: AppColors.secondaryBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}