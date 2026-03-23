import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/app_strings.dart';
import 'core/brand.dart';
import 'models/member.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell_screen.dart';
import 'screens/splash_screen.dart';
import 'services/auth_service.dart';
import 'services/app_language_service.dart';
import 'services/donation_service.dart';
import 'services/emergency_service.dart';
import 'services/help_feed_service.dart';
import 'services/member_repository.dart';
import 'services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ApneSaathiApp());
}

class ApneSaathiApp extends StatefulWidget {
  const ApneSaathiApp({super.key});

  @override
  State<ApneSaathiApp> createState() => _ApneSaathiAppState();
}

class _ApneSaathiAppState extends State<ApneSaathiApp> {
  static const Duration _startupTimeout = Duration(seconds: 8);
  static const Duration _autoLogoutAfter = Duration(minutes: 30);

  final SupabaseService _supabaseService = SupabaseService();
  late final MemberRepository _repository =
      MemberRepository(cloudService: _supabaseService);
  late final AuthService _authService = AuthService(_repository);
  late final DonationService _donationService =
      DonationService(cloudService: _supabaseService);
  late final EmergencyService _emergencyService =
      EmergencyService(cloudService: _supabaseService);
  late final HelpFeedService _helpFeedService =
      HelpFeedService(cloudService: _supabaseService);
  final AppLanguageService _languageService = AppLanguageService();

  bool _loading = true;
  Member? _currentUser;
  Timer? _inactivityTimer;
  final GlobalKey<ScaffoldMessengerState> _messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _stopInactivityTimer();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    Member? sessionUser;
    try {
      await _supabaseService.initialize().timeout(_startupTimeout);
      await _repository.load().timeout(_startupTimeout);
      await _repository.seedAdminIfNeeded().timeout(_startupTimeout);
      await _authService.initialize().timeout(_startupTimeout);
      await _languageService.loadSavedLanguage().timeout(_startupTimeout);
      await _donationService.load().timeout(_startupTimeout);
      await _emergencyService.load().timeout(_startupTimeout);
      await _helpFeedService.load().timeout(_startupTimeout);
      sessionUser = await _authService
          .loadSession()
          .timeout(_startupTimeout, onTimeout: () => null);
    } catch (error) {
      debugPrint('Bootstrap failed, continuing with safe defaults: $error');
      try {
        await _repository.load().timeout(_startupTimeout);
        await _repository.seedAdminIfNeeded().timeout(_startupTimeout);
        await _authService.initialize().timeout(_startupTimeout);
        await _languageService.loadSavedLanguage().timeout(_startupTimeout);
        await _donationService.load().timeout(_startupTimeout);
        await _helpFeedService.load().timeout(_startupTimeout);
        sessionUser = await _authService
            .loadSession()
            .timeout(_startupTimeout, onTimeout: () => null);
      } catch (fallbackError) {
        debugPrint('Fallback bootstrap also failed: $fallbackError');
      }
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _currentUser = sessionUser;
      _loading = false;
    });
    _startInactivityTimer();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0F3A4A),
      brightness: Brightness.light,
    ).copyWith(
      primary: const Color(0xFF0F3A4A),
      secondary: const Color(0xFFC18B3A),
      tertiary: const Color(0xFF2E7D83),
      surface: const Color(0xFFF8FAFB),
    );

    return ValueListenableBuilder<Locale>(
      valueListenable: _languageService.localeListenable,
      builder: (context, locale, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: AppBrand.appName,
          scaffoldMessengerKey: _messengerKey,
          locale: locale,
          supportedLocales: AppStrings.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          theme: ThemeData(
            colorScheme: colorScheme,
            useMaterial3: true,
            textTheme: GoogleFonts.manropeTextTheme(),
            scaffoldBackgroundColor: const Color(0xFFF1F5F8),
            cardTheme: CardThemeData(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Color(0xFFE2E9EE)),
              ),
            ),
            appBarTheme: AppBarTheme(
              centerTitle: false,
              elevation: 0,
              scrolledUnderElevation: 0,
              backgroundColor: const Color(0xFFF1F5F8),
              foregroundColor: const Color(0xFF0D2D39),
              titleTextStyle: GoogleFonts.manrope(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0D2D39),
              ),
            ),
            filledButtonTheme: FilledButtonThemeData(
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            outlinedButtonTheme: OutlinedButtonThemeData(
              style: OutlinedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            navigationBarTheme: NavigationBarThemeData(
              height: 78,
              backgroundColor: Colors.white,
              indicatorColor: const Color(0x220F3A4A),
              elevation: 14,
              shadowColor: const Color(0x220D2D39),
              surfaceTintColor: Colors.white,
              labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>(
                (states) {
                  final selected = states.contains(WidgetState.selected);
                  return GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected
                        ? const Color(0xFF0F3A4A)
                        : const Color(0xFF5C727D),
                  );
                },
              ),
            ),
            chipTheme: const ChipThemeData(
              side: BorderSide(color: Color(0xFFD7E2E9)),
              shape: StadiumBorder(),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFD5E0E8)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide:
                    const BorderSide(color: Color(0xFF0F3A4A), width: 1.5),
              ),
            ),
          ),
          home: _loading
              ? const SplashScreen()
              : _currentUser == null
                  ? LoginScreen(
                      authService: _authService,
                      repository: _repository,
                      onLoggedIn: (member) {
                        setState(() {
                          _currentUser = member;
                        });
                        _startInactivityTimer();
                      },
                    )
                  : MainShellScreen(
                      currentUser: _currentUser!,
                      repository: _repository,
                      donationService: _donationService,
                      emergencyService: _emergencyService,
                      helpFeedService: _helpFeedService,
                      onCurrentUserUpdated: (member) {
                        setState(() {
                          _currentUser = member;
                        });
                        _startInactivityTimer();
                      },
                      onLogout: () async {
                        await _authService.logout();
                        if (!mounted) {
                          return;
                        }
                        setState(() {
                          _currentUser = null;
                        });
                        _stopInactivityTimer();
                      },
                    ),
          builder: (context, child) {
            return Listener(
              onPointerDown: (_) => _handleUserActivity(),
              child: child ?? const SizedBox.shrink(),
            );
          },
        );
      },
    );
  }

  void _handleUserActivity() {
    if (_currentUser == null) {
      return;
    }
    _startInactivityTimer();
  }

  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    if (_currentUser == null) {
      return;
    }
    _inactivityTimer = Timer(_autoLogoutAfter, _performAutoLogout);
  }

  void _stopInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
  }

  Future<void> _performAutoLogout() async {
    if (!mounted || _currentUser == null) {
      return;
    }

    await _authService.logout();
    if (!mounted) {
      return;
    }

    setState(() {
      _currentUser = null;
    });
    _stopInactivityTimer();
    _messengerKey.currentState?.showSnackBar(
      const SnackBar(
        content: Text('You were logged out due to inactivity.'),
      ),
    );
  }
}