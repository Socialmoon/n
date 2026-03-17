import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/member.dart';
import '../services/auth_service.dart';
import '../services/member_repository.dart';
import 'registration_screen.dart';

enum LoginMode { otp, mpin }

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    required this.authService,
    required this.repository,
    required this.onLoggedIn,
    super.key,
  });

  final AuthService authService;
  final MemberRepository repository;
  final ValueChanged<Member> onLoggedIn;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _mobileController = TextEditingController();
  final _otpController = TextEditingController();
  final _mpinController = TextEditingController();
  LoginMode _mode = LoginMode.otp;
  bool _submitting = false;

  @override
  void dispose() {
    _mobileController.dispose();
    _otpController.dispose();
    _mpinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[Color(0xFF0D2438), Color(0xFF1A4A67), Color(0xFFE4B363)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'Police Network',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Secure access to the member directory with local MVP authentication.',
                        ),
                        const SizedBox(height: 24),
                        SegmentedButton<LoginMode>(
                          segments: const <ButtonSegment<LoginMode>>[
                            ButtonSegment<LoginMode>(
                              value: LoginMode.otp,
                              label: Text('OTP'),
                              icon: Icon(Icons.sms_outlined),
                            ),
                            ButtonSegment<LoginMode>(
                              value: LoginMode.mpin,
                              label: Text('M-PIN'),
                              icon: Icon(Icons.lock_outline),
                            ),
                          ],
                          selected: <LoginMode>{_mode},
                          onSelectionChanged: (selection) {
                            setState(() {
                              _mode = selection.first;
                            });
                          },
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _mobileController,
                          keyboardType: TextInputType.phone,
                          maxLength: 10,
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(labelText: 'Mobile number'),
                        ),
                        if (_mode == LoginMode.otp) ...<Widget>[
                          TextField(
                            controller: _otpController,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            inputFormatters: <TextInputFormatter>[
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: const InputDecoration(labelText: 'OTP'),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: _issueOtp,
                            icon: const Icon(Icons.sms_outlined),
                            label: const Text('Generate local OTP'),
                          ),
                        ] else
                          TextField(
                            controller: _mpinController,
                            obscureText: true,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            inputFormatters: <TextInputFormatter>[
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: const InputDecoration(labelText: '6 digit M-PIN'),
                          ),
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: _submitting ? null : _submit,
                          child: Text(_submitting ? 'Signing in...' : 'Sign in'),
                        ),
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: _loginWithBiometric,
                          icon: const Icon(Icons.fingerprint),
                          label: const Text('Use biometric login'),
                        ),
                        const Divider(height: 32),
                        TextButton(
                          onPressed: _openRegistration,
                          child: const Text('New member registration'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _issueOtp() {
    final mobile = _mobileController.text.trim();
    if (mobile.length != 10) {
      _showMessage('Enter a valid 10 digit mobile number first.');
      return;
    }
    final otp = widget.authService.issueOtp(mobile);
    _showMessage('Local OTP: $otp');
  }

  Future<void> _submit() async {
    final mobile = _mobileController.text.trim();
    if (mobile.length != 10) {
      _showMessage('Enter a valid 10 digit mobile number.');
      return;
    }
    setState(() {
      _submitting = true;
    });

    final result = _mode == LoginMode.otp
        ? await widget.authService.loginWithOtp(
            mobileNumber: mobile,
            otp: _otpController.text.trim(),
          )
        : await widget.authService.loginWithMpin(
            mobileNumber: mobile,
            mpin: _mpinController.text.trim(),
          );
    if (!mounted) {
      return;
    }
    setState(() {
      _submitting = false;
    });
    if (result.isSuccess) {
      widget.onLoggedIn(result.member!);
      return;
    }
    _showMessage(result.error ?? 'Login failed.');
  }

  Future<void> _loginWithBiometric() async {
    final result = await widget.authService.loginWithBiometric();
    if (!mounted) {
      return;
    }
    if (result.isSuccess) {
      widget.onLoggedIn(result.member!);
      return;
    }
    _showMessage(result.error ?? 'Biometric login failed.');
  }

  Future<void> _openRegistration() async {
    await Navigator.of(context).push<Member>(
      MaterialPageRoute<Member>(
        builder: (context) => RegistrationScreen(
          repository: widget.repository,
          authService: widget.authService,
        ),
      ),
    );
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}