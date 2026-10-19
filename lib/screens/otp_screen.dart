import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../state/auth_provider.dart';

/// 4-digit OTP verification — matches the official app's "Verify OTP" screen.
class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});
  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otp = TextEditingController();
  final _focus = FocusNode();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _otp.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _otp.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_otp.text.trim().length < 4) return;
    setState(() { _loading = true; _error = null; });
    FocusScope.of(context).unfocus();
    try {
      await context.read<AuthProvider>().verifyOtp(_otp.text.trim());
      // Auth gate swaps the root to HomeShell; pop this pushed route so the
      // newly-authenticated Home is revealed underneath.
      if (mounted && context.read<AuthProvider>().isAuthenticated) {
        Navigator.of(context).popUntil((r) => r.isFirst);
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mobile = context.read<AuthProvider>().mobile ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('Verify OTP')),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Enter the 4-digit code sent to +91 $mobile',
                style: const TextStyle(fontSize: 16, color: DropzyColors.inkSoft)),
            const SizedBox(height: 28),
            // Hidden field drives the boxes.
            Stack(
              children: [
                Opacity(
                  opacity: 0,
                  child: TextField(
                    controller: _otp,
                    focusNode: _focus,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    onSubmitted: (_) => _verify(),
                  ),
                ),
                GestureDetector(
                  onTap: () => _focus.requestFocus(),
                  child: Container(
                    height: 70,
                    decoration: BoxDecoration(
                      color: DropzyColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: DropzyColors.line),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (i) {
                        final filled = i < _otp.text.length;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: filled ? DropzyColors.ink : DropzyColors.line,
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 14),
              Text(_error!, style: const TextStyle(color: DropzyColors.primary)),
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: (_otp.text.length == 4 && !_loading) ? _verify : null,
              child: _loading
                  ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                  : const Text('Verify & Continue'),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: _loading
                    ? null
                    : () => context.read<AuthProvider>().requestOtp(mobile),
                child: const Text('Resend OTP'),
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Text('Demo: use code 1234',
                  style: TextStyle(color: DropzyColors.inkSoft, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}
