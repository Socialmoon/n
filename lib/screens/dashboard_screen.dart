import 'package:flutter/material.dart';

import '../core/time_utils.dart';
import '../models/emergency_alert.dart';
import '../models/member.dart';
import '../services/auth_service.dart';
import '../services/donation_service.dart';
import '../services/emergency_service.dart';
import '../services/help_feed_service.dart';
import '../services/member_repository.dart';
import '../services/app_settings_service.dart';
import '../core/brand.dart';
import 'donation_screen.dart';
import 'emergency_alert_screen.dart';
import 'help_feed_screen.dart';
import 'members_screen.dart';
import 'admin_approvals_screen.dart';
import 'admin_all_members_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'user_guide_screen.dart';

const int _membersTabIndex = 1;
const int _helpTabIndex = 2;
const int _donationsTabIndex = 3;
const int _accountTabIndex = 4;

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    required this.currentUser,
    required this.repository,
    required this.authService,
    required this.donationService,
    required this.emergencyService,
    required this.helpFeedService,
    required this.onCurrentUserUpdated,
    required this.onLogout,
    this.onNavigateToTab,
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
  final ValueChanged<int>? onNavigateToTab;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AppSettingsService _settingsService = AppSettingsService();

  @override
  void initState() {
    super.initState();
    widget.emergencyService.addListener(_handleEmergencyUpdates);
  }

  @override
  void didUpdateWidget(covariant DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.emergencyService, widget.emergencyService)) {
      oldWidget.emergencyService.removeListener(_handleEmergencyUpdates);
      widget.emergencyService.addListener(_handleEmergencyUpdates);
    }
  }

  @override
  void dispose() {
    widget.emergencyService.removeListener(_handleEmergencyUpdates);
    super.dispose();
  }

  void _handleEmergencyUpdates() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isHindi = Localizations.localeOf(context).languageCode == 'hi';
    if (!widget.currentUser.isApproved) {
      final isHindi = Localizations.localeOf(context).languageCode == 'hi';
      return Scaffold(
        appBar: AppBar(
          title: Text(isHindi ? 'स्वीकृति लंबित' : 'Approval Pending'),
          actions: <Widget>[
            IconButton(
              onPressed: widget.onLogout,
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
            ),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Card(
              margin: const EdgeInsets.all(20),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      isHindi
                          ? 'आपका खाता एडमिन स्वीकृति के लिए लंबित है।'
                          : 'Your account is pending admin approval.',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      isHindi
                          ? 'एडमिन स्वीकृति के बाद आपको तुरंत पूरे ऐप का एक्सेस मिल जाएगा।'
                          : 'You can access the full app immediately after admin approval.',
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _refreshApprovalStatus,
                      icon: const Icon(Icons.refresh),
                      label: Text(isHindi
                          ? 'स्वीकृति स्थिति जांचें'
                          : 'Check Approval Status'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: BrandedScreenTitle(isHindi ? 'डैशबोर्ड' : 'Dashboard'),
        actions: <Widget>[
          IconButton(
            onPressed: _openMembersSearch,
            icon: const Icon(Icons.search),
            tooltip: 'Search members',
          ),
          IconButton(
            onPressed: _triggerAlert,
            icon: const Icon(Icons.warning_amber_outlined),
            tooltip: 'Emergency alert',
          ),
          IconButton(
            onPressed: widget.onLogout,
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: <Color>[Color(0xFF123C56), Color(0xFF266D7A)],
              ),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x2A0F3A4A),
                  blurRadius: 18,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _buildHeaderAvatar(widget.currentUser),
                const SizedBox(height: 12),
                Text(
                  'Welcome, ${widget.currentUser.name}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${widget.currentUser.role} • ${widget.currentUser.postingLocation}',
                  style: const TextStyle(color: Colors.white70),
                ),
                if (widget.currentUser.referenceMemberName != null) ...<Widget>[
                  const SizedBox(height: 8),
                  Text(
                    'Referred by ${widget.currentUser.referenceMemberName}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Quick links',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          _buildQuickActions(),
          const SizedBox(height: 20),
          const SizedBox(height: 24),
          Text(
            isHindi ? 'हाल के आपातकालीन अलर्ट' : 'Recent emergency alerts',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          ...widget.emergencyService.alerts.take(5).map(_buildAlertCard),
          if (widget.emergencyService.alerts.isEmpty)
            Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(isHindi
                  ? 'अभी तक कोई आपातकालीन अलर्ट ट्रिगर नहीं हुआ है।'
                  : 'No emergency alerts have been triggered yet.'),
              ),
            ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _goToTabOrOpen(_helpTabIndex, _openHelpFeed),
            icon: const Icon(Icons.forum_outlined),
            label: Text(isHindi ? 'हेल्प फीड खोलें' : 'Open Help Feed'),
          ),
          const SizedBox(height: 8),
          const Text(
            'Open the dedicated Help Feed page to post requests, comment, and coordinate support.',
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'dashboard-emergency-fab',
        onPressed: _triggerAlert,
        icon: const Icon(Icons.sos_outlined),
        label: Text(isHindi ? 'आपातकाल' : 'Emergency'),
      ),
    );
  }

  Widget _buildQuickActions() {
    return GridView.count(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: <Widget>[
        _buildQuickActionTile(
          icon: Icons.groups_outlined,
          title: 'Members',
          subtitle: 'Search and connect',
          onTap: () => _goToTabOrOpen(_membersTabIndex, _openMembers),
        ),
        _buildQuickActionTile(
          icon: Icons.forum_outlined,
          title: 'Help Feed',
          subtitle: 'Requests and support',
          onTap: () => _goToTabOrOpen(_helpTabIndex, _openHelpFeed),
        ),
        _buildQuickActionTile(
          icon: Icons.volunteer_activism_outlined,
          title: 'Donations',
          subtitle: 'Fund and history',
          onTap: () => _goToTabOrOpen(_donationsTabIndex, _openDonations),
        ),
        _buildQuickActionTile(
          icon: Icons.person_outline,
          title: 'Account',
          subtitle: 'Profile and settings',
          onTap: () => _goToTabOrOpen(_accountTabIndex, _openAccountHub),
        ),
        if (widget.currentUser.isAdmin) ...<Widget>[
          _buildQuickActionTile(
            icon: Icons.verified_user_outlined,
            title: 'Approvals',
            subtitle: 'Review new members',
            onTap: _openApprovals,
          ),
          _buildQuickActionTile(
            icon: Icons.badge_outlined,
            title: 'All Members',
            subtitle: 'Full admin details',
            onTap: _openAdminAllMembers,
          ),
        ] else
          _buildQuickActionTile(
            icon: Icons.health_and_safety_outlined,
            title: 'Safety',
            subtitle: 'Emergency response',
            onTap: _triggerAlert,
          ),
        _buildQuickActionTile(
          icon: Icons.menu_book_rounded,
          title: 'User Guide',
          subtitle: 'Learn app features',
          onTap: _openUserGuide,
        ),
      ],
    );
  }

  Widget _buildQuickActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE1E8EE)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(icon, color: const Color(0xFF0F3A4A)),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(color: Color(0xFF61747E), fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildAlertCard(EmergencyAlert alert) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.notifications_active_outlined),
        title: Text(alert.message),
        subtitle: Text(
          '${alert.memberName} • ${alert.location} • ${formatIstDateTime(alert.timestamp)}',
        ),
      ),
    );
  }
  Future<void> _triggerAlert() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => EmergencyAlertScreen(
          currentUser: widget.currentUser,
          emergencyService: widget.emergencyService,
        ),
      ),
    );
    if (!mounted) {
      return;
    }
    final notificationsEnabled = await _settingsService.getNotificationsEnabled();
    if (!notificationsEnabled) {
      return;
    }
    setState(() {});
  }

  Future<void> _openHelpFeed() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => HelpFeedScreen(
          currentUser: widget.currentUser,
          helpFeedService: widget.helpFeedService,
          repository: widget.repository,
        ),
      ),
    );
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  Future<void> _openDonations() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => DonationScreen(
          currentUser: widget.currentUser,
          donationService: widget.donationService,
        ),
      ),
    );
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  Future<void> _openProfile() async {
    final updated = await Navigator.of(context).push<Member>(
      MaterialPageRoute<Member>(
        builder: (context) => ProfileScreen(
          currentUser: widget.currentUser,
          repository: widget.repository,
          authService: widget.authService,
          donationService: widget.donationService,
          onOpenSettings: () => _openSettings(),
        ),
      ),
    );
    if (!mounted) {
      return;
    }
    if (updated != null) {
      widget.onCurrentUserUpdated(updated);
    }
    setState(() {});
  }

  Future<void> _openAccountHub() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final isHindi = Localizations.localeOf(context).languageCode == 'hi';
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text(isHindi ? 'मेरा प्रोफाइल' : 'My Profile'),
                subtitle: Text(isHindi
                    ? 'अपनी बेसिक जानकारी अपडेट करें'
                    : 'Edit your basic details'),
                onTap: () => Navigator.of(context).pop('profile'),
              ),
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: Text(isHindi ? 'सेटिंग्स' : 'Settings'),
                subtitle: Text(isHindi
                    ? 'सुरक्षा, नोटिफिकेशन और अकाउंट नियंत्रण'
                    : 'Security, notifications, and account controls'),
                onTap: () => Navigator.of(context).pop('settings'),
              ),
            ],
          ),
        );
      },
    );

    if (action == 'settings') {
      await _openSettings();
      return;
    }
    if (action == 'profile') {
      await _openProfile();
    }
  }

  Widget _buildHeaderAvatar(Member member) {
    final selfieUrl = member.selfiePath?.trim() ?? '';
    final initial = member.name.isEmpty ? '?' : member.name[0].toUpperCase();
    if (selfieUrl.isEmpty) {
      return CircleAvatar(
        radius: 24,
        backgroundColor: const Color(0x33FFFFFF),
        child: Text(
          initial,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      );
    }
    return ClipOval(
      child: Image.network(
        selfieUrl,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => CircleAvatar(
          radius: 24,
          backgroundColor: const Color(0x33FFFFFF),
          child: Text(
            initial,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
        ),
      ),
    );
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
    setState(() {});
  }

  void _openUserGuide() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const UserGuideScreen(),
      ),
    );
  }

  Future<void> _openMembers() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => MembersScreen(
          currentUser: widget.currentUser,
          repository: widget.repository,
        ),
      ),
    );
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  Future<void> _openMembersSearch() async {
    await _openMembers();
  }

  void _goToTabOrOpen(int tabIndex, Future<void> Function() fallback) {
    if (widget.onNavigateToTab != null) {
      widget.onNavigateToTab!(tabIndex);
      return;
    }
    fallback();
  }

  Future<void> _openApprovals() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => AdminApprovalsScreen(
          currentUser: widget.currentUser,
          repository: widget.repository,
        ),
      ),
    );
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  Future<void> _openAdminAllMembers() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => AdminAllMembersScreen(
          currentUser: widget.currentUser,
          repository: widget.repository,
        ),
      ),
    );
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  Future<void> _refreshApprovalStatus() async {
    await widget.repository.refreshFromCloud();
    final updated = widget.repository.findById(widget.currentUser.id);

    if (!mounted) {
      return;
    }

    if (updated == null) {
      final isHindi = Localizations.localeOf(context).languageCode == 'hi';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isHindi
              ? 'स्वीकृति स्थिति अपडेट नहीं हो सकी।'
              : 'Unable to refresh approval status.'),
        ),
      );
      return;
    }

    final isHindi = Localizations.localeOf(context).languageCode == 'hi';
    widget.onCurrentUserUpdated(updated);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          updated.isApproved
              ? (isHindi
                  ? 'स्वीकृत। अब आपके पास पूरा एक्सेस है।'
                  : 'Approved. You now have full access.')
              : (isHindi
                  ? 'अब भी एडमिन स्वीकृति लंबित है।'
                  : 'Still pending admin approval.'),
        ),
      ),
    );
  }

}
