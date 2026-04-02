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
  bool _locatingDevice = false;
  _MemberFilterMode? _filterMode;
  String? _selectedDistrict;
  String? _selectedPostingLocation;
  String? _optionalDistrict;
  String? _optionalDepartment;
  String? _optionalCategory;
  _LatLng? _deviceCoordinates;
  final double _radiusKm = 100;

  @override
  void initState() {
    super.initState();
    _refreshMembers();
    _refreshDeviceLocation(showFeedback: false, requestPermissionIfNeeded: false);
  }

  @override
  void dispose() {
    super.dispose();
  }

  List<Member> get _allVisibleMembers {
    return widget.repository.activeMembers
        .where((member) => widget.currentUser.isAdmin || member.isApproved)
        .toList();
  }

  List<Member> get _filteredMembers {
    final members = _allVisibleMembers.toList();

    if (_filterMode == null) {
      return const <Member>[];
    }

    if (_filterMode == _MemberFilterMode.district) {
      final district = (_selectedDistrict ?? '').trim().toLowerCase();
      if (district.isEmpty) {
        return const <Member>[];
      }
      final filtered = members
          .where((member) => member.postingDistrict.trim().toLowerCase() == district)
          .toList();
      return _applyOptionalFilters(filtered);
    }

    if (_filterMode == _MemberFilterMode.postingLocation) {
      final location = (_selectedPostingLocation ?? '').trim().toLowerCase();
      if (location.isEmpty) {
        return const <Member>[];
      }
      final filtered = members
          .where((member) => member.postingLocation.trim().toLowerCase() == location)
          .toList();
      return _applyOptionalFilters(filtered);
    }

    final currentCoords = _distanceOriginCoordinates();
    if (currentCoords == null) {
      return const <Member>[];
    }

    final filtered = members.where((member) {
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
    return _applyOptionalFilters(filtered);
  }

  List<Member> _applyOptionalFilters(List<Member> members) {
    final district = (_optionalDistrict ?? '').trim().toLowerCase();
    final department = (_optionalDepartment ?? '').trim().toLowerCase();
    final category = (_optionalCategory ?? '').trim().toLowerCase();

    final filtered = members.where((member) {
      final districtMatch = district.isEmpty ||
          member.postingDistrict.trim().toLowerCase() == district;
      final departmentValue = (member.department ?? '').trim().toLowerCase();
      final departmentMatch = department.isEmpty || departmentValue == department;
      final categoryValue = _displayValue(member.postingCategory ?? '')
        .trim()
        .toLowerCase();
      final categoryMatch = category.isEmpty || categoryValue == category;

      return districtMatch && departmentMatch && categoryMatch;
    }).toList();

    return _sortByDistanceIfAvailable(filtered);
  }

  List<Member> _sortByDistanceIfAvailable(List<Member> members) {
    final current = _distanceOriginCoordinates();
    if (current == null) {
      return members;
    }

    final sorted = List<Member>.from(members);
    sorted.sort((a, b) {
      final da = _distanceKmFromCurrent(a, current);
      final db = _distanceKmFromCurrent(b, current);
      if (da == null && db == null) {
        return a.name.compareTo(b.name);
      }
      if (da == null) {
        return 1;
      }
      if (db == null) {
        return -1;
      }
      return da.compareTo(db);
    });
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final isHindi = Localizations.localeOf(context).languageCode == 'hi';
    final filtered = _filteredMembers;
    final distanceOrigin = _distanceOriginCoordinates();
    final minDistanceKm = _minimumDistanceKm(filtered, distanceOrigin);

    return Scaffold(
      appBar: AppBar(
        title: BrandedScreenTitle(isHindi ? 'सभी सदस्य' : 'All Members'),
        actions: <Widget>[
          IconButton(
            onPressed: (_locatingDevice || _updatingLiveLocation)
                ? null
                : _useAndShareCurrentLocation,
            icon: const Icon(Icons.my_location_outlined),
            tooltip: 'Use and share my current location',
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
          if (_filterMode != null && distanceOrigin == null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3CD),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE5D4A1)),
              ),
              child: Row(
                children: <Widget>[
                  const Icon(Icons.location_off_outlined, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isHindi
                          ? 'दूरी और निकटतम सदस्य देखने के लिए कृपया डिवाइस की वर्तमान लोकेशन सक्षम करें।'
                          : 'Enable current location to calculate nearest member distance.',
                      style: const TextStyle(fontSize: 12.5),
                    ),
                  ),
                ],
              ),
            ),
          _buildFilterPanel(filtered),
          if (minDistanceKm != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFE7F5EE),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFB7DDBF)),
              ),
              child: Text(
                isHindi
                    ? 'आपसे न्यूनतम दूरी: ${minDistanceKm.toStringAsFixed(1)} किमी'
                    : 'Minimum distance from your current location: ${minDistanceKm.toStringAsFixed(1)} km',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          const SizedBox(height: 12),
          if (_filterMode == null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  isHindi
                      ? 'पहले फ़िल्टर चुनें। जिला, पोस्टिंग लोकेशन या रेडियस फ़िल्टर लगाने के बाद सदस्य दिखेंगे।'
                      : 'Select a filter first. Member data is visible after applying district, posting location, or radius filter.',
                ),
              ),
            )
          else if (filtered.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(isHindi
                    ? 'चुने गए फ़िल्टर के लिए कोई सदस्य नहीं मिला।'
                    : 'No members found for the selected filters.'),
              ),
            )
          else
            ...filtered.map(_buildMemberCard),
        ],
      ),
    );
  }

  Widget _buildFilterPanel(List<Member> filteredMembers) {
    final isHindi = Localizations.localeOf(context).languageCode == 'hi';
    final districts = _allVisibleMembers
        .map((member) => member.postingDistrict.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    final departments = _allVisibleMembers
        .map((member) => (member.department ?? '').trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    final categories = _allVisibleMembers
        .map((member) => (member.postingCategory ?? '').trim())
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
            Text(
              isHindi ? 'सदस्य फ़िल्टर' : 'Member Filters',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              isHindi
                  ? 'कम से कम एक फ़िल्टर लगाने के बाद ही सदस्य दिखेंगे।'
                  : 'Members are visible only after applying one filter.',
              style: const TextStyle(color: Color(0xFF5A6B74)),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                ChoiceChip(
                  label: Text(isHindi ? 'जिले से' : 'By District'),
                  selected: _filterMode == _MemberFilterMode.district,
                  onSelected: (_) {
                    setState(() {
                      _filterMode = _MemberFilterMode.district;
                    });
                  },
                ),
                ChoiceChip(
                  label: Text(isHindi ? 'पोस्टिंग लोकेशन से' : 'By Posting Location'),
                  selected: _filterMode == _MemberFilterMode.postingLocation,
                  onSelected: (_) {
                    setState(() {
                      _filterMode = _MemberFilterMode.postingLocation;
                    });
                  },
                ),
                ChoiceChip(
                  label: Text(isHindi ? '100 किमी रेडियस' : 'By 100 km Radius'),
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
              _buildTypeablePickerField(
                labelText: isHindi ? 'पोस्टिंग जिला' : 'Posting District',
                value: _selectedDistrict,
                options: districts,
                onChanged: (value) {
                  setState(() {
                    _selectedDistrict = value;
                  });
                },
              ),
            if (_filterMode == _MemberFilterMode.postingLocation)
              _buildTypeablePickerField(
                labelText: isHindi ? 'पोस्टिंग स्थान नाम' : 'Posting Place Name',
                value: _selectedPostingLocation,
                options: postingLocations,
                onChanged: (value) {
                  setState(() {
                    _selectedPostingLocation = value;
                  });
                },
              ),
            if (_filterMode == _MemberFilterMode.currentLocation) ...<Widget>[
              if (_distanceOriginCoordinates() == null)
                Text(
                  isHindi
                      ? 'रेडियस फ़िल्टर के लिए डिवाइस लोकेशन चालू करें।'
                      : 'Enable device location first to use radius filter.',
                )
              else
                Text(
                  isHindi
                      ? 'आपकी वर्तमान लोकेशन से ${_radiusKm.toInt()} किमी के भीतर पोस्टिंग स्थान वाले सदस्य दिख रहे हैं।'
                      : 'Showing members whose posting station coordinates are within ${_radiusKm.toInt()} km of your current location.',
                ),
              const SizedBox(height: 4),
              Text(isHindi
                  ? 'रेडियस में सदस्य: ${filteredMembers.length}'
                  : 'Members in range: ${filteredMembers.length}'),
              const SizedBox(height: 8),
              FilledButton.tonalIcon(
                onPressed: () => _openRadiusMap(filteredMembers),
                icon: const Icon(Icons.map_outlined),
                label: Text(isHindi
                    ? 'मैप पर सभी सदस्य दिखाएं'
                    : 'Show All In-Range Members on Map'),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              isHindi ? 'अतिरिक्त वैकल्पिक फ़िल्टर' : 'Additional optional filters',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            _buildTypeablePickerField(
              labelText:
                  isHindi ? 'पोस्टिंग जिला (वैकल्पिक)' : 'Posting District (Optional)',
              value: _optionalDistrict,
              options: districts,
              onChanged: (value) {
                setState(() {
                  _optionalDistrict = value;
                });
              },
              emptyLabel: isHindi ? 'सभी जिले' : 'All Districts',
            ),
            const SizedBox(height: 8),
            _buildTypeablePickerField(
              labelText: isHindi ? 'विभाग (वैकल्पिक)' : 'Department (Optional)',
              value: _optionalDepartment,
              options: departments,
              onChanged: (value) {
                setState(() {
                  _optionalDepartment = value;
                });
              },
              emptyLabel: isHindi ? 'सभी विभाग' : 'All Departments',
            ),
            const SizedBox(height: 8),
            _buildTypeablePickerField(
              labelText: isHindi
                  ? 'पोस्टिंग कैटेगरी (वैकल्पिक)'
                  : 'Posting Category (Optional)',
              value: _optionalCategory,
              options: categories.map(_displayValue).toList(),
              onChanged: (value) {
                setState(() {
                  _optionalCategory = value;
                });
              },
              emptyLabel: isHindi ? 'सभी कैटेगरी' : 'All Categories',
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    _optionalDistrict = null;
                    _optionalDepartment = null;
                    _optionalCategory = null;
                  });
                },
                icon: const Icon(Icons.restart_alt_outlined),
                label: Text(isHindi ? 'फ़िल्टर साफ़ करें' : 'Clear Optional Filters'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberCard(Member member) {
    final isCurrentUser = member.id == widget.currentUser.id;
    final blocked = member.isBlocked;
    final currentCoords = _distanceOriginCoordinates();
    final distanceKm = _distanceKmFromCurrent(member, currentCoords);
    final lastLogin = member.lastLoginAt == null
        ? 'Never'
        : _formatDateTime(member.lastLoginAt!);

    final card = Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openMemberDetails(member),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  _buildAvatar(member),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          member.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: member.isRetired ? const Color(0xFF8B6A29) : null,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Rank: ${_displayValue(member.postRank ?? '-')}   Batch: ${member.batchYear ?? '-'}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF5A6B74)),
                        ),
                        Text(
                          'Posting district: ${_displayValue(member.postingDistrict)}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF5A6B74)),
                        ),
                        Text(
                          'Posting location: ${_displayValue(member.postingLocation)}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF5A6B74)),
                        ),
                        if (distanceKm != null)
                          Text(
                            'Distance from you: ${distanceKm.toStringAsFixed(1)} km',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF0F5C6E), fontWeight: FontWeight.w600),
                          ),
                      ],
                    ),
                  ),
                  if (isCurrentUser)
                    const Chip(
                      label: Text('You'),
                      visualDensity: VisualDensity.compact,
                    ),
                  if (member.isRetired)
                    const Chip(
                      label: Text('Retired'),
                      backgroundColor: Color(0xFFFFF4D6),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      blocked ? 'Status: Blocked' : 'Last Login: $lastLogin',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF5A6B74)),
                    ),
                  ),
                  if (!blocked)
                    IconButton(
                      onPressed: () => _openPhone(member.mobileNumber),
                      icon: const Icon(Icons.call_outlined, size: 20),
                      tooltip: 'Call',
                    ),
                  if (!blocked)
                    IconButton(
                      onPressed: () => _openWhatsApp(member.whatsappNumber ?? member.mobileNumber),
                      icon: const Icon(Icons.chat_outlined, size: 20),
                      tooltip: 'WhatsApp',
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
                    ),
                ],
              ),
            ],
          ),
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

  Future<void> _openWhatsApp(String mobile) async {
    final digits = mobile.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      _showMessage('WhatsApp number not available.');
      return;
    }
    final normalized = digits.length > 10 ? digits : '91$digits';
    final uri = Uri.parse('https://wa.me/$normalized');
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

  Future<void> _useAndShareCurrentLocation() async {
    setState(() {
      _locatingDevice = true;
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
        _showMessage('Location permission is required to use and share current location.');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      if (mounted) {
        setState(() {
          _deviceCoordinates = _LatLng(position.latitude, position.longitude);
        });
      }

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
      _showMessage('Current location enabled and shared successfully.');
    } catch (error) {
      _showMessage('Unable to fetch current location: $error');
    } finally {
      if (mounted) {
        setState(() {
          _locatingDevice = false;
          _updatingLiveLocation = false;
        });
      }
    }
  }

  Future<void> _openRadiusMap(List<Member> filteredMembers) async {
    final coords = _distanceOriginCoordinates();
    if (coords == null) {
      _showMessage('Enable current location first to use radius filter.');
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

  _LatLng? _currentSharedCoordinates() {
    final current = widget.repository.findById(widget.currentUser.id);
    if (current?.liveLatitude != null && current?.liveLongitude != null) {
      return _LatLng(current!.liveLatitude!, current.liveLongitude!);
    }
    return null;
  }

  _LatLng? _distanceOriginCoordinates() {
    return _deviceCoordinates ?? _currentSharedCoordinates();
  }

  double? _minimumDistanceKm(List<Member> members, _LatLng? origin) {
    if (origin == null || members.isEmpty) {
      return null;
    }

    double? minDistance;
    for (final member in members) {
      final distance = _distanceKmFromCurrent(member, origin);
      if (distance == null) {
        continue;
      }
      if (minDistance == null || distance < minDistance) {
        minDistance = distance;
      }
    }
    return minDistance;
  }

  Future<void> _refreshDeviceLocation({
    required bool showFeedback,
    required bool requestPermissionIfNeeded,
  }) async {
    setState(() {
      _locatingDevice = true;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (showFeedback) {
          _showMessage('Location services are disabled on this device.');
        }
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied && requestPermissionIfNeeded) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (showFeedback) {
          _showMessage('Location permission is required for distance calculation.');
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      if (!mounted) {
        return;
      }
      setState(() {
        _deviceCoordinates = _LatLng(position.latitude, position.longitude);
      });
      if (showFeedback) {
        _showMessage('Current location enabled for distance calculation.');
      }
    } catch (error) {
      if (showFeedback) {
        _showMessage('Unable to fetch current location: $error');
      }
    } finally {
      if (mounted) {
        setState(() {
          _locatingDevice = false;
        });
      }
    }
  }

  Widget _buildTypeablePickerField({
    required String labelText,
    required String? value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
    String? emptyLabel,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () async {
          final picked = await _pickTypedValue(
            title: labelText,
            options: options,
            initialValue: value,
            emptyLabel: emptyLabel,
          );
          onChanged(picked);
        },
        child: AbsorbPointer(
          child: TextFormField(
            initialValue: value ?? '',
            decoration: InputDecoration(
              labelText: labelText,
              hintText: emptyLabel,
              suffixIcon: const Icon(Icons.arrow_drop_down_rounded),
            ),
          ),
        ),
      ),
    );
  }

  Future<String?> _pickTypedValue({
    required String title,
    required List<String> options,
    required String? initialValue,
    String? emptyLabel,
  }) async {
    return showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final textController = TextEditingController(text: initialValue ?? '');
        String query = '';
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final filtered = query.trim().isEmpty
                ? options
                : options
                    .where((item) => item.toLowerCase().contains(query.toLowerCase()))
                    .toList();

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.72,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    TextField(
                      controller: textController,
                      decoration: InputDecoration(
                        labelText: 'Type or search',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: IconButton(
                          onPressed: () {
                            textController.clear();
                            setSheetState(() {
                              query = '';
                            });
                          },
                          icon: const Icon(Icons.clear),
                        ),
                      ),
                      onChanged: (value) {
                        setSheetState(() {
                          query = value;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    if (emptyLabel != null)
                      ListTile(
                        title: Text(emptyLabel),
                        leading: const Icon(Icons.filter_alt_off_outlined),
                        onTap: () => Navigator.of(context).pop(null),
                      ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final value = filtered[index];
                          return ListTile(
                            title: Text(value),
                            onTap: () => Navigator.of(context).pop(value),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.tonal(
                        onPressed: () {
                          final typed = textController.text.trim();
                          if (typed.isEmpty) {
                            Navigator.of(context).pop(null);
                            return;
                          }
                          Navigator.of(context).pop(typed);
                        },
                        child: const Text('Use typed value'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  double? _distanceKmFromCurrent(Member member, _LatLng? currentCoords) {
    if (currentCoords == null) {
      return null;
    }
    final posting = _memberPostingCoordinates(member);
    if (posting == null) {
      return null;
    }
    final meters = Geolocator.distanceBetween(
      currentCoords.latitude,
      currentCoords.longitude,
      posting.latitude,
      posting.longitude,
    );
    return meters / 1000;
  }

  String _displayValue(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'n/a' || normalized == 'na') {
      return 'Others';
    }
    return value;
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
