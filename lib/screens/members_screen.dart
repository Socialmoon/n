import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/brand.dart';
import '../models/member.dart';
import 'member_details_screen.dart';
import '../services/location_suggestion_service.dart';
import '../services/member_repository.dart';

class MembersScreen extends StatefulWidget {
  const MembersScreen({
    required this.currentUser,
    required this.repository,
    super.key,
  });

  final Member currentUser;
  final MemberRepository repository;

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  final TextEditingController _queryController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();
  final LocationSuggestionService _locationSuggestions =
      LocationSuggestionService();
  List<String> _districtSuggestions = <String>[];
  List<String> _stationSuggestions = <String>[];
  Timer? _districtDebounce;
  Timer? _stationDebounce;
  int _districtRequest = 0;
  int _stationRequest = 0;
  bool _refreshing = false;
  bool _updatingLiveLocation = false;

  @override
  void initState() {
    super.initState();
    _refreshMembers();
  }

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
    final members = widget.repository
        .search(
          query: _queryController.text,
          districtFilter: _districtController.text,
        )
        .where((member) => widget.currentUser.isAdmin || member.isApproved)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const BrandedScreenTitle('All Members'),
        actions: <Widget>[
          IconButton(
            onPressed: _updatingLiveLocation ? null : _shareMyLiveLocation,
            icon: const Icon(Icons.my_location_outlined),
            tooltip: 'Share my live location',
          ),
          IconButton(
            onPressed: _refreshing ? null : _refreshMembers,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh members',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          if (_refreshing)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: LinearProgressIndicator(),
            ),
          TextField(
            controller: _queryController,
            onChanged: _onSearchChanged,
            onTap: () => _loadStationSuggestions(_queryController.text),
            decoration: const InputDecoration(
              labelText: 'Search by name, role, location',
              prefixIcon: Icon(Icons.search),
            ),
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
            onChanged: _onDistrictChanged,
            onTap: () => _loadDistrictSuggestions(_districtController.text),
            decoration: const InputDecoration(
              labelText: 'Filter by posting district',
              prefixIcon: Icon(Icons.place_outlined),
            ),
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
          const SizedBox(height: 16),
          if (members.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No members found.'),
              ),
            ),
          ...members.map(_buildMemberCard),
        ],
      ),
    );
  }

  Widget _buildMemberCard(Member member) {
    final blocked = member.isBlocked;
    final isCurrentUser = member.id == widget.currentUser.id;
    final hasLiveLocation = member.liveLatitude != null && member.liveLongitude != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    member.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (isCurrentUser)
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Chip(label: Text('You')),
                  ),
                if (!member.isApproved)
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Chip(label: Text('Pending Approval')),
                  ),
                if (blocked)
                  const Chip(
                    label: Text('Blocked'),
                    backgroundColor: Color(0xFFFDE8E8),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(member.role),
            const SizedBox(height: 4),
            Text('Mobile: ${member.mobileNumber}'),
            const SizedBox(height: 4),
            Text(
                'Posting: ${member.postingLocation}, ${member.postingDistrict}'),
            if (widget.currentUser.isAdmin) ...<Widget>[
              const SizedBox(height: 4),
              Text('Home district: ${member.homeDistrict}'),
            ],
            const SizedBox(height: 4),
            Text(
              hasLiveLocation
                  ? 'Live location available'
                  : 'Live location not shared yet',
            ),
            if (member.referenceMemberName != null) ...<Widget>[
              const SizedBox(height: 4),
              Text('Reference: ${member.referenceMemberName}'),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                OutlinedButton.icon(
                  onPressed: blocked ? null : () => _openPhone(member.mobileNumber),
                  icon: const Icon(Icons.call_outlined),
                  label: const Text('Call'),
                ),
                OutlinedButton.icon(
                  onPressed: blocked ? null : () => _openWhatsApp(member.mobileNumber),
                  icon: const Icon(Icons.chat_outlined),
                  label: const Text('WhatsApp'),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => _openMemberDetails(member),
                  icon: const Icon(Icons.badge_outlined),
                  label: const Text('View Details'),
                ),
                FilledButton.tonalIcon(
                  onPressed: hasLiveLocation
                      ? () => _openMap(member.liveLatitude!, member.liveLongitude!)
                      : null,
                  icon: const Icon(Icons.pin_drop_outlined),
                  label: const Text('Live Location'),
                ),
                if (widget.currentUser.isAdmin)
                  FilledButton.tonalIcon(
                    onPressed: () => _toggleBlock(member),
                    icon:
                        Icon(blocked ? Icons.lock_open_outlined : Icons.block),
                    label: Text(blocked ? 'Unblock' : 'Block'),
                  ),
              ],
            ),
          ],
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

  Future<void> _toggleBlock(Member member) async {
    final targetBlockState = !member.isBlocked;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(targetBlockState ? 'Block member?' : 'Unblock member?'),
          content: Text(
            targetBlockState
                ? 'This member will not be able to log in until unblocked.'
                : 'This member will be allowed to log in again.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(targetBlockState ? 'Block' : 'Unblock'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    final success = await widget.repository.setMemberBlocked(
      actor: widget.currentUser,
      memberId: member.id,
      blocked: targetBlockState,
    );

    if (!mounted) {
      return;
    }

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to update member block status.')),
      );
      return;
    }

    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(targetBlockState ? 'Member blocked.' : 'Member unblocked.'),
      ),
    );
  }

  Future<void> _openPhone(String mobile) async {
    final uri = Uri.parse('tel:$mobile');
    await launchUrl(uri);
  }

  Future<void> _openWhatsApp(String mobile) async {
    final uri = Uri.parse('https://wa.me/91$mobile');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openMap(double lat, double lng) async {
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openMemberDetails(Member member) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => MemberDetailsScreen(
          currentUser: widget.currentUser,
          member: member,
        ),
      ),
    );
  }

  Future<void> _shareMyLiveLocation() async {
    setState(() {
      _updatingLiveLocation = true;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showMessage('Location services are disabled on this device.');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showMessage('Location permission is required to share live location.');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final current = widget.repository.findById(widget.currentUser.id);
      if (current == null) {
        _showMessage('Current member profile not found.');
        return;
      }

      final updated = current.copyWith(
        liveLatitude: position.latitude,
        liveLongitude: position.longitude,
        liveLocationUpdatedAt: DateTime.now(),
        lastUpdated: DateTime.now(),
      );
      final saved = await widget.repository.saveMember(updated);
      if (!saved) {
        _showMessage('Unable to sync live location to cloud.');
        return;
      }

      if (!mounted) {
        return;
      }
      setState(() {});
      _showMessage('Live location shared successfully.');
    } catch (error) {
      _showMessage('Unable to fetch live location: $error');
    } finally {
      if (mounted) {
        setState(() {
          _updatingLiveLocation = false;
        });
      }
    }
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

  Future<void> _refreshMembers() async {
    setState(() {
      _refreshing = true;
    });

    await widget.repository.refreshFromCloud();

    if (!mounted) {
      return;
    }

    setState(() {
      _refreshing = false;
    });
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
