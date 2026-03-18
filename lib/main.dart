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

  @override
  void initState() {
    super.initState();
    _bootstrap();
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
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Police Network',
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
                  },
                )
              : DashboardScreen(
                  currentUser: _currentUser!,
                  repository: _repository,
                  donationService: _donationService,
                  emergencyService: _emergencyService,
                  helpFeedService: _helpFeedService,
                  onLogout: () async {
                    await _authService.logout();
                    if (!mounted) {
                      return;
                    }
                    setState(() {
                      _currentUser = null;
                    });
                  },
                ),
    );
  }
}