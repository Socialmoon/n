import 'dart:async';

import 'package:flutter/material.dart';

import '../models/emergency_alert.dart';
import '../models/member.dart';
import '../services/donation_service.dart';
import '../services/emergency_service.dart';
import '../services/help_feed_service.dart';
import '../services/location_suggestion_service.dart';
import '../services/member_repository.dart';
import 'donation_screen.dart';
import 'help_feed_screen.dart';
import 'members_screen.dart';
import 'admin_approvals_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import '../widgets/member_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    required this.currentUser,
    required this.repository,
    required this.donationService,
    required this.emergencyService,
    required this.helpFeedService,
    required this.onCurrentUserUpdated,
    required this.onLogout,
    super.key,
  });

  final Member currentUser;
  final MemberRepository repository;
  final DonationService donationService;
  final EmergencyService emergencyService;
  final HelpFeedService helpFeedService;
  final ValueChanged<Member> onCurrentUserUpdated;
  final VoidCallback onLogout;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _queryController = TextEditingController();
  final _districtController = TextEditingController();
  final LocationSuggestionService _locationSuggestions =
      LocationSuggestionService();
  List<String> _districtSuggestions = <String>[];
  List<String> _stationSuggestions = <String>[];
  Timer? _districtDebounce;
  Timer? _stationDebounce;
  int _districtRequest = 0;
  int _stationRequest = 0;

  @override
  void dispose() {
    _districtDebounce?.cancel();
    _stationDebounce?.cancel();
    _queryController.dispose();
    _districtController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.currentUser.isApproved) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Approval Pending'),
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
                    const Text(
                      'Your account is pending admin approval.',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'You can access the full app immediately after admin approval.',
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _refreshApprovalStatus,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Check Approval Status'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final members = widget.repository.search(
      query: _queryController.text,
      districtFilter: _districtController.text,
    );
    final visibleMembers =
        members.where((member) => member.id != widget.currentUser.id).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Member Directory'),
        actions: <Widget>[
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
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
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
          TextField(
            controller: _queryController,
            decoration: const InputDecoration(
              labelText: 'Search by name, role, or posting location',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: _onSearchChanged,
            onTap: () => _loadStationSuggestions(_queryController.text),
          ),
          _buildSuggestionChips(
            suggestions: _stationSuggestions,
            onSelected: (station) {
              setState(() {
                _queryController.text = station;
                _stationSuggestions = <String>[];
              });
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _districtController,
            decoration: const InputDecoration(
              labelText: 'Filter by posting district',
              prefixIcon: Icon(Icons.place_outlined),
            ),
            onChanged: _onDistrictChanged,
            onTap: () => _loadDistrictSuggestions(_districtController.text),
          ),
          _buildSuggestionChips(
            suggestions: _districtSuggestions,
            onSelected: (district) {
              setState(() {
                _districtController.text = district;
                _districtSuggestions = <String>[];
              });
              _onSearchChanged(_queryController.text);
            },
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: widget.currentUser.isAdmin ? _openApprovals : null,
            icon: const Icon(Icons.verified_user_outlined),
            label: const Text('Open New Approvals'),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _openProfile,
            icon: const Icon(Icons.person_outline),
            label: const Text('Open My Profile'),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _openSettings,
            icon: const Icon(Icons.settings_outlined),
            label: const Text('Open Settings'),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _openDonations,
            icon: const Icon(Icons.volunteer_activism_outlined),
            label: const Text('Open Donations Page'),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _openMembers,
            icon: const Icon(Icons.groups_outlined),
            label: const Text('Open Members Page'),
          ),
          const SizedBox(height: 16),
          const Text(
            'Visible member data excludes home district. Admin accounts can see it in the cards below.',
          ),
          const SizedBox(height: 12),
          if (visibleMembers.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('No members match the current filters.'),
              ),
            ),
          ...visibleMembers.map(
            (member) => MemberCard(
              member: member,
              showAdminFields: widget.currentUser.isAdmin,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Recent emergency alerts',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          ...widget.emergencyService.alerts.take(5).map(_buildAlertCard),
          if (widget.emergencyService.alerts.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('No emergency alerts have been triggered yet.'),
              ),
            ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _openHelpFeed,
            icon: const Icon(Icons.forum_outlined),
            label: const Text('Open Help Feed'),
          ),
          const SizedBox(height: 8),
          const Text(
            'Open the dedicated Help Feed page to post requests, comment, and coordinate support.',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _triggerAlert,
        icon: const Icon(Icons.sos_outlined),
        label: const Text('Emergency'),
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
          '${alert.memberName} • ${alert.location} • ${alert.timestamp.day}/${alert.timestamp.month}/${alert.timestamp.year} ${alert.timestamp.hour.toString().padLeft(2, '0')}:${alert.timestamp.minute.toString().padLeft(2, '0')}',
        ),
      ),
    );
  }

  Widget _buildSuggestionChips({
    required List<String> suggestions,
    required ValueChanged<String> onSelected,
  }) {
    if (suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: suggestions
              .map(
                (item) => ActionChip(
                  label: Text(item),
                  onPressed: () => onSelected(item),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Future<void> _triggerAlert() async {
    final controller =
        TextEditingController(text: 'Immediate assistance required');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Trigger emergency alert'),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Alert message'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Send alert'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) {
      controller.dispose();
      return;
    }
    await widget.emergencyService.triggerAlert(
      member: widget.currentUser,
      message: controller.text.trim().isEmpty
          ? 'Immediate assistance required'
          : controller.text.trim(),
    );
    controller.dispose();
    if (!mounted) {
      return;
    }
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Emergency alert triggered.')),
    );
  }

  Future<void> _openHelpFeed() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => HelpFeedScreen(
          currentUser: widget.currentUser,
          helpFeedService: widget.helpFeedService,
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

  Future<void> _openSettings() async {
    final updated = await Navigator.of(context).push<Member>(
      MaterialPageRoute<Member>(
        builder: (context) => SettingsScreen(
          currentUser: widget.currentUser,
          repository: widget.repository,
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

  Future<void> _refreshApprovalStatus() async {
    await widget.repository.refreshFromCloud();
    final updated = widget.repository.findById(widget.currentUser.id);

    if (!mounted) {
      return;
    }

    if (updated == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to refresh approval status.')),
      );
      return;
    }

    widget.onCurrentUserUpdated(updated);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          updated.isApproved
              ? 'Approved. You now have full access.'
              : 'Still pending admin approval.',
        ),
      ),
    );
  }

  void _onSearchChanged(String value) {
    _stationDebounce?.cancel();
    _stationDebounce = Timer(const Duration(milliseconds: 350), () {
      _loadStationSuggestions(value);
    });
  }

  void _onDistrictChanged(String value) {
    _districtDebounce?.cancel();
    _districtDebounce = Timer(const Duration(milliseconds: 350), () {
      _loadDistrictSuggestions(value);
    });
    _onSearchChanged(_queryController.text);
  }

  Future<void> _loadStationSuggestions(String query) async {
    final request = ++_stationRequest;
    final suggestions = await _locationSuggestions.suggestPoliceStations(
      query: query,
      district: _districtController.text,
    );
    if (!mounted || request != _stationRequest) {
      return;
    }
    setState(() {
      _stationSuggestions = suggestions;
    });
  }

  Future<void> _loadDistrictSuggestions(String query) async {
    final request = ++_districtRequest;
    final suggestions = await _locationSuggestions.suggestDistricts(query);
    if (!mounted || request != _districtRequest) {
      return;
    }
    setState(() {
      _districtSuggestions = suggestions;
    });
  }
}
