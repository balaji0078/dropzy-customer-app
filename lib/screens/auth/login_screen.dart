import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../utils/helpers.dart';
import '../../config/constants.dart';
import '../../config/theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showPassword = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error ?? 'Login failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Red gradient header with logo
              Container(
                decoration: BoxDecoration(
                  gradient: AppTheme.redGradient,
                ),
                padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.local_shipping,
                        size: 56,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Welcome Back',
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // White card with form
              Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sign in to your account to continue',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 32),
                      CustomTextField(
                        label: 'Email Address',
                        hint: 'Enter your email',
                        controller: _emailController,
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: Helpers.validateEmail,
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        label: 'Password',
                        hint: 'Enter your password',
                        controller: _passwordController,
                        prefixIcon: Icons.lock_outlined,
                        obscureText: true,
                        validator: Helpers.validatePassword,
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {},
                          child: const Text('Forgot Password?'),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Consumer<AuthProvider>(
                        builder: (context, authProvider, _) {
                          return CustomButton(
                            text: 'Sign In',
                            onPressed: _login,
                            isLoading: authProvider.isLoading,
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      const Center(
                        child: Text(
                          'OR',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildSocialButton(
                        icon: Icons.mail,
                        label: 'Continue with Google',
                        onPressed: () {},
                      ),
                      const SizedBox(height: 12),
                      _buildSocialButton(
                        icon: Icons.apple,
                        label: 'Continue with Apple',
                        onPressed: () {},
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: RichText(
                          text: TextSpan(
                            text: "Don't have an account? ",
                            style: Theme.of(context).textTheme.bodyMedium,
                            children: [
                              TextSpan(
                                text: 'Register',
                                style: TextStyle(
                                  color: AppTheme.primaryRed,
                                  fontWeight: FontWeight.w600,
                                ),
                                recognizer: _handleRegisterTap(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      icon: Icon(icon),
      label: Text(label),
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 50),
        side: const BorderSide(color: AppTheme.primaryRed, width: 1.5),
        foregroundColor: AppTheme.primaryRed,
      ),
    );
  }

  TapGestureRecognizer _handleRegisterTap() {
    return TapGestureRecognizer()
      ..onTap = () {
        Navigator.of(context).pushNamed('/register');
      };
  }
}
