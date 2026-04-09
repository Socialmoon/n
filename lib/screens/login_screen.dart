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

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _mobileController = TextEditingController();
  final _mpinController = TextEditingController();
  final AppLanguageService _languageService = AppLanguageService();
  bool _submitting = false;
  bool _biometricAvailable = false;
  bool _checkingBiometric = true;
  bool _obscureMpin = true;
  static final RegExp _mobilePattern = RegExp(r'^[0-9]{10}$');
  static final RegExp _mpinPattern = RegExp(r'^[0-9]{6}$');

  late final AnimationController _entryController;
  late final Animation<double> _headerOpacity;
  late final Animation<double> _cardSlide;
  late final Animation<double> _cardOpacity;

  static const Color _ink = Color(0xFF0F2638);
  static const Color _accent = Color(0xFF2563EB);
  static const Color _gold = Color(0xFFD4994A);

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _headerOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );
    _cardSlide = Tween<double>(begin: 40.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.2, 0.7, curve: Curves.easeOutCubic),
      ),
    );
    _cardOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.2, 0.6, curve: Curves.easeOut),
      ),
    );

    _refreshBiometricAvailability();
  }

  @override
  void dispose() {
    _mobileController.dispose();
    _mpinController.dispose();
    _entryController.dispose();
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
          backgroundColor: const Color(0xFFF5F7FA),
          body: Stack(
            children: <Widget>[
              // Top gradient header
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: MediaQuery.of(context).size.height * 0.42,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[
                        Color(0xFF0A1A2E),
                        Color(0xFF0F2638),
                        Color(0xFF1A3A54),
                      ],
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(36),
                      bottomRight: Radius.circular(36),
                    ),
                  ),
                  child: const SizedBox.expand(),
                ),
              ),

              // Decorative circles on header
              Positioned(
                top: -50,
                right: -30,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: <Color>[
                        const Color(0x12FFFFFF),
                        const Color(0x00FFFFFF),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 80,
                left: -40,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: <Color>[
                        const Color(0x10D4994A),
                        const Color(0x00D4994A),
                      ],
                    ),
                  ),
                ),
              ),

              // Main content
              SafeArea(
                child: AnimatedBuilder(
                  animation: _entryController,
                  builder: (context, child) {
                    return SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                          24, keyboardOpen ? 8 : 16, 24, 24),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: Column(
                          children: <Widget>[
                            // Language selector & branding
                            Opacity(
                              opacity: _headerOpacity.value,
                              child: _buildHeader(languageCode, keyboardOpen),
                            ),

                            SizedBox(height: keyboardOpen ? 16 : 36),

                            // Sign-in card
                            Transform.translate(
                              offset: Offset(0, _cardSlide.value),
                              child: Opacity(
                                opacity: _cardOpacity.value,
                                child: _buildSignInCard(
                                    languageCode, keyboardOpen),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(String languageCode, bool keyboardOpen) {
    return Column(
      children: <Widget>[
        // Language toggle
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0x1AFFFFFF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0x25FFFFFF)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: languageCode,
                dropdownColor: const Color(0xFFF8F6F1),
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600),
                iconEnabledColor: Colors.white70,
                isDense: true,
                onChanged: (value) {
                  if (value == null) return;
                  _languageService.setLanguageCode(value);
                },
                items: AppStrings.supportedLocales
                    .map((locale) => DropdownMenuItem<String>(
                          value: locale.languageCode,
                          child: Text(
                            AppStrings.languageLabel(
                                locale.languageCode, languageCode),
                            style: const TextStyle(color: Color(0xFF1C3340)),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ),
        ),

        if (!keyboardOpen) ...<Widget>[
          const SizedBox(height: 24),

          // Logo
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              color: Colors.white,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: const Color(0x30000000),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: const BrandLogo(size: 56, withBackdrop: false),
            ),
          ),

          const SizedBox(height: 16),

          // App name
          Text(
            AppBrand.appName,
            style: GoogleFonts.merriweather(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.2,
            ),
          ),

          const SizedBox(height: 6),

          // Tagline
          Text(
            AppStrings.tr(languageCode, 'login_tagline'),
            style: const TextStyle(
              color: Color(0xB3FFFFFF),
              fontSize: 13,
              height: 1.35,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildSignInCard(String languageCode, bool keyboardOpen) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0x0C000000),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: const Color(0x06000000),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Section title
          Row(
            children: <Widget>[
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: _gold,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                AppStrings.tr(languageCode, 'sign_in'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _ink,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          // Mobile field
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
              labelStyle: const TextStyle(color: Color(0xFF6B7A88)),
              prefixIcon: const Icon(Icons.phone_iphone_rounded,
                  color: _accent, size: 20),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _accent, width: 1.5),
              ),
              counterText: '',
            ),
          ),

          const SizedBox(height: 14),

          // MPIN field
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
              labelStyle: const TextStyle(color: Color(0xFF6B7A88)),
              prefixIcon:
                  const Icon(Icons.lock_rounded, color: _accent, size: 20),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _obscureMpin = !_obscureMpin;
                  });
                },
                icon: Icon(
                  _obscureMpin
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                  size: 20,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _accent, width: 1.5),
              ),
              counterText: '',
            ),
          ),

          const SizedBox(height: 22),

          // Sign in button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: _ink,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                        strokeCap: StrokeCap.round,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        const Icon(Icons.login_rounded, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          AppStrings.tr(languageCode, 'sign_in'),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 12),

          // Biometric button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: _ink,
                side: BorderSide(
                  color: _biometricAvailable
                      ? const Color(0xFFE2E8F0)
                      : const Color(0xFFF1F5F9),
                ),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              onPressed: _checkingBiometric
                  ? null
                  : (_biometricAvailable ? _loginWithBiometric : null),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    Icons.fingerprint_rounded,
                    size: 22,
                    color:
                        _biometricAvailable ? _accent : const Color(0xFFCBD5E1),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _checkingBiometric
                        ? AppStrings.tr(languageCode, 'checking_biometrics')
                        : (_biometricAvailable
                            ? AppStrings.tr(languageCode, 'use_biometric_login')
                            : 'Biometric unavailable for this mobile'),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color:
                          _biometricAvailable ? _ink : const Color(0xFFCBD5E1),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),

          // Divider
          Row(
            children: <Widget>[
              const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  AppStrings.tr(languageCode, 'new_member_registration')
                      .split(' ')
                      .first,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
            ],
          ),

          const SizedBox(height: 14),

          // Register button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: _gold,
                side: const BorderSide(color: Color(0xFFE8D5B8)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              onPressed: _openRegistration,
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 20),
              label: Text(
                AppStrings.tr(languageCode, 'new_member_registration'),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
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
