import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../state/auth_provider.dart';
import '../widgets/common.dart';
import 'otp_screen.dart';

/// Mobile-number entry — matches the official app's "Welcome to Dropzy" screen.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _mobile = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _mobile.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _mobile.dispose();
    super.dispose();
  }

  bool get _valid => _mobile.text.trim().length == 10;

  Future<void> _getOtp() async {
    if (!_valid) return;
    setState(() => _loading = true);
    FocusScope.of(context).unfocus();
    try {
      await context.read<AuthProvider>().requestOtp(_mobile.text.trim());
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const OtpScreen()),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const DropzyIconTile(size: 72),
              const SizedBox(height: 28),
              const Text('Welcome to Dropzy',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: DropzyColors.ink)),
              const SizedBox(height: 8),
              const Text('Send parcels across cities',
                  style: TextStyle(fontSize: 16, color: DropzyColors.inkSoft)),
              const SizedBox(height: 44),
              const Text('Mobile number',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: DropzyColors.ink)),
              const SizedBox(height: 10),
              TextField(
                controller: _mobile,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _getOtp(),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                decoration: const InputDecoration(
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(left: 18, right: 8),
                    child: Text('+91',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: DropzyColors.ink)),
                  ),
                  prefixIconConstraints: BoxConstraints(minWidth: 0, minHeight: 0),
                  hintText: '10-digit mobile number',
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: (_valid && !_loading) ? _getOtp : null,
                child: _loading
                    ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                    : const Text('Get OTP'),
              ),
              const Spacer(),
              const Center(
                child: Text(
                  'By continuing you agree to our Terms & Privacy Policy',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: DropzyColors.inkSoft, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
