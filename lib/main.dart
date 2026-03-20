import 'dart:async';

import 'package:flutter/material.dart';

import 'models/member.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';
import 'services/auth_service.dart';
import 'services/donation_service.dart';
import 'services/emergency_service.dart';
import 'services/help_feed_service.dart';
import 'services/member_repository.dart';
import 'services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PoliceNetworkApp());
}

class PoliceNetworkApp extends StatefulWidget {
  const PoliceNetworkApp({super.key});

  @override
  State<PoliceNetworkApp> createState() => _PoliceNetworkAppState();
}

class _PoliceNetworkAppState extends State<PoliceNetworkApp> {
  static const Duration _startupTimeout = Duration(seconds: 8);
  static const Duration _autoLogoutAfter = Duration(minutes: 15);

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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Police Network',
      scaffoldMessengerKey: _messengerKey,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF123C56),
          primary: const Color(0xFF123C56),
          secondary: const Color(0xFFE4B363),
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF3F5F7),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
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
              : DashboardScreen(
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