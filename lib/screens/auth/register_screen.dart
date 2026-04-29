import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../utils/helpers.dart';
import '../../config/theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _showOTP = false;
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isLoading = false;
      _showOTP = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('OTP sent to your email and phone'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _verifyOTP() async {
    if (_otpController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter OTP'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isLoading = false;
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Account created successfully!'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Red gradient header
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
                        'Create Account',
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Form content
              Padding(
                padding: const EdgeInsets.all(24),
                child: _showOTP ? _buildOTPForm() : _buildRegistrationForm(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRegistrationForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Create your account',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Fill in your details to get started',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  label: 'First Name',
                  hint: 'John',
                  controller: _firstNameController,
                  validator: Helpers.validateName,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomTextField(
                  label: 'Last Name',
                  hint: 'Doe',
                  controller: _lastNameController,
                  validator: Helpers.validateName,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Email Address',
            hint: 'john@example.com',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email_outlined,
            validator: Helpers.validateEmail,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Phone Number',
            hint: '9876543210',
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            prefixIcon: Icons.phone_outlined,
            validator: Helpers.validatePhone,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Password',
            hint: 'Enter password',
            controller: _passwordController,
            prefixIcon: Icons.lock_outlined,
            obscureText: true,
            validator: Helpers.validatePassword,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Confirm Password',
            hint: 'Confirm password',
            controller: _confirmPasswordController,
            prefixIcon: Icons.lock_outlined,
            obscureText: true,
            validator: Helpers.validatePassword,
          ),
          const SizedBox(height: 32),
          CustomButton(
            text: 'Create Account',
            onPressed: _register,
            isLoading: _isLoading,
          ),
          const SizedBox(height: 24),
          Center(
            child: RichText(
              text: TextSpan(
                text: 'Already have an account? ',
                style: Theme.of(context).textTheme.bodyMedium,
                children: [
                  TextSpan(
                    text: 'Sign In',
                    style: const TextStyle(
                      color: AppTheme.primaryRed,
                      fontWeight: FontWeight.w600,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        Navigator.of(context).pop();
                      },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOTPForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Icon(
            Icons.verified_user_outlined,
            size: 80,
            color: AppTheme.primaryRed,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Verify Your Account',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'We sent a verification code to ${_emailController.text}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 32),
        CustomTextField(
          label: 'Verification Code',
          hint: 'Enter 6-digit code',
          controller: _otpController,
          keyboardType: TextInputType.number,
          maxLines: 1,
        ),
        const SizedBox(height: 32),
        CustomButton(
          text: 'Verify & Create Account',
          onPressed: _verifyOTP,
          isLoading: _isLoading,
        ),
        const SizedBox(height: 16),
        Center(
          child: RichText(
            text: TextSpan(
              text: "Didn't receive code? ",
              style: Theme.of(context).textTheme.bodySmall,
              children: [
                TextSpan(
                  text: 'Resend',
                  style: const TextStyle(
                    color: AppTheme.primaryRed,
                    fontWeight: FontWeight.w600,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('OTP resent'),
                        ),
                      );
                    },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
