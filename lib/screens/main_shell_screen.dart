import 'package:flutter/material.dart';

import '../models/member.dart';
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

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, 4);
  }

  @override
  Widget build(BuildContext context) {
    final tabs = <Widget>[
      DashboardScreen(
        currentUser: widget.currentUser,
        repository: widget.repository,
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
      ),
      DonationScreen(
        currentUser: widget.currentUser,
        donationService: widget.donationService,
      ),
      ProfileScreen(
        currentUser: widget.currentUser,
        repository: widget.repository,
        donationService: widget.donationService,
        onOpenSettings: _openSettings,
        onProfileUpdated: widget.onCurrentUserUpdated,
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: tabs,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _switchTab,
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups_rounded),
            label: 'Members',
          ),
          NavigationDestination(
            icon: Icon(Icons.forum_outlined),
            selectedIcon: Icon(Icons.forum_rounded),
            label: 'Feed',
          ),
          NavigationDestination(
            icon: Icon(Icons.volunteer_activism_outlined),
            selectedIcon: Icon(Icons.volunteer_activism_rounded),
            label: 'Donations',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Account',
          ),
        ],
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
