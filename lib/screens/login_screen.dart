import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:google_fonts/google_fonts.dart';

import '../core/app_strings.dart';
import '../core/brand.dart';
import '../models/member.dart';
import '../services/app_language_service.dart';
import '../services/auth_service.dart';
import 'device_verification_screen.dart';
import '../services/member_repository.dart';
import 'registration_screen.dart';

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
  bool _submitting = false;
  bool _biometricAvailable = false;
  bool _checkingBiometric = true;
  bool _obscureMpin = true;
  static final RegExp _mobilePattern = RegExp(r'^[0-9]{10}$');
  static final RegExp _mpinPattern = RegExp(r'^[0-9]{6}$');

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
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    return ValueListenableBuilder<Locale>(
      valueListenable: _languageService.localeListenable,
      builder: (context, locale, _) {
        final languageCode = locale.languageCode;

        return Scaffold(
          body: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: <Color>[Color(0xFF0C2C3A), Color(0xFF20606E), Color(0xFFE0AE5A)],
              ),
            ),
            child: Stack(
              children: <Widget>[
                Positioned(
                  top: -120,
                  left: -90,
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0x30FFFFFF),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -160,
                  right: -100,
                  child: Container(
                    width: 320,
                    height: 320,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0x33FFFFFF),
                    ),
                  ),
                ),
                SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 500),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOut,
                          padding: EdgeInsets.fromLTRB(24, keyboardOpen ? 18 : 24, 24, 24),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            color: const Color(0xFFFDFBF7),
                            border: Border.all(color: const Color(0xFFDCCFAF)),
                            boxShadow: const <BoxShadow>[
                              BoxShadow(
                                color: Color(0x35092A34),
                                blurRadius: 24,
                                offset: Offset(0, 12),
                              ),
                            ],
                          ),
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
                              Row(
                                children: <Widget>[
                                  Container(
                                    width: 58,
                                    height: 58,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      gradient: const LinearGradient(
                                        colors: <Color>[Color(0xFF0C2D3A), Color(0xFF225F6E)],
                                      ),
                                    ),
                                    child: const BrandLogo(size: 38, withBackdrop: false),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      AppBrand.appName,
                                      style: GoogleFonts.merriweather(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF142C38),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                AppStrings.tr(languageCode, 'login_tagline'),
                                style: const TextStyle(color: Color(0xFF5A6470)),
                              ),
                              const SizedBox(height: 20),
                              TextField(
                                controller: _mobileController,
                                keyboardType: TextInputType.phone,
                                maxLength: 10,
                                inputFormatters: <TextInputFormatter>[
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                onChanged: (_) => _refreshBiometricAvailability(),
                                decoration: InputDecoration(
                                  labelText: AppStrings.tr(languageCode, 'mobile_number'),
                                  prefixIcon: const Icon(Icons.phone_iphone_outlined),
                                ),
                              ),
                              TextField(
                                controller: _mpinController,
                                obscureText: _obscureMpin,
                                keyboardType: TextInputType.number,
                                maxLength: 6,
                                inputFormatters: <TextInputFormatter>[
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: InputDecoration(
                                  labelText: AppStrings.tr(languageCode, 'mpin_label'),
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _obscureMpin = !_obscureMpin;
                                      });
                                    },
                                    icon: Icon(
                                      _obscureMpin
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed: _submitting ? null : _submit,
                                  icon: const Icon(Icons.login_outlined),
                                  label: Text(
                                    _submitting
                                        ? AppStrings.tr(languageCode, 'signing_in')
                                        : AppStrings.tr(languageCode, 'sign_in'),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed:
                                      _checkingBiometric ? null : _loginWithBiometric,
                                  icon: const Icon(Icons.fingerprint),
                                  label: Text(
                                    _checkingBiometric
                                        ? AppStrings.tr(languageCode, 'checking_biometrics')
                                        : AppStrings.tr(languageCode, 'use_biometric_login'),
                                  ),
                                ),
                              ),
                              const Divider(height: 30),
                              Center(
                                child: TextButton.icon(
                                  onPressed: _openRegistration,
                                  icon: const Icon(Icons.person_add_alt_1_outlined),
                                  label: Text(
                                    AppStrings.tr(
                                      languageCode,
                                      'new_member_registration',
                                    ),
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
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _submit() async {
    final languageCode = _languageService.currentLanguageCode;
    final mobile = _mobileController.text.trim();
    final mpin = _mpinController.text.trim();
    if (!_mobilePattern.hasMatch(mobile)) {
      _showMessage(AppStrings.tr(languageCode, 'enter_valid_mobile'));
      return;
    }
    if (!_mpinPattern.hasMatch(mpin)) {
      _showMessage(AppStrings.tr(languageCode, 'mpin_exact_6'));
      return;
    }
    setState(() {
      _submitting = true;
    });

    final result = await widget.authService.loginWithMpin(
      mobileNumber: mobile,
      mpin: mpin,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _submitting = false;
    });
    if (result.requiresDeviceVerification && result.member != null) {
      if (!mounted) {
        return;
      }
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (context) => DeviceVerificationScreen(
            member: result.member!,
            onVerified: () async {
              final completion =
                  await widget.authService.completeDeviceVerification(
                result.member!,
              );
              if (!mounted) {
                return;
              }
              if (completion.isSuccess && completion.member != null) {
                widget.onLoggedIn(completion.member!);
              } else {
                _showMessage(
                  completion.error ??
                      AppStrings.tr(languageCode, 'login_failed'),
                );
              }
            },
          ),
        ),
      );
      return;
    }
    if (result.isSuccess) {
      widget.onLoggedIn(result.member!);
      return;
    }
    _showMessage(result.error ?? AppStrings.tr(languageCode, 'login_failed'));
  }

  Future<void> _loginWithBiometric() async {
    final languageCode = _languageService.currentLanguageCode;
    final result = await widget.authService.loginWithBiometric(
      mobileNumber: _mobileController.text.trim(),
    );
    if (!mounted) {
      return;
    }
    if (result.requiresDeviceVerification && result.member != null) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (context) => DeviceVerificationScreen(
            member: result.member!,
            onVerified: () async {
              final completion =
                  await widget.authService.completeDeviceVerification(
                result.member!,
              );
              if (!mounted) {
                return;
              }
              if (completion.isSuccess && completion.member != null) {
                widget.onLoggedIn(completion.member!);
              } else {
                _showMessage(
                  completion.error ??
                      AppStrings.tr(languageCode, 'biometric_login_failed'),
                );
              }
            },
          ),
        ),
      );
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
    final available = await widget.authService.isBiometricAvailable(
      mobileNumber: _mobileController.text.trim(),
    );
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
