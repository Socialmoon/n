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
  final Future<void> Function() onVerified;

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
  int _remainingSeconds = 0;
  int _failedVerifyAttempts = 0;
  DateTime? _verifyLockedUntil;

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
    final isHindi = Localizations.localeOf(context).languageCode == 'hi';
    if (_otpSentCount >= 3) {
      _showMessage(isHindi
          ? 'बहुत अधिक OTP अनुरोध हो चुके हैं। कृपया बाद में प्रयास करें।'
          : 'Too many OTP requests. Please try again later.');
      return;
    }

    setState(() {
      _sendingOtp = true;
    });

    final email = widget.member.email ?? '';
    if (email.isEmpty) {
      _showMessage(isHindi
          ? 'इस खाते में ईमेल दर्ज नहीं है।'
          : 'Email not registered for this account.');
      setState(() {
        _sendingOtp = false;
      });
      return;
    }

    final result = await _emailOtpService.sendVerificationOtp(
      email,
      purpose: EmailOtpPurpose.deviceBinding,
      memberName: widget.member.name,
    );

    if (!mounted) {
      return;
    }

    if (!result.success) {
      _showMessage(result.error ?? (isHindi ? 'OTP भेजने में विफल।' : 'Failed to send OTP.'));
      setState(() {
        _sendingOtp = false;
      });
      return;
    }

    setState(() {
      _sendingOtp = false;
      _otpSentCount++;
      _remainingSeconds = 30;
    });

    _startCountdown();
    _showMessage(isHindi
      ? 'OTP भेज दिया गया: ${_maskEmail(email)}'
      : 'OTP sent to ${_maskEmail(email)}');
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
    final isHindi = Localizations.localeOf(context).languageCode == 'hi';
    if (_verifyLockedUntil != null && DateTime.now().isBefore(_verifyLockedUntil!)) {
      final waitMinutes = _verifyLockedUntil!.difference(DateTime.now()).inMinutes + 1;
      _showMessage(isHindi
          ? 'बहुत अधिक गलत प्रयास। $waitMinutes मिनट बाद पुनः प्रयास करें।'
          : 'Too many invalid attempts. Try again in $waitMinutes minute(s).');
      return;
    }
    final mpin = _mpinController.text.trim();
    final otp = _otpController.text.trim();

    if (mpin.isEmpty || otp.isEmpty) {
      _showMessage(isHindi
          ? 'M-PIN और OTP दोनों दर्ज करें।'
          : 'Enter both M-PIN and OTP.');
      return;
    }

    if (mpin != widget.member.mpin) {
      _showMessage(isHindi ? 'गलत M-PIN।' : 'Incorrect M-PIN.');
      return;
    }

    if (mpin.length != 6) {
      _showMessage(isHindi
          ? 'M-PIN 6 अंकों का होना चाहिए।'
          : 'M-PIN must be 6 digits.');
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
      _failedVerifyAttempts += 1;
      if (_failedVerifyAttempts >= 5) {
        _verifyLockedUntil = DateTime.now().add(const Duration(minutes: 10));
        _failedVerifyAttempts = 0;
      }
      _showMessage(isHindi
          ? 'OTP अमान्य है या समय समाप्त हो गया है।'
          : 'Invalid or expired OTP.');
      setState(() {
        _verifying = false;
      });
      return;
    }

    _failedVerifyAttempts = 0;
    _verifyLockedUntil = null;

    // Device verified, proceed
    await widget.onVerified();
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop(true);
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
    if (name.length < 3) {
      return '$name@$domain';
    }
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
    final isHindi = Localizations.localeOf(context).languageCode == 'hi';
    return Scaffold(
      appBar: AppBar(
        title: Text(isHindi ? 'नया डिवाइस सत्यापित करें' : 'Verify New Device'),
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
                        isHindi
                            ? 'नया डिवाइस मिला है। जारी रखने के लिए अपनी पहचान सत्यापित करें।'
                            : 'New device detected. Verify your identity to continue.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isHindi ? 'चरण 1: अपना M-PIN दर्ज करें' : 'Step 1: Enter your M-PIN',
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
              isHindi ? 'चरण 2: OTP से सत्यापित करें' : 'Step 2: Verify with OTP',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              isHindi
                  ? 'आपके रजिस्टर्ड ईमेल पर OTP भेजा गया है। नीचे दर्ज करें। OTP 5 मिनट तक मान्य है।'
                  : 'An OTP has been sent to your registered email. Enter it below. OTP is valid for 5 minutes.',
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
                      ? (isHindi
                          ? '$_remainingSeconds सेकंड में OTP दोबारा भेजें'
                          : 'Resend OTP in $_remainingSeconds s')
                      : (isHindi ? 'OTP फिर से भेजें' : 'Resend OTP'),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _verifying ? null : _verify,
                icon: const Icon(Icons.verified_user_outlined),
                label: Text(_verifying
                    ? (isHindi ? 'सत्यापित हो रहा है...' : 'Verifying...')
                    : (isHindi ? 'डिवाइस सत्यापित करें' : 'Verify Device')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
