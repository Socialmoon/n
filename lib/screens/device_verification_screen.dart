import 'package:flutter/material.dart';
import '../models/member.dart';
import '../services/email_otp_service.dart';

class DeviceVerificationScreen extends StatefulWidget {
  const DeviceVerificationScreen({
    required this.member,
    required this.onVerified,
    super.key,
  });

  final Member member;
  final VoidCallback onVerified;

  @override
  State<DeviceVerificationScreen> createState() =>
      _DeviceVerificationScreenState();
}

class _DeviceVerificationScreenState extends State<DeviceVerificationScreen> {
  final EmailOtpService _emailOtpService = EmailOtpService();
  final _mpinController = TextEditingController();
  final _otpController = TextEditingController();
  bool _sendingOtp = false;
  bool _verifying = false;
  int _otpSentCount = 0;
  bool _otpSent = false;
  int _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _sendOtp();
  }

  @override
  void dispose() {
    _mpinController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (_otpSentCount >= 3) {
      _showMessage('Too many OTP requests. Please try again later.');
      return;
    }

    setState(() {
      _sendingOtp = true;
    });

    final email = widget.member.email ?? '';
    if (email.isEmpty) {
      _showMessage('Email not registered for this account.');
      setState(() {
        _sendingOtp = false;
      });
      return;
    }

    final result = await _emailOtpService.sendVerificationOtp(email);

    if (!mounted) {
      return;
    }

    if (!result.success) {
      _showMessage(result.error ?? 'Failed to send OTP.');
      setState(() {
        _sendingOtp = false;
      });
      return;
    }

    setState(() {
      _sendingOtp = false;
      _otpSent = true;
      _otpSentCount++;
      _remainingSeconds = 30;
    });

    _startCountdown();
    _showMessage('OTP sent to ${_maskEmail(email)}');
  }

  void _startCountdown() {
    Future<void>.delayed(const Duration(seconds: 1), () {
      if (!mounted) {
        return;
      }
      setState(() {
        _remainingSeconds--;
      });
      if (_remainingSeconds > 0) {
        _startCountdown();
      }
    });
  }

  Future<void> _verify() async {
    final mpin = _mpinController.text.trim();
    final otp = _otpController.text.trim();

    if (mpin.isEmpty || otp.isEmpty) {
      _showMessage('Enter both M-PIN and OTP.');
      return;
    }

    if (mpin != widget.member.mpin) {
      _showMessage('Incorrect M-PIN.');
      return;
    }

    if (mpin.length != 6) {
      _showMessage('M-PIN must be 6 digits.');
      return;
    }

    setState(() {
      _verifying = true;
    });

    final email = widget.member.email ?? '';
    final isOtpValid = await _emailOtpService.verifyOtp(
      email: email,
      otp: otp,
    );

    if (!mounted) {
      return;
    }

    if (!isOtpValid) {
      _showMessage('Invalid or expired OTP.');
      setState(() {
        _verifying = false;
      });
      return;
    }

    // Device verified, proceed
    widget.onVerified();
    setState(() {
      _verifying = false;
    });
  }

  String _maskEmail(String email) {
    if (email.isEmpty) {
      return '';
    }
    final parts = email.split('@');
    if (parts.length != 2) {
      return email;
    }
    final name = parts[0];
    final domain = parts[1];
    final masked = name.replaceRange(1, name.length - 1, '*' * (name.length - 2));
    return '$masked@$domain';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 3),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify New Device'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.security_outlined, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'New device detected. Verify your identity to continue.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Step 1: Enter your M-PIN',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _mpinController,
              decoration: const InputDecoration(
                labelText: 'M-PIN',
                hintText: 'Enter your 6-digit M-PIN',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
            ),
            const SizedBox(height: 24),
            Text(
              'Step 2: Verify with OTP',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'An OTP has been sent to your registered email. Enter it below.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _otpController,
              decoration: const InputDecoration(
                labelText: 'OTP',
                hintText: 'Enter 6-digit OTP',
                prefixIcon: Icon(Icons.mail_outline),
              ),
              keyboardType: TextInputType.number,
              maxLength: 6,
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: (_sendingOtp || _otpSentCount >= 3)
                    ? null
                    : _remainingSeconds > 0
                        ? null
                        : _sendOtp,
                child: Text(
                  _remainingSeconds > 0
                      ? 'Resend OTP in $_remainingSeconds s'
                      : 'Resend OTP',
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _verifying ? null : _verify,
                icon: const Icon(Icons.verified_user_outlined),
                label: Text(_verifying ? 'Verifying...' : 'Verify Device'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
