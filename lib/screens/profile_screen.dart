import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

import '../core/brand.dart';
import '../models/member.dart';
import '../services/donation_service.dart';
import '../services/location_suggestion_service.dart';
import '../services/member_repository.dart';
import 'admin_approvals_screen.dart';
import 'admin_donation_leaderboard_screen.dart';
import 'admin_payment_reviews_screen.dart';
import 'admin_upi_settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    required this.currentUser,
    required this.repository,
    required this.donationService,
    this.onOpenSettings,
    this.onProfileUpdated,
    super.key,
  });

  final Member currentUser;
  final MemberRepository repository;
  final DonationService donationService;
  final Future<void> Function()? onOpenSettings;
  final ValueChanged<Member>? onProfileUpdated;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _postingLocationController;
  final ImagePicker _imagePicker = ImagePicker();
  final LocationSuggestionService _locationSuggestions =
      LocationSuggestionService();
  List<String> _stationSuggestions = <String>[];
  Timer? _stationDebounce;
  int _stationRequest = 0;
  String? _selfiePath;
  Uint8List? _selfiePreviewBytes;
  bool _saving = false;
  static final RegExp _namePattern = RegExp(r"^[A-Za-z][A-Za-z .'-]{1,59}$");

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentUser.name);
    _postingLocationController =
        TextEditingController(text: widget.currentUser.postingLocation);
    _selfiePath = widget.currentUser.selfiePath;
  }

  @override
  void dispose() {
    _stationDebounce?.cancel();
    _nameController.dispose();
    _postingLocationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentUser.id != oldWidget.currentUser.id ||
        widget.currentUser.lastUpdated != oldWidget.currentUser.lastUpdated) {
      _nameController.text = widget.currentUser.name;
      _postingLocationController.text = widget.currentUser.postingLocation;
      // Preserve unsaved local preview if user is editing right now.
      if (_selfiePreviewBytes == null) {
        _selfiePath = widget.currentUser.selfiePath;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const BrandedScreenTitle('My Profile'),
        actions: <Widget>[
          if (widget.onOpenSettings != null)
            IconButton(
              onPressed: _openSettingsShortcut,
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'Open settings',
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: <Widget>[
                  const Icon(Icons.verified_user_outlined, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      user.isBlocked
                          ? 'Your profile is currently blocked. Contact admin support.'
                          : 'Profile active. Keep details updated for faster coordination.',
                    ),
                  ),
                  if (widget.onOpenSettings != null)
                    TextButton(
                      onPressed: _openSettingsShortcut,
                      child: const Text('Settings'),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Editable Basic Info',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      CircleAvatar(
                        radius: 34,
                        backgroundColor: const Color(0xFFE6ECF1),
                        backgroundImage: _profileImageProvider(),
                        child: _profileImageProvider() == null
                            ? const Icon(Icons.person, size: 36)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const Text(
                              'Profile Photo',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selfiePath == null
                                  ? 'No photo selected.'
                                  : (_selfiePreviewBytes != null
                                      ? 'Photo selected and ready to save.'
                                      : 'Cloud photo linked to your profile.'),
                              style: const TextStyle(color: Color(0xFF5A6B74)),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: <Widget>[
                                OutlinedButton.icon(
                                  onPressed: _pickProfilePhoto,
                                  icon: const Icon(Icons.photo_library_outlined),
                                  label: const Text('Choose Photo'),
                                ),
                                if (_selfiePath != null)
                                  TextButton.icon(
                                    onPressed: _removeProfilePhoto,
                                    icon: const Icon(Icons.delete_outline),
                                    label: const Text('Remove'),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Full name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _postingLocationController,
                    textCapitalization: TextCapitalization.words,
                    onChanged: _onPostingLocationChanged,
                    onTap: () =>
                        _loadStationSuggestions(_postingLocationController.text),
                    decoration: const InputDecoration(
                      labelText: 'Posting location',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                  ),
                  _buildSuggestionChips(
                    suggestions: _stationSuggestions,
                    onSelected: (station) {
                      setState(() {
                        _postingLocationController.text = station;
                        _stationSuggestions = <String>[];
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: const Icon(Icons.save_outlined),
                    label: Text(_saving ? 'Saving...' : 'Save Changes'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Admin Verified (Read-only)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  _readOnlyRow('Mobile number', user.mobileNumber),
                  _readOnlyRow('Role', user.role),
                  _readOnlyRow('Reference mobile', user.referenceMobileNumber),
                  _readOnlyRow(
                    'Reference member',
                    user.referenceMemberName ?? '-',
                  ),
                  _readOnlyRow('Home district', user.homeDistrict),
                  _readOnlyRow('Posting district', user.postingDistrict),
                  _readOnlyRow('Department', user.department ?? '-'),
                  _readOnlyRow('Post / Rank', user.postRank ?? '-'),
                  _readOnlyRow('Official name', user.officialName ?? '-'),
                  _readOnlyRow('Batch year', user.batchYear ?? '-'),
                  _readOnlyRow('WhatsApp', user.whatsappNumber ?? '-'),
                  _readOnlyRow(
                    'Calling contact',
                    user.callingContactNumber ?? '-',
                  ),
                  _readOnlyRow(
                    'Emergency contact',
                    user.emergencyContact ?? '-',
                  ),
                  _readOnlyRow(
                    'Posting place location',
                    user.postingPlaceLocation ?? '-',
                  ),
                  _readOnlyRow(
                    'Home village / mohalla',
                    user.homeVillageMohalla ?? '-',
                  ),
                  _readOnlyRow('Home gali no', user.homeGaliNo ?? '-'),
                  _readOnlyRow('Home post office', user.homePostOffice ?? '-'),
                  _readOnlyRow(
                    'Home police station',
                    user.homePoliceStation ?? '-',
                  ),
                  _readOnlyRow('Home tehsil', user.homeTehsil ?? '-'),
                  _readOnlyRow(
                    'Home village location',
                    user.homeVillageLocation ?? '-',
                  ),
                  _readOnlyRow(
                    'Live latitude',
                    user.liveLatitude?.toStringAsFixed(6) ?? '-',
                  ),
                  _readOnlyRow(
                    'Live longitude',
                    user.liveLongitude?.toStringAsFixed(6) ?? '-',
                  ),
                  _readOnlyRow(
                    'Live location updated',
                    user.liveLocationUpdatedAt?.toString() ?? '-',
                  ),
                  _readOnlyRow(
                    'Appointment date',
                    '${user.appointmentDate.day}/${user.appointmentDate.month}/${user.appointmentDate.year}',
                  ),
                  _readOnlyRow(
                    'Status',
                    user.isBlocked ? 'Blocked' : 'Active',
                  ),
                ],
              ),
            ),
          ),
          if (user.isAdmin) ...<Widget>[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Admin Pages',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.rule_folder_outlined),
                      title: const Text('Request Approvals'),
                      subtitle: const Text('Approve pending member registrations.'),
                      onTap: _openRequestApprovals,
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.leaderboard_outlined),
                      title: const Text('Donations Leaderboard'),
                      subtitle: const Text('View all member donation rankings.'),
                      onTap: _openAdminLeaderboard,
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.fact_check_outlined),
                      title: const Text('Payment Verification'),
                      subtitle: const Text(
                        'Review screenshots and verify or reject submissions.',
                      ),
                      onTap: _openPaymentVerification,
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.qr_code_2_outlined),
                      title: const Text('UPI / QR Settings'),
                      subtitle: const Text(
                        'Manage donation UPI details and custom QR image.',
                      ),
                      onTap: _openUpiSettings,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
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

  Widget _readOnlyRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF5A6B74)),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openSettingsShortcut() async {
    final openSettings = widget.onOpenSettings;
    if (openSettings == null) {
      return;
    }
    await openSettings();
  }

  Future<void> _openRequestApprovals() async {
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

  Future<void> _openAdminLeaderboard() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => AdminDonationLeaderboardScreen(
          currentUser: widget.currentUser,
          donationService: widget.donationService,
        ),
      ),
    );
  }

  Future<void> _openPaymentVerification() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => AdminPaymentReviewsScreen(
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

  Future<void> _openUpiSettings() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => AdminUpiSettingsScreen(
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

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final postingLocation = _postingLocationController.text.trim();

    if (name.isEmpty) {
      _showMessage('Name cannot be empty.');
      return;
    }
    if (!_namePattern.hasMatch(name)) {
      _showMessage('Enter a valid name (letters and spaces only).');
      return;
    }

    if (postingLocation.isEmpty) {
      _showMessage('Posting location cannot be empty.');
      return;
    }

    final validStation = await _locationSuggestions.isKnownStation(
      station: postingLocation,
      district: widget.currentUser.postingDistrict,
    );
    if (!validStation) {
      _showMessage('Choose a valid police station from suggestions.');
      return;
    }

    setState(() {
      _saving = true;
    });

    String? selfiePath = _selfiePath;
    final shouldUploadSelfie =
        selfiePath != null && _selfiePreviewBytes != null && !selfiePath.startsWith('http');
    if (shouldUploadSelfie) {
      final uploaded = await widget.repository.cloudService.uploadImageBytes(
        bytes: _selfiePreviewBytes!,
        folder: 'member-docs',
        fileName: 'profile_${widget.currentUser.id}_${DateTime.now().microsecondsSinceEpoch}.jpg',
      );
      if (uploaded == null) {
        if (!mounted) {
          return;
        }
        setState(() {
          _saving = false;
        });
        final uploadError = widget.repository.cloudService.lastUploadError;
        final message = (uploadError == null || uploadError.isEmpty)
            ? 'Unable to upload profile photo to cloud. Please retry.'
            : 'Unable to upload profile photo to cloud: $uploadError';
        _showMessage(message);
        return;
      }
      selfiePath = uploaded;
    }

    final updated = widget.currentUser.copyWith(
      name: name,
      postingLocation: postingLocation,
      selfiePath: selfiePath,
      clearSelfiePath: selfiePath == null,
      lastUpdated: DateTime.now(),
    );
    final saved = await widget.repository.saveMember(updated);

    if (!mounted) {
      return;
    }

    if (!saved) {
      setState(() {
        _saving = false;
      });
      final writeError = widget.repository.cloudService.lastWriteError;
      final message = (writeError == null || writeError.isEmpty)
          ? 'Unable to save profile to cloud. Please retry.'
          : 'Unable to save profile to cloud: $writeError';
      _showMessage(message);
      return;
    }

    widget.onProfileUpdated?.call(updated);

    setState(() {
      _saving = false;
      _selfiePath = updated.selfiePath;
      _selfiePreviewBytes = null;
    });

    // In dashboard flow this screen is pushed and should return updated member.
    // In main tab flow it is embedded and should remain on screen.
    if (widget.onProfileUpdated == null) {
      Navigator.of(context).pop(updated);
      return;
    }

    _showMessage('Profile updated successfully.');
  }

  ImageProvider<Object>? _profileImageProvider() {
    if (_selfiePreviewBytes != null) {
      return MemoryImage(_selfiePreviewBytes!);
    }
    final path = _selfiePath;
    if (path == null || path.isEmpty) {
      return null;
    }
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return NetworkImage(path);
    }
    return null;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _onPostingLocationChanged(String value) {
    _stationDebounce?.cancel();
    _stationDebounce = Timer(const Duration(milliseconds: 350), () {
      _loadStationSuggestions(value);
    });
  }

  Future<void> _loadStationSuggestions(String query) async {
    final request = ++_stationRequest;
    final suggestions = await _locationSuggestions.suggestPoliceStations(
      query: query,
      district: widget.currentUser.postingDistrict,
    );
    if (!mounted || request != _stationRequest) {
      return;
    }
    setState(() {
      _stationSuggestions = suggestions;
    });
  }

  Future<void> _pickProfilePhoto() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1200,
    );
    if (picked == null) {
      return;
    }
    final bytes = await picked.readAsBytes();
    if (!mounted) {
      return;
    }
    setState(() {
      _selfiePath = picked.path;
      _selfiePreviewBytes = bytes;
    });
  }

  void _removeProfilePhoto() {
    setState(() {
      _selfiePath = null;
      _selfiePreviewBytes = null;
    });
  }
}
