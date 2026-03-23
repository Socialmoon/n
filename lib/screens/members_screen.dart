import 'package:geolocator/geolocator.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/brand.dart';
import '../models/member.dart';
import 'member_details_screen.dart';
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
  bool _refreshing = false;
  bool _updatingLiveLocation = false;

  @override
  void initState() {
    super.initState();
    _refreshMembers();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isHindi = Localizations.localeOf(context).languageCode == 'hi';
    final visibleMembers = widget.repository
        .search(
          query: '',
          districtFilter: '',
        )
        .where((member) => widget.currentUser.isAdmin || member.isApproved)
        .toList();

    final members = <Member>[];
    final mine = visibleMembers.firstWhere(
      (member) => member.id == widget.currentUser.id,
      orElse: () => widget.currentUser,
    );
    members.add(mine);
    members.addAll(
      visibleMembers.where((member) => member.id != widget.currentUser.id),
    );

    return Scaffold(
      appBar: AppBar(
        title: BrandedScreenTitle(isHindi ? 'सभी सदस्य' : 'All Members'),
        actions: <Widget>[
          IconButton(
            onPressed: _openSearchPage,
            icon: const Icon(Icons.search),
            tooltip: 'Search members',
          ),
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
                _buildAvatar(member),
                const SizedBox(width: 10),
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

  Future<void> _openSearchPage() async {
    final selected = await showSearch<Member?>(
      context: context,
      delegate: MemberSearchDelegate(
        currentUser: widget.currentUser,
        repository: widget.repository,
      ),
    );
    if (!mounted || selected == null) {
      return;
    }
    await _openMemberDetails(selected);
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

  Widget _buildAvatar(Member member) {
    final selfieUrl = member.selfiePath?.trim() ?? '';
    final initial = member.name.isEmpty ? '?' : member.name[0].toUpperCase();
    if (selfieUrl.isEmpty) {
      return _buildInitialAvatar(initial);
    }

    return ClipOval(
      child: Image.network(
        selfieUrl,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildInitialAvatar(initial),
      ),
    );
  }

  Widget _buildInitialAvatar(String initial) {
    return CircleAvatar(
      radius: 20,
      backgroundColor: const Color(0xFFE8F0F5),
      child: Text(initial, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}

class MemberSearchDelegate extends SearchDelegate<Member?> {
  MemberSearchDelegate({
    required this.currentUser,
    required this.repository,
  });

  final Member currentUser;
  final MemberRepository repository;

  @override
  String get searchFieldLabel => 'Search by name or posting details';

  List<Member> _results(String input) {
    final members = repository
        .search(query: input, districtFilter: '')
        .where((member) => currentUser.isAdmin || member.isApproved)
        .toList();
    return members;
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return <Widget>[
      if (query.isNotEmpty)
        IconButton(
          onPressed: () => query = '',
          icon: const Icon(Icons.clear),
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () => close(context, null),
      icon: const Icon(Icons.arrow_back),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = _results(query).take(12).toList();
    if (query.trim().isEmpty) {
      return const Center(
        child: Text('Type a name, role, posting place, or district.'),
      );
    }
    if (suggestions.isEmpty) {
      return const Center(
        child: Text('No matching member suggestions.'),
      );
    }
    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final member = suggestions[index];
        return ListTile(
          leading: const Icon(Icons.person_outline),
          title: Text(member.name),
          subtitle: Text('${member.postingLocation}, ${member.postingDistrict}'),
          trailing: const Icon(Icons.north_west),
          onTap: () => close(context, member),
        );
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = _results(query);
    if (results.isEmpty) {
      return const Center(
        child: Text('No members found for this search.'),
      );
    }
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final member = results[index];
        return ListTile(
          leading: const CircleAvatar(
            child: Icon(Icons.person_outline),
          ),
          title: Text(member.name),
          subtitle: Text('${member.role} • ${member.postingLocation}, ${member.postingDistrict}'),
          onTap: () => close(context, member),
        );
      },
    );
  }
}
