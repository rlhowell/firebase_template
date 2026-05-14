import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_providers.dart';
import '../../widgets/error_banner.dart';

class PhoneVerificationScreen extends ConsumerStatefulWidget {
  final String phoneNumber;

  const PhoneVerificationScreen({super.key, required this.phoneNumber});

  @override
  ConsumerState<PhoneVerificationScreen> createState() =>
      _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState
    extends ConsumerState<PhoneVerificationScreen> {
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();

  bool _codeSent = false;
  bool _isLoading = false;
  String? _verificationId;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.phoneNumber.isNotEmpty) {
      _phoneCtrl.text = widget.phoneNumber;
    }
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (_phoneCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please enter your phone number.');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });

    await ref.read(authServiceProvider).verifyPhoneNumber(
      phoneNumber: _phoneCtrl.text.trim(),
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Android auto-verification — GoRouter redirect handles navigation.
        await ref.read(authServiceProvider).signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _error = e.message ??
                'Verification failed. Check the number and try again.';
          });
        }
      },
      codeSent: (String verificationId, int? resendToken) {
        if (mounted) {
          setState(() {
            _verificationId = verificationId;
            _codeSent = true;
            _isLoading = false;
          });
        }
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
        if (mounted) setState(() => _isLoading = false);
      },
    );
  }

  Future<void> _verifyCode() async {
    if (_otpCtrl.text.trim().length != 6) {
      setState(() => _error = 'Please enter the 6-digit code.');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final success = await ref
        .read(authNotifierProvider.notifier)
        .signInWithPhone(_verificationId!, _otpCtrl.text.trim());

    if (!mounted) return;
    if (success) {
      context.go('/home');
    } else {
      setState(() {
        _isLoading = false;
        _error = ref.read(authNotifierProvider).error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Phone Sign In')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Text(
                _codeSent
                    ? 'Enter verification code'
                    : 'Enter your phone number',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _codeSent
                    ? 'We sent a 6-digit code to ${_phoneCtrl.text}'
                    : 'Include country code, e.g. +1 555 000 0000',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 40),
              if (_error != null) ...[
                ErrorBanner(message: _error!),
                const SizedBox(height: 16),
              ],
              if (!_codeSent) ...[
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _sendCode(),
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    hintText: '+1 555 000 0000',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: _isLoading ? null : _sendCode,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Send Code'),
                ),
              ] else ...[
                TextFormField(
                  controller: _otpCtrl,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _verifyCode(),
                  maxLength: 6,
                  decoration: const InputDecoration(
                    labelText: 'Verification Code',
                    prefixIcon: Icon(Icons.lock_outlined),
                  ),
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: _isLoading ? null : _verifyCode,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Verify'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () => setState(() {
                            _codeSent = false;
                            _error = null;
                            _otpCtrl.clear();
                          }),
                  child: const Text('Change phone number'),
                ),
              ],
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => context.go('/auth/login'),
                child: const Text('Back to Sign In'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
