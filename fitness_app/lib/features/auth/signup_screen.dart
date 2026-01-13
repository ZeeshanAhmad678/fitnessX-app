import 'package:fitness_app/constants/app_colors.dart';
import 'package:fitness_app/shared/custom_textfield.dart';
import 'package:fitness_app/shared/primary_button.dart';
import 'package:fitness_app/features/auth/auth_service.dart'; // Import your auth service
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

 void _handleSignup() async {
  setState(() => _isLoading = true);
  
  try {
    final authService = AuthService(); 
    final user = await authService.signUp(
      _emailController.text.trim(), 
      _passwordController.text.trim(), 
      _firstNameController.text.trim()
    );

    if (user != null && mounted) {
      context.go('/home');
    }
  } catch (e) {
    // This will now show the actual error from Firebase (e.g. "Email already in use")
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
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
                "Create an account",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.blackText),
              ),
              const SizedBox(height: 40),
              
              // First Name
              CustomTextField(
                controller: _firstNameController,
                hintText: "First Name",
                prefixIcon: Icons.person_outline,
              ),
              const SizedBox(height: 15),
              
              // Last Name
              CustomTextField(
                controller: _lastNameController,
                hintText: "Last Name",
                prefixIcon: Icons.person_outline,
              ),
              const SizedBox(height: 15),

              // Email
              CustomTextField(
                controller: _emailController,
                hintText: "Email",
                prefixIcon: Icons.email_outlined,
              ),
              const SizedBox(height: 15),

              // Password
              CustomTextField(
                controller: _passwordController,
                hintText: "Password",
                prefixIcon: Icons.lock_outline,
                isPassword: true,
              ),
              
              const SizedBox(height: 20),
              
              // Register Button
              _isLoading 
                ? const CircularProgressIndicator()
                : PrimaryButton(
                    text: "Register",
                    onPressed: _handleSignup,
                  ),
              
              const SizedBox(height: 20),
              
              // OR Divider
              Row(
                children: const [
                  Expanded(child: Divider(color: AppColors.grayText)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text("or"),
                  ),
                  Expanded(child: Divider(color: AppColors.grayText)),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Login Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("If you have already an account, "),
                  GestureDetector(
                    onTap: () => context.go('/login'),
                    child: const Text(
                      "Login",
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