import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/app_strings.dart';
import '../core/brand.dart';
import '../models/member.dart';
import '../services/app_language_service.dart';
import '../services/auth_service.dart';
import '../services/member_repository.dart';
import 'registration_screen.dart';

enum LoginMode { mpin }

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
  final _mpinController = TextEditingController();
  final AppLanguageService _languageService = AppLanguageService();
  LoginMode _mode = LoginMode.mpin;
  bool _submitting = false;
  bool _biometricAvailable = false;
  bool _checkingBiometric = true;

  @override
  void initState() {
    super.initState();
    _refreshBiometricAvailability();
  }

  @override
  void dispose() {
    _mobileController.dispose();
    _mpinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: _languageService.localeListenable,
      builder: (context, locale, _) {
        final languageCode = locale.languageCode;

        return Scaffold(
          body: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Color(0xFF0D2438),
                  Color(0xFF1A4A67),
                  Color(0xFFE4B363)
                ],
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
                            Align(
                              alignment: Alignment.centerRight,
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: languageCode,
                                  icon: const Icon(Icons.keyboard_arrow_down),
                                  onChanged: (value) {
                                    if (value == null) {
                                      return;
                                    }
                                    _languageService.setLanguageCode(value);
                                  },
                                  items: AppStrings.supportedLocales
                                      .map((locale) => DropdownMenuItem<String>(
                                            value: locale.languageCode,
                                            child: Text(
                                              AppStrings.languageLabel(
                                                locale.languageCode,
                                                languageCode,
                                              ),
                                            ),
                                          ))
                                      .toList(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Row(
                              children: <Widget>[
                                BrandLogo(size: 48, withBackdrop: false),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    AppBrand.appName,
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(AppStrings.tr(languageCode, 'login_tagline')),
                            const SizedBox(height: 24),
                            SegmentedButton<LoginMode>(
                              segments: const <ButtonSegment<LoginMode>>[
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
                              decoration: InputDecoration(
                                labelText:
                                    AppStrings.tr(languageCode, 'mobile_number'),
                              ),
                            ),
                            TextField(
                              controller: _mpinController,
                              obscureText: true,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              inputFormatters: <TextInputFormatter>[
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: InputDecoration(
                                labelText:
                                    AppStrings.tr(languageCode, 'mpin_label'),
                              ),
                            ),
                            const SizedBox(height: 20),
                            FilledButton(
                              onPressed: _submitting ? null : _submit,
                              child: Text(
                                _submitting
                                    ? AppStrings.tr(languageCode, 'signing_in')
                                    : AppStrings.tr(languageCode, 'sign_in'),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextButton.icon(
                              onPressed:
                                  (_checkingBiometric || !_biometricAvailable)
                                      ? null
                                      : _loginWithBiometric,
                              icon: const Icon(Icons.fingerprint),
                              label: Text(
                                _checkingBiometric
                                    ? AppStrings.tr(
                                        languageCode,
                                        'checking_biometrics',
                                      )
                                    : AppStrings.tr(
                                        languageCode,
                                        'use_biometric_login',
                                      ),
                              ),
                            ),
                            const Divider(height: 32),
                            TextButton(
                              onPressed: _openRegistration,
                              child: Text(
                                AppStrings.tr(
                                  languageCode,
                                  'new_member_registration',
                                ),
                              ),
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
      },
    );
  }

  Future<void> _submit() async {
    final languageCode = _languageService.currentLanguageCode;
    final mobile = _mobileController.text.trim();
    if (mobile.length != 10) {
      _showMessage(AppStrings.tr(languageCode, 'enter_valid_mobile'));
      return;
    }
    setState(() {
      _submitting = true;
    });

    final result = await widget.authService.loginWithMpin(
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
    _showMessage(result.error ?? AppStrings.tr(languageCode, 'login_failed'));
  }

  Future<void> _loginWithBiometric() async {
    final languageCode = _languageService.currentLanguageCode;
    final result = await widget.authService.loginWithBiometric();
    if (!mounted) {
      return;
    }
    if (result.isSuccess) {
      widget.onLoggedIn(result.member!);
      return;
    }
    _showMessage(
      result.error ?? AppStrings.tr(languageCode, 'biometric_login_failed'),
    );
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
    await _refreshBiometricAvailability();
  }

  Future<void> _refreshBiometricAvailability() async {
    setState(() {
      _checkingBiometric = true;
    });
    final available = await widget.authService.isBiometricAvailable();
    if (!mounted) {
      return;
    }
    setState(() {
      _biometricAvailable = available;
      _checkingBiometric = false;
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
