import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/member.dart';
import '../services/auth_service.dart';
import '../services/donation_service.dart';
import '../services/emergency_service.dart';
import '../services/help_feed_service.dart';
import '../services/member_repository.dart';
import 'dashboard_screen.dart';
import 'donation_screen.dart';
import 'help_feed_screen.dart';
import 'members_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

class MainShellScreen extends StatefulWidget {
  const MainShellScreen({
    required this.currentUser,
    required this.repository,
    required this.authService,
    required this.donationService,
    required this.emergencyService,
    required this.helpFeedService,
    required this.onCurrentUserUpdated,
    required this.onLogout,
    this.initialIndex = 2,
    super.key,
  });

  final Member currentUser;
  final MemberRepository repository;
  final AuthService authService;
  final DonationService donationService;
  final EmergencyService emergencyService;
  final HelpFeedService helpFeedService;
  final ValueChanged<Member> onCurrentUserUpdated;
  final VoidCallback onLogout;
  final int initialIndex;

  @override
  State<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends State<MainShellScreen> {
  late int _index;
  DateTime? _lastBackPressAt;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, 4);
  }

  @override
  Widget build(BuildContext context) {
    final isHindi = Localizations.localeOf(context).languageCode == 'hi';
    final tabs = <Widget>[
      DashboardScreen(
        currentUser: widget.currentUser,
        repository: widget.repository,
        authService: widget.authService,
        donationService: widget.donationService,
        emergencyService: widget.emergencyService,
        helpFeedService: widget.helpFeedService,
        onCurrentUserUpdated: widget.onCurrentUserUpdated,
        onLogout: widget.onLogout,
        onNavigateToTab: _switchTab,
      ),
      MembersScreen(
        currentUser: widget.currentUser,
        repository: widget.repository,
      ),
      HelpFeedScreen(
        currentUser: widget.currentUser,
        helpFeedService: widget.helpFeedService,
        repository: widget.repository,
      ),
      DonationScreen(
        currentUser: widget.currentUser,
        donationService: widget.donationService,
      ),
      ProfileScreen(
        currentUser: widget.currentUser,
        repository: widget.repository,
        authService: widget.authService,
        donationService: widget.donationService,
        onOpenSettings: _openSettings,
        onProfileUpdated: widget.onCurrentUserUpdated,
      ),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          return;
        }
        if (_index != 0) {
          _switchTab(0);
          return;
        }
        final now = DateTime.now();
        final shouldExit = _lastBackPressAt != null &&
            now.difference(_lastBackPressAt!) <= const Duration(seconds: 2);
        if (shouldExit) {
          SystemNavigator.pop();
          return;
        }
        _lastBackPressAt = now;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Press back again to exit app.')),
        );
      },
      child: Scaffold(
        body: IndexedStack(
          index: _index,
          children: tabs,
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _switchTab,
          destinations: <NavigationDestination>[
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: isHindi ? 'होम' : 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.groups_outlined),
              selectedIcon: Icon(Icons.groups_rounded),
              label: isHindi ? 'सदस्य' : 'Members',
            ),
            NavigationDestination(
              icon: Icon(Icons.forum_outlined),
              selectedIcon: Icon(Icons.forum_rounded),
              label: isHindi ? 'फीड' : 'Feed',
            ),
            NavigationDestination(
              icon: Icon(Icons.volunteer_activism_outlined),
              selectedIcon: Icon(Icons.volunteer_activism_rounded),
              label: isHindi ? 'डोनेशन' : 'Donations',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person_rounded),
              label: isHindi ? 'अकाउंट' : 'Account',
            ),
          ],
        ),
      ),
    );
  }

  void _switchTab(int index) {
    if (index == _index) {
      return;
    }
    setState(() {
      _index = index;
    });
  }

  Future<void> _openSettings() async {
    final updated = await Navigator.of(context).push<Member>(
      MaterialPageRoute<Member>(
        builder: (context) => SettingsScreen(
          currentUser: widget.currentUser,
          repository: widget.repository,
          authService: widget.authService,
          onLogout: widget.onLogout,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    if (updated != null) {
      widget.onCurrentUserUpdated(updated);
    }
  }
}
