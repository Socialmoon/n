import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/brand.dart';
import '../models/member.dart';
import '../services/member_repository.dart';
import 'member_details_screen.dart';

enum _MemberFilterMode {
  district,
  postingLocation,
  currentLocation,
}

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
  _MemberFilterMode? _filterMode;
  String? _selectedDistrict;
  String? _selectedPostingLocation;
  final double _radiusKm = 100;

  @override
  void initState() {
    super.initState();
    _refreshMembers();
  }

  List<Member> get _allVisibleMembers {
    return widget.repository.activeMembers
        .where((member) => widget.currentUser.isAdmin || member.isApproved)
        .toList();
  }

  List<Member> get _filteredMembers {
    final members = _allVisibleMembers
        .where((member) => member.id != widget.currentUser.id)
        .toList();

    if (_filterMode == null) {
      return const <Member>[];
    }

    if (_filterMode == _MemberFilterMode.district) {
      final district = (_selectedDistrict ?? '').trim().toLowerCase();
      if (district.isEmpty) {
        return const <Member>[];
      }
      return members
          .where((member) => member.postingDistrict.trim().toLowerCase() == district)
          .toList();
    }

    if (_filterMode == _MemberFilterMode.postingLocation) {
      final location = (_selectedPostingLocation ?? '').trim().toLowerCase();
      if (location.isEmpty) {
        return const <Member>[];
      }
      return members
          .where((member) => member.postingLocation.trim().toLowerCase() == location)
          .toList();
    }

    final currentCoords = _currentFilterCoordinates();
    if (currentCoords == null) {
      return const <Member>[];
    }

    return members.where((member) {
      final postingCoords = _memberPostingCoordinates(member);
      if (postingCoords == null) {
        return false;
      }
      final distanceMeters = Geolocator.distanceBetween(
        currentCoords.latitude,
        currentCoords.longitude,
        postingCoords.latitude,
        postingCoords.longitude,
      );
      return distanceMeters <= _radiusKm * 1000;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isHindi = Localizations.localeOf(context).languageCode == 'hi';
    final filtered = _filteredMembers;

    return Scaffold(
      appBar: AppBar(
        title: BrandedScreenTitle(isHindi ? 'सभी सदस्य' : 'All Members'),
        actions: <Widget>[
          IconButton(
            onPressed: _updatingLiveLocation ? null : _shareMyLiveLocation,
            icon: const Icon(Icons.my_location_outlined),
            tooltip: 'Share my current location',
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
          _buildFilterPanel(filtered),
          const SizedBox(height: 12),
          if (_filterMode == null)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Select a filter first. Member data is locked until you filter by district, posting location, or 100 km radius.',
                ),
              ),
            )
          else if (filtered.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No members found for the selected filter.'),
              ),
            )
          else
            ...filtered.map(_buildMemberCard),
        ],
      ),
    );
  }

  Widget _buildFilterPanel(List<Member> filteredMembers) {
    final districts = _allVisibleMembers
        .map((member) => member.postingDistrict.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    final postingLocations = _allVisibleMembers
        .map((member) => member.postingLocation.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Member Filters',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              'Members are visible only after applying one filter.',
              style: TextStyle(color: Color(0xFF5A6B74)),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                ChoiceChip(
                  label: const Text('By District'),
                  selected: _filterMode == _MemberFilterMode.district,
                  onSelected: (_) {
                    setState(() {
                      _filterMode = _MemberFilterMode.district;
                    });
                  },
                ),
                ChoiceChip(
                  label: const Text('By Posting Location'),
                  selected: _filterMode == _MemberFilterMode.postingLocation,
                  onSelected: (_) {
                    setState(() {
                      _filterMode = _MemberFilterMode.postingLocation;
                    });
                  },
                ),
                ChoiceChip(
                  label: const Text('By 100 km Radius'),
                  selected: _filterMode == _MemberFilterMode.currentLocation,
                  onSelected: (_) {
                    setState(() {
                      _filterMode = _MemberFilterMode.currentLocation;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_filterMode == _MemberFilterMode.district)
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: districts.contains(_selectedDistrict)
                    ? _selectedDistrict
                    : null,
                decoration: const InputDecoration(labelText: 'Posting District'),
                items: districts
                    .map(
                      (district) => DropdownMenuItem<String>(
                        value: district,
                        child: Text(district),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedDistrict = value;
                  });
                },
              ),
            if (_filterMode == _MemberFilterMode.postingLocation)
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: postingLocations.contains(_selectedPostingLocation)
                    ? _selectedPostingLocation
                    : null,
                decoration: const InputDecoration(labelText: 'Posting Place Name'),
                items: postingLocations
                    .map(
                      (postingLocation) => DropdownMenuItem<String>(
                        value: postingLocation,
                        child: Text(postingLocation),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPostingLocation = value;
                  });
                },
              ),
            if (_filterMode == _MemberFilterMode.currentLocation) ...<Widget>[
              Text(
                'Showing members whose posting station coordinates are within ${_radiusKm.toInt()} km of your current shared location.',
              ),
              const SizedBox(height: 4),
              Text('Members in range: ${filteredMembers.length}'),
              const SizedBox(height: 8),
              FilledButton.tonalIcon(
                onPressed: () => _openRadiusMap(filteredMembers),
                icon: const Icon(Icons.map_outlined),
                label: const Text('Show All In-Range Members on Map'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMemberCard(Member member) {
    final isCurrentUser = member.id == widget.currentUser.id;
    final blocked = member.isBlocked;
    final lastLogin = member.lastLoginAt == null
        ? 'Never'
        : _formatDateTime(member.lastLoginAt!);

    final card = Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: _buildAvatar(member),
        title: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                member.name,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: member.isRetired ? const Color(0xFF8B6A29) : null,
                ),
              ),
            ),
            if (member.isRetired)
              const Chip(
                label: Text('Retired'),
                backgroundColor: Color(0xFFFFF4D6),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 4),
            Text('Rank: ${member.postRank ?? '-'}'),
            Text('Batch Year: ${member.batchYear ?? '-'}'),
            Text('Posting Place: ${member.postingLocation}'),
            Text('Last Login: $lastLogin'),
            if (blocked) const Text('Status: Blocked'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                OutlinedButton.icon(
                  onPressed: blocked ? null : () => _openPhone(member.mobileNumber),
                  icon: const Icon(Icons.call_outlined),
                  label: const Text('Call'),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => _openMemberDetails(member),
                  icon: const Icon(Icons.badge_outlined),
                  label: const Text('View Card'),
                ),
                if (widget.currentUser.isAdmin && !isCurrentUser)
                  PopupMenuButton<String>(
                    tooltip: 'Admin actions',
                    onSelected: (value) => _handleAdminAction(member, value),
                    itemBuilder: (context) => <PopupMenuEntry<String>>[
                      PopupMenuItem<String>(
                        value: member.isBlocked ? 'unblock' : 'block',
                        child: Text(member.isBlocked ? 'Unblock' : 'Block'),
                      ),
                      PopupMenuItem<String>(
                        value: member.isRetired ? 'unretire' : 'retire',
                        child: Text(member.isRetired ? 'Mark Active' : 'Mark Retired'),
                      ),
                      PopupMenuItem<String>(
                        value: member.isDeleted ? 'restore' : 'delete',
                        child: Text(member.isDeleted ? 'Restore' : 'Delete'),
                      ),
                    ],
                    child: const Chip(label: Text('Admin Actions')),
                  ),
              ],
            ),
          ],
        ),
      ),
    );

    if (!member.isRetired) {
      return card;
    }

    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 0.9, sigmaY: 0.9),
      child: card,
    );
  }

  Future<void> _handleAdminAction(Member member, String action) async {
    bool success = false;
    if (action == 'block') {
      success = await widget.repository.setMemberBlocked(
        actor: widget.currentUser,
        memberId: member.id,
        blocked: true,
      );
    } else if (action == 'unblock') {
      success = await widget.repository.setMemberBlocked(
        actor: widget.currentUser,
        memberId: member.id,
        blocked: false,
      );
    } else if (action == 'retire') {
      success = await widget.repository.setMemberRetired(
        actor: widget.currentUser,
        memberId: member.id,
        retired: true,
      );
    } else if (action == 'unretire') {
      success = await widget.repository.setMemberRetired(
        actor: widget.currentUser,
        memberId: member.id,
        retired: false,
      );
    } else if (action == 'delete') {
      success = await widget.repository.setMemberDeleted(
        actor: widget.currentUser,
        memberId: member.id,
        deleted: true,
      );
    } else if (action == 'restore') {
      success = await widget.repository.setMemberDeleted(
        actor: widget.currentUser,
        memberId: member.id,
        deleted: false,
      );
    }

    if (!mounted) {
      return;
    }

    if (!success) {
      _showMessage('Unable to update member status.');
      return;
    }

    setState(() {});
    _showMessage('Member status updated.');
  }

  Future<void> _openPhone(String mobile) async {
    final uri = Uri.parse('tel:$mobile');
    await launchUrl(uri);
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
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
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

  Future<void> _openRadiusMap(List<Member> filteredMembers) async {
    final coords = _currentFilterCoordinates();
    if (coords == null) {
      _showMessage('Share your live location first to use radius filter.');
      return;
    }

    final inRangeCoordinates = filteredMembers
        .map(_memberPostingCoordinates)
        .whereType<_LatLng>()
        .toList();

    if (inRangeCoordinates.isEmpty) {
      _showMessage('No in-range members with valid posting coordinates.');
      return;
    }

    // Keep URL length manageable for Google Maps by limiting waypoints.
    final cappedCoordinates = inRangeCoordinates.take(20).toList();
    final waypoints = cappedCoordinates
        .map((item) => '${item.latitude},${item.longitude}')
        .join('|');
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&origin=${coords.latitude},${coords.longitude}&destination=${coords.latitude},${coords.longitude}&waypoints=$waypoints',
    );

    if (inRangeCoordinates.length > cappedCoordinates.length) {
      _showMessage(
        'Showing first ${cappedCoordinates.length} members on map due to map waypoint limit.',
      );
    }
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  _LatLng? _currentFilterCoordinates() {
    final current = widget.repository.findById(widget.currentUser.id);
    if (current?.liveLatitude != null && current?.liveLongitude != null) {
      return _LatLng(current!.liveLatitude!, current.liveLongitude!);
    }
    return _memberPostingCoordinates(current ?? widget.currentUser);
  }

  _LatLng? _memberPostingCoordinates(Member member) {
    final raw = member.postingPlaceLocation?.trim() ?? '';
    if (raw.isEmpty) {
      return null;
    }

    final direct = RegExp(r'^\s*(-?\d+(?:\.\d+)?)\s*,\s*(-?\d+(?:\.\d+)?)\s*$')
        .firstMatch(raw);
    if (direct != null) {
      final lat = double.tryParse(direct.group(1)!);
      final lng = double.tryParse(direct.group(2)!);
      if (lat != null && lng != null) {
        return _LatLng(lat, lng);
      }
    }

    final parsed = Uri.tryParse(raw);
    if (parsed == null) {
      return null;
    }

    final query = parsed.queryParameters['query'];
    if (query != null) {
      final parts = query.split(',');
      if (parts.length == 2) {
        final lat = double.tryParse(parts[0]);
        final lng = double.tryParse(parts[1]);
        if (lat != null && lng != null) {
          return _LatLng(lat, lng);
        }
      }
    }

    return null;
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

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year;
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
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
      return CircleAvatar(
        radius: 22,
        backgroundColor: const Color(0xFFE8F0F5),
        child: Text(initial, style: const TextStyle(fontWeight: FontWeight.w700)),
      );
    }

    return ClipOval(
      child: Image.network(
        selfieUrl,
        width: 44,
        height: 44,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => CircleAvatar(
          radius: 22,
          backgroundColor: const Color(0xFFE8F0F5),
          child: Text(initial, style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}

class _LatLng {
  const _LatLng(this.latitude, this.longitude);

  final double latitude;
  final double longitude;
}
