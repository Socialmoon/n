import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../core/brand.dart';
import '../models/member.dart';
import '../services/auth_service.dart';
import '../services/donation_service.dart';
import '../services/email_otp_service.dart';
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
    required this.authService,
    required this.donationService,
    this.onOpenSettings,
    this.onProfileUpdated,
    super.key,
  });

  final Member currentUser;
  final MemberRepository repository;
  final AuthService authService;
  final DonationService donationService;
  final Future<void> Function()? onOpenSettings;
  final ValueChanged<Member>? onProfileUpdated;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _emailOtpController;
  late final TextEditingController _postingLocationController;
  late final TextEditingController _homeStateController;
  late final TextEditingController _homeDistrictController;
  late final TextEditingController _postingStateController;
  late final TextEditingController _postingDistrictController;
  late final TextEditingController _departmentController;
  late final TextEditingController _postRankController;
  late final TextEditingController _officialNameController;
  late final TextEditingController _batchYearController;
  late final TextEditingController _genderController;
  late final TextEditingController _maritalStatusController;
  late final TextEditingController _postingCategoryController;
  late final TextEditingController _postingWorkAsController;
  late final TextEditingController _whatsappController;
  late final TextEditingController _callingContactController;
  late final TextEditingController _postingPlaceLocationController;
  late final TextEditingController _homeVillageMohallaController;
  late final TextEditingController _homeGaliNoController;
  late final TextEditingController _homePostOfficeController;
  late final TextEditingController _homePoliceStationController;
  late final TextEditingController _homeTehsilController;
  late final TextEditingController _homeVillageLocationController;
  final ImagePicker _imagePicker = ImagePicker();
  final LocationSuggestionService _locationSuggestions =
      LocationSuggestionService();
  final EmailOtpService _emailOtpService = EmailOtpService();
  List<String> _stationSuggestions = <String>[];
  Timer? _stationDebounce;
  int _stationRequest = 0;
  String? _selfiePath;
  Uint8List? _selfiePreviewBytes;
  bool _saving = false;
  bool _updatingBiometric = false;
  bool _sendingEmailOtp = false;
  bool _verifyingEmailOtp = false;
  bool _emailOtpSent = false;
  static final RegExp _namePattern = RegExp(r"^[A-Za-z][A-Za-z .'-]{1,59}$");
  static final RegExp _emailPattern = RegExp(r'^[^@]+@[^@]+\.[^@]+$');

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentUser.name);
    _emailController = TextEditingController(text: widget.currentUser.email ?? '');
    _emailOtpController = TextEditingController();
    _postingLocationController =
        TextEditingController(text: widget.currentUser.postingLocation);
    _homeStateController = TextEditingController(text: widget.currentUser.homeState ?? '');
    _homeDistrictController = TextEditingController(text: widget.currentUser.homeDistrict);
    _postingStateController = TextEditingController(text: widget.currentUser.postingState ?? '');
    _postingDistrictController = TextEditingController(text: widget.currentUser.postingDistrict);
    _departmentController = TextEditingController(text: widget.currentUser.department ?? '');
    _postRankController = TextEditingController(text: widget.currentUser.postRank ?? '');
    _officialNameController = TextEditingController(text: widget.currentUser.officialName ?? '');
    _batchYearController = TextEditingController(text: widget.currentUser.batchYear ?? '');
    _genderController = TextEditingController(text: widget.currentUser.gender ?? '');
    _maritalStatusController = TextEditingController(text: widget.currentUser.maritalStatus ?? '');
    _postingCategoryController = TextEditingController(text: widget.currentUser.postingCategory ?? '');
    _postingWorkAsController = TextEditingController(text: widget.currentUser.postingWorkAs ?? '');
    _whatsappController = TextEditingController(text: widget.currentUser.whatsappNumber ?? '');
    _callingContactController = TextEditingController(text: widget.currentUser.callingContactNumber ?? '');
    _postingPlaceLocationController = TextEditingController(text: widget.currentUser.postingPlaceLocation ?? '');
    _homeVillageMohallaController = TextEditingController(text: widget.currentUser.homeVillageMohalla ?? '');
    _homeGaliNoController = TextEditingController(text: widget.currentUser.homeGaliNo ?? '');
    _homePostOfficeController = TextEditingController(text: widget.currentUser.homePostOffice ?? '');
    _homePoliceStationController = TextEditingController(text: widget.currentUser.homePoliceStation ?? '');
    _homeTehsilController = TextEditingController(text: widget.currentUser.homeTehsil ?? '');
    _homeVillageLocationController = TextEditingController(text: widget.currentUser.homeVillageLocation ?? '');
    _selfiePath = widget.currentUser.selfiePath;
  }

  @override
  void dispose() {
    _stationDebounce?.cancel();
    _nameController.dispose();
    _emailController.dispose();
    _emailOtpController.dispose();
    _postingLocationController.dispose();
    _homeStateController.dispose();
    _homeDistrictController.dispose();
    _postingStateController.dispose();
    _postingDistrictController.dispose();
    _departmentController.dispose();
    _postRankController.dispose();
    _officialNameController.dispose();
    _batchYearController.dispose();
    _genderController.dispose();
    _maritalStatusController.dispose();
    _postingCategoryController.dispose();
    _postingWorkAsController.dispose();
    _whatsappController.dispose();
    _callingContactController.dispose();
    _postingPlaceLocationController.dispose();
    _homeVillageMohallaController.dispose();
    _homeGaliNoController.dispose();
    _homePostOfficeController.dispose();
    _homePoliceStationController.dispose();
    _homeTehsilController.dispose();
    _homeVillageLocationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentUser.id != oldWidget.currentUser.id ||
        widget.currentUser.lastUpdated != oldWidget.currentUser.lastUpdated) {
      _nameController.text = widget.currentUser.name;
      _emailController.text = widget.currentUser.email ?? '';
      _emailOtpController.clear();
      _emailOtpSent = false;
      _postingLocationController.text = widget.currentUser.postingLocation;
      _homeStateController.text = widget.currentUser.homeState ?? '';
      _homeDistrictController.text = widget.currentUser.homeDistrict;
      _postingStateController.text = widget.currentUser.postingState ?? '';
      _postingDistrictController.text = widget.currentUser.postingDistrict;
      _departmentController.text = widget.currentUser.department ?? '';
      _postRankController.text = widget.currentUser.postRank ?? '';
      _officialNameController.text = widget.currentUser.officialName ?? '';
      _batchYearController.text = widget.currentUser.batchYear ?? '';
      _genderController.text = widget.currentUser.gender ?? '';
      _maritalStatusController.text = widget.currentUser.maritalStatus ?? '';
      _postingCategoryController.text = widget.currentUser.postingCategory ?? '';
      _postingWorkAsController.text = widget.currentUser.postingWorkAs ?? '';
      _whatsappController.text = widget.currentUser.whatsappNumber ?? '';
      _callingContactController.text = widget.currentUser.callingContactNumber ?? '';
      _postingPlaceLocationController.text = widget.currentUser.postingPlaceLocation ?? '';
      _homeVillageMohallaController.text = widget.currentUser.homeVillageMohalla ?? '';
      _homeGaliNoController.text = widget.currentUser.homeGaliNo ?? '';
      _homePostOfficeController.text = widget.currentUser.homePostOffice ?? '';
      _homePoliceStationController.text = widget.currentUser.homePoliceStation ?? '';
      _homeTehsilController.text = widget.currentUser.homeTehsil ?? '';
      _homeVillageLocationController.text = widget.currentUser.homeVillageLocation ?? '';
      // Preserve unsaved local preview if user is editing right now.
      if (_selfiePreviewBytes == null) {
        _selfiePath = widget.currentUser.selfiePath;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.currentUser;
    final biometricEnabled = widget.authService.isBiometricEnabledForMember(user);
    final hasEmail = (user.email?.trim().isNotEmpty ?? false);
    final needsPostingLocationUpdate =
        (user.postingPlaceLocation?.trim().isEmpty ?? true);
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
          if (!hasEmail) ...<Widget>[
            const SizedBox(height: 12),
            Card(
              color: const Color(0xFFFFE9E9),
              child: ListTile(
                leading: const Icon(Icons.warning_amber_rounded, color: Color(0xFFB3261E)),
                title: const Text(
                  'Urgent: Add your email',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text(
                  'Your account has no email. Add and verify it now to enable OTP on new-device login.',
                ),
                trailing: FilledButton.tonal(
                  onPressed: _openEmailVerificationSheet,
                  child: const Text('Add Email'),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: Icon(
                biometricEnabled ? Icons.fingerprint_rounded : Icons.fingerprint_outlined,
              ),
              title: const Text('Fingerprint Login'),
              subtitle: Text(
                biometricEnabled
                    ? 'Fingerprint is enabled for this account. You can update it any time.'
                    : 'Enable fingerprint for this account to use biometric login.',
              ),
              trailing: FilledButton.tonal(
                onPressed: _updatingBiometric ? null : _registerOrUpdateFingerprint,
                child: Text(
                  _updatingBiometric
                      ? 'Please wait...'
                      : (biometricEnabled ? 'Update' : 'Enable'),
                ),
              ),
            ),
          ),
          if (needsPostingLocationUpdate) ...<Widget>[
            const SizedBox(height: 12),
            Card(
              color: const Color(0xFFFFF3CD),
              child: ListTile(
                leading: const Icon(Icons.warning_amber_rounded),
                title: const Text('Posting location not uploaded'),
                subtitle: const Text(
                  'Your posting place location is missing or marked as upload later. '
                  'Please update it so members can locate you accurately.',
                ),
                trailing: FilledButton.tonal(
                  onPressed: _openUpdateInfoPage,
                  child: const Text('Update'),
                ),
              ),
            ),
          ],
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
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.edit_note_outlined),
                    title: const Text('Update full profile information'),
                    subtitle: const Text(
                      'Open a separate page to submit full profile update request for admin approval.',
                    ),
                    trailing: FilledButton.tonal(
                      onPressed: _openUpdateInfoPage,
                      child: const Text('Open'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: const Icon(Icons.save_outlined),
                      label: Text(_saving ? 'Saving...' : 'Save Basic Changes'),
                    ),
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
                  _readOnlyRow('Email', user.email?.trim().isEmpty ?? true ? '-' : user.email!),
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

  Future<void> _openUpdateInfoPage() async {
    final previousValues = <String, String>{
      'Posting Location': _postingLocationController.text.trim(),
      'Home State': _homeStateController.text.trim(),
      'Home District': _homeDistrictController.text.trim(),
      'Posting State': _postingStateController.text.trim(),
      'Posting District': _postingDistrictController.text.trim(),
      'Whatsapp Number': _whatsappController.text.trim(),
      'Calling Contact Number': _callingContactController.text.trim(),
      'Posting Place Location': _postingPlaceLocationController.text.trim(),
      'Home Village / Mohalla': _homeVillageMohallaController.text.trim(),
      'Home Gali No': _homeGaliNoController.text.trim(),
      'Home Police Station': _homePoliceStationController.text.trim(),
      'Home Tehsil': _homeTehsilController.text.trim(),
      'Home Village Location': _homeVillageLocationController.text.trim(),
    };

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => _ProfileUpdateInfoScreen(
          postingLocationController: _postingLocationController,
          homeStateController: _homeStateController,
          homeDistrictController: _homeDistrictController,
          postingStateController: _postingStateController,
          postingDistrictController: _postingDistrictController,
          whatsappController: _whatsappController,
          callingContactController: _callingContactController,
          postingPlaceLocationController: _postingPlaceLocationController,
          homeVillageMohallaController: _homeVillageMohallaController,
          homeGaliNoController: _homeGaliNoController,
          homePoliceStationController: _homePoliceStationController,
          homeTehsilController: _homeTehsilController,
          homeVillageLocationController: _homeVillageLocationController,
          previousValues: previousValues,
          saving: _saving,
          onSave: _save,
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

  Future<bool> _save() async {
    final name = _nameController.text.trim();
    final postingLocation = _postingLocationController.text.trim();
    final homeDistrict = _homeDistrictController.text.trim();
    final postingDistrict = _postingDistrictController.text.trim();
    final homePoliceStation = _homePoliceStationController.text.trim();
    final whatsappNumber = _whatsappController.text.trim();
    final callingContactNumber = _callingContactController.text.trim();
    final currentProfile = _currentPublicProfileSnapshot(widget.currentUser);
    final currentPostingLocation =
        (currentProfile['postingLocation'] ?? '').toString().trim();
    final postingLocationChanged =
        postingLocation.toLowerCase() != currentPostingLocation.toLowerCase();

    if (name.isEmpty) {
      _showMessage('Name cannot be empty.');
      return false;
    }
    if (!_namePattern.hasMatch(name)) {
      _showMessage('Enter a valid name (letters and spaces only).');
      return false;
    }

    if (postingLocation.isEmpty) {
      _showMessage('Posting location cannot be empty.');
      return false;
    }

    if (postingLocationChanged && !_isAcceptableStationValue(postingLocation)) {
      _showMessage('Enter a valid posting location name.');
      return false;
    }

    if (homeDistrict.isEmpty || postingDistrict.isEmpty || homePoliceStation.isEmpty) {
      _showMessage('Home district, posting district, and home police station are required.');
      return false;
    }

    final homeDistrictValid = await _locationSuggestions.isKnownDistrict(homeDistrict);
    if (!homeDistrictValid) {
      _showMessage('Choose a valid home district from options.');
      return false;
    }

    final postingDistrictValid = await _locationSuggestions.isKnownDistrict(postingDistrict);
    if (!postingDistrictValid) {
      _showMessage('Choose a valid posting district from options.');
      return false;
    }

    if (!_isAcceptableStationValue(homePoliceStation)) {
      _showMessage('Enter a valid home police station name.');
      return false;
    }

    if (!_isValidContactNumber(whatsappNumber) ||
        !_isValidContactNumber(callingContactNumber)) {
      _showMessage('WhatsApp and Calling contact must be 10-digit numbers.');
      return false;
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
          return false;
        }
        setState(() {
          _saving = false;
        });
        final uploadError = widget.repository.cloudService.lastUploadError;
        final message = (uploadError == null || uploadError.isEmpty)
            ? 'Unable to upload profile photo to cloud. Please retry.'
            : 'Unable to upload profile photo to cloud: $uploadError';
        _showMessage(message);
        return false;
      }
      selfiePath = uploaded;
    }

    Member updated;
    if (widget.currentUser.isAdmin) {
      updated = widget.currentUser.copyWith(
        name: name,
        postingLocation: postingLocation,
        homeState: _homeStateController.text.trim(),
        homeDistrict: _homeDistrictController.text.trim(),
        postingState: _postingStateController.text.trim(),
        postingDistrict: _postingDistrictController.text.trim(),
        department: _departmentController.text.trim(),
        postRank: _postRankController.text.trim(),
        officialName: _officialNameController.text.trim(),
        batchYear: _batchYearController.text.trim(),
        gender: _genderController.text.trim(),
        maritalStatus: _maritalStatusController.text.trim(),
        postingCategory: _postingCategoryController.text.trim(),
        postingWorkAs: _postingWorkAsController.text.trim(),
        whatsappNumber: _whatsappController.text.trim(),
        callingContactNumber: _callingContactController.text.trim(),
        postingPlaceLocation: _postingPlaceLocationController.text.trim(),
        homeVillageMohalla: _homeVillageMohallaController.text.trim(),
        homeGaliNo: _homeGaliNoController.text.trim(),
        homePostOffice: _homePostOfficeController.text.trim(),
        homePoliceStation: _homePoliceStationController.text.trim(),
        homeTehsil: _homeTehsilController.text.trim(),
        homeVillageLocation: _homeVillageLocationController.text.trim(),
        selfiePath: selfiePath,
        clearSelfiePath: selfiePath == null,
        lastUpdated: DateTime.now(),
      );
    } else {
      final candidate = <String, dynamic>{
        'name': name,
        'postingLocation': postingLocation,
        'homeState': _homeStateController.text.trim(),
        'homeDistrict': _homeDistrictController.text.trim(),
        'postingState': _postingStateController.text.trim(),
        'postingDistrict': _postingDistrictController.text.trim(),
        'whatsappNumber': _whatsappController.text.trim(),
        'callingContactNumber': _callingContactController.text.trim(),
        'postingPlaceLocation': _postingPlaceLocationController.text.trim(),
        'homeVillageMohalla': _homeVillageMohallaController.text.trim(),
        'homeGaliNo': _homeGaliNoController.text.trim(),
        'homePostOffice': _homePostOfficeController.text.trim(),
        'homePoliceStation': _homePoliceStationController.text.trim(),
        'homeTehsil': _homeTehsilController.text.trim(),
        'homeVillageLocation': _homeVillageLocationController.text.trim(),
        'selfiePath': selfiePath ?? '',
      };

      final changed = <String, dynamic>{};
      candidate.forEach((key, value) {
        final next = (value ?? '').toString().trim();
        final current = (currentProfile[key] ?? '').toString().trim();
        if (next.toLowerCase() != current.toLowerCase()) {
          changed[key] = next;
        }
      });

      if (changed.isEmpty) {
        setState(() {
          _saving = false;
        });
        _showMessage('No changes detected. Update at least one field.');
        return false;
      }

      final existingPayload =
          _decodePendingPayload(widget.currentUser.pendingUpdatePayload);
      final securityOnly = _extractSecurityPayload(existingPayload);
      final mergedPayload = <String, dynamic>{...securityOnly, ...changed};

      updated = widget.currentUser.copyWith(
        pendingUpdatePayload: jsonEncode(mergedPayload),
        previousPublicProfileSnapshot: jsonEncode(currentProfile),
        lastUpdated: DateTime.now(),
      );
    }
    final saved = await widget.repository.saveMember(updated);

    if (!mounted) {
      return false;
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
      return false;
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
      return true;
    }

    _showMessage(widget.currentUser.isAdmin
        ? 'Profile updated successfully.'
        : 'Update request sent to admin for approval.');
    return true;
  }

  bool _isValidContactNumber(String value) {
    if (value.isEmpty) {
      return true;
    }
    return RegExp(r'^[0-9]{10}$').hasMatch(value);
  }

  bool _isAcceptableStationValue(String value) {
    final trimmed = value.trim();
    if (trimmed.length < 3) {
      return false;
    }
    return RegExp(r"^[A-Za-z0-9 .,'()/-]{3,}$").hasMatch(trimmed);
  }

  Map<String, dynamic> _decodePendingPayload(String? payload) {
    if (payload == null || payload.trim().isEmpty) {
      return <String, dynamic>{};
    }
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        return Map<String, dynamic>.from(decoded);
      }
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
      return <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  Map<String, dynamic> _extractSecurityPayload(Map<String, dynamic> payload) {
    final security = <String, dynamic>{};
    for (final key in _securityPayloadKeys) {
      if (payload.containsKey(key)) {
        security[key] = payload[key];
      }
    }
    return security;
  }

  static const Set<String> _securityPayloadKeys = <String>{
    'biometricEnabled',
    'biometricEnrolledAt',
    'trustedDeviceId',
    'trustedDeviceFingerprint',
    'trustedDeviceBoundAt',
  };

  Map<String, dynamic> _currentPublicProfileSnapshot(Member member) {
    return <String, dynamic>{
      'name': member.name,
      'homeState': member.homeState,
      'homeDistrict': member.homeDistrict,
      'postingState': member.postingState,
      'postingDistrict': member.postingDistrict,
      'postingLocation': member.postingLocation,
      'postRank': member.postRank,
      'batchYear': member.batchYear,
      'department': member.department,
      'officialName': member.officialName,
      'gender': member.gender,
      'maritalStatus': member.maritalStatus,
      'postingCategory': member.postingCategory,
      'postingWorkAs': member.postingWorkAs,
      'whatsappNumber': member.whatsappNumber,
      'callingContactNumber': member.callingContactNumber,
      'postingPlaceLocation': member.postingPlaceLocation,
      'homeVillageMohalla': member.homeVillageMohalla,
      'homeGaliNo': member.homeGaliNo,
      'homePostOffice': member.homePostOffice,
      'homePoliceStation': member.homePoliceStation,
      'homeTehsil': member.homeTehsil,
      'homeVillageLocation': member.homeVillageLocation,
    };
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

  Future<void> _registerOrUpdateFingerprint() async {
    setState(() {
      _updatingBiometric = true;
    });
    final result = await widget.authService.registerOrUpdateBiometric(widget.currentUser);
    if (!mounted) {
      return;
    }
    setState(() {
      _updatingBiometric = false;
    });

    if (!result.isSuccess || result.member == null) {
      _showMessage(result.error ?? 'Unable to update fingerprint preference.');
      return;
    }

    widget.onProfileUpdated?.call(result.member!);
    _showMessage('Fingerprint login updated successfully.');
  }

  Future<void> _openEmailVerificationSheet() async {
    _emailController.text = widget.currentUser.email ?? _emailController.text;
    _emailOtpController.clear();
    _emailOtpSent = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                10,
                16,
                MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Add and verify email',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email address',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _sendingEmailOtp
                              ? null
                              : () => _sendEmailOtpFromSheet(setSheetState),
                          icon: const Icon(Icons.mark_email_read_outlined),
                          label: Text(_sendingEmailOtp ? 'Sending...' : 'Send OTP'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _emailOtpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: const InputDecoration(
                      labelText: 'Enter OTP',
                      prefixIcon: Icon(Icons.password_outlined),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _verifyingEmailOtp
                          ? null
                          : () => _verifyEmailOtpAndSave(setSheetState),
                      icon: const Icon(Icons.verified_outlined),
                      label: Text(
                        _verifyingEmailOtp ? 'Verifying...' : 'Verify OTP and Save Email',
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _sendEmailOtpFromSheet(StateSetter setSheetState) async {
    final email = _emailController.text.trim();
    if (!_emailPattern.hasMatch(email)) {
      _showMessage('Enter a valid email address first.');
      return;
    }

    setSheetState(() {
      _sendingEmailOtp = true;
    });

    final result = await _emailOtpService.sendVerificationOtp(
      email,
      purpose: EmailOtpPurpose.profileUpdate,
      memberName: widget.currentUser.name,
    );

    if (!mounted) {
      return;
    }

    setSheetState(() {
      _sendingEmailOtp = false;
      _emailOtpSent = result.success;
    });

    if (!result.success) {
      _showMessage(result.error ?? 'Unable to send OTP.');
      return;
    }
    _showMessage('OTP sent to $email');
  }

  Future<void> _verifyEmailOtpAndSave(StateSetter setSheetState) async {
    final email = _emailController.text.trim();
    final otp = _emailOtpController.text.trim();
    if (!_emailPattern.hasMatch(email)) {
      _showMessage('Enter a valid email address.');
      return;
    }
    if (!_emailOtpSent) {
      _showMessage('Send OTP first.');
      return;
    }
    if (!RegExp(r'^[0-9]{6}$').hasMatch(otp)) {
      _showMessage('Enter valid 6 digit OTP.');
      return;
    }

    setSheetState(() {
      _verifyingEmailOtp = true;
    });

    final verified = await _emailOtpService.verifyOtp(email: email, otp: otp);
    if (!mounted) {
      return;
    }
    if (!verified) {
      setSheetState(() {
        _verifyingEmailOtp = false;
      });
      _showMessage('Invalid or expired OTP.');
      return;
    }

    final updated = widget.currentUser.copyWith(
      email: email,
      lastUpdated: DateTime.now(),
    );
    final saved = await widget.repository.saveMember(updated);
    if (!mounted) {
      return;
    }

    setSheetState(() {
      _verifyingEmailOtp = false;
    });

    if (!saved) {
      _showMessage('Unable to save email. Please retry.');
      return;
    }

    widget.onProfileUpdated?.call(updated);
    if (context.mounted) {
      Navigator.of(context).pop();
    }
    _showMessage('Email verified and added successfully.');
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

class _ProfileUpdateInfoScreen extends StatefulWidget {
  const _ProfileUpdateInfoScreen({
    required this.postingLocationController,
    required this.homeStateController,
    required this.homeDistrictController,
    required this.postingStateController,
    required this.postingDistrictController,
    required this.whatsappController,
    required this.callingContactController,
    required this.postingPlaceLocationController,
    required this.homeVillageMohallaController,
    required this.homeGaliNoController,
    required this.homePoliceStationController,
    required this.homeTehsilController,
    required this.homeVillageLocationController,
    required this.previousValues,
    required this.saving,
    required this.onSave,
  });

  final TextEditingController postingLocationController;
  final TextEditingController homeStateController;
  final TextEditingController homeDistrictController;
  final TextEditingController postingStateController;
  final TextEditingController postingDistrictController;
  final TextEditingController whatsappController;
  final TextEditingController callingContactController;
  final TextEditingController postingPlaceLocationController;
  final TextEditingController homeVillageMohallaController;
  final TextEditingController homeGaliNoController;
  final TextEditingController homePoliceStationController;
  final TextEditingController homeTehsilController;
  final TextEditingController homeVillageLocationController;
  final Map<String, String> previousValues;
  final bool saving;
  final Future<bool> Function() onSave;

  @override
  State<_ProfileUpdateInfoScreen> createState() => _ProfileUpdateInfoScreenState();
}

class _ProfileUpdateInfoScreenState extends State<_ProfileUpdateInfoScreen> {
  final LocationSuggestionService _locationSuggestions = LocationSuggestionService();
  List<String> _districtOptions = <String>[];
  List<String> _homeStationOptions = <String>[];
  List<String> _postingStationOptions = <String>[];
  bool _fetchingPostingLocation = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadDistrictOptions());
    unawaited(_loadHomeStationOptions());
    unawaited(_loadPostingStationOptions());
  }

  Future<void> _loadDistrictOptions() async {
    final districts = await _locationSuggestions.allDistricts();
    if (!mounted) {
      return;
    }
    setState(() {
      _districtOptions = districts;
    });
  }

  Future<void> _loadHomeStationOptions() async {
    final stations = await _locationSuggestions.allPoliceStations(
      district: widget.homeDistrictController.text.trim(),
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _homeStationOptions = stations;
    });
  }

  Future<void> _loadPostingStationOptions() async {
    final stations = await _locationSuggestions.allPoliceStations(
      district: widget.postingDistrictController.text.trim(),
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _postingStationOptions = stations;
    });
  }

  Future<void> _pickFromList({
    required String title,
    required List<String> options,
    required TextEditingController controller,
    ValueChanged<String>? onSelected,
    bool allowCustomValue = false,
  }) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final searchController = TextEditingController();
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
                height: MediaQuery.of(context).size.height * 0.7,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: searchController,
                      decoration: const InputDecoration(
                        labelText: 'Search',
                        suffixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) {
                        setSheetState(() {
                          query = value;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(child: Text('No matches found.'))
                          : ListView.builder(
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final item = filtered[index];
                                return ListTile(
                                  title: Text(item),
                                  onTap: () => Navigator.of(context).pop(item),
                                );
                              },
                            ),
                    ),
                    if (allowCustomValue)
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.tonal(
                          onPressed: () {
                            final typed = searchController.text.trim();
                            if (typed.isEmpty) {
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

    final selected = (result ?? '').trim();
    if (selected.isEmpty) {
      return;
    }

    setState(() {
      controller.text = selected;
    });
    onSelected?.call(selected);
  }

  Widget _buildSelectionField(
    TextEditingController controller,
    String label, {
    required VoidCallback onTap,
    String? hint,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AbsorbPointer(
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            suffixIcon: const Icon(Icons.arrow_drop_down_rounded),
          ),
        ),
      ),
    );
  }

  Future<void> _fetchCurrentPostingLocation() async {
    setState(() {
      _fetchingPostingLocation = true;
    });
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission is required.')),
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        widget.postingPlaceLocationController.text =
            '${position.latitude},${position.longitude}';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Current location fetched successfully.')),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to fetch current location.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _fetchingPostingLocation = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Update Information')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F0E3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFDCCFB3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Previously entered info',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  ...widget.previousValues.entries.map(
                    (entry) => _infoRow(entry.key, entry.value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Edit and submit updated details',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: widget.homeStateController,
              decoration: const InputDecoration(labelText: 'Home State'),
              readOnly: true,
            ),
            const SizedBox(height: 8),
            _buildSelectionField(
              widget.homeDistrictController,
              'Home District',
              hint: 'Tap to choose district',
              onTap: () => _pickFromList(
                title: 'Select Home District',
                options: _districtOptions,
                controller: widget.homeDistrictController,
                onSelected: (_) {
                  widget.homePoliceStationController.clear();
                  unawaited(_loadHomeStationOptions());
                },
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: widget.postingStateController,
              decoration: const InputDecoration(labelText: 'Posting State'),
              readOnly: true,
            ),
            const SizedBox(height: 8),
            _buildSelectionField(
              widget.postingDistrictController,
              'Posting District',
              hint: 'Tap to choose district',
              onTap: () => _pickFromList(
                title: 'Select Posting District',
                options: _districtOptions,
                controller: widget.postingDistrictController,
                onSelected: (_) => unawaited(_loadPostingStationOptions()),
              ),
            ),
            const SizedBox(height: 8),
            _buildSelectionField(
              widget.postingLocationController,
              'Posting Location',
              hint: 'Tap to choose station or use typed value',
              onTap: () => _pickFromList(
                title: 'Select Posting Location',
                options: _postingStationOptions,
                controller: widget.postingLocationController,
                allowCustomValue: true,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: widget.whatsappController,
              decoration: const InputDecoration(labelText: 'Whatsapp Number'),
              keyboardType: TextInputType.phone,
              inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
              maxLength: 10,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: widget.callingContactController,
              decoration: const InputDecoration(labelText: 'Calling Contact Number'),
              keyboardType: TextInputType.phone,
              inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
              maxLength: 10,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: widget.postingPlaceLocationController,
              decoration: const InputDecoration(labelText: 'Posting Place Location (GPS)'),
              readOnly: true,
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed: _fetchingPostingLocation ? null : _fetchCurrentPostingLocation,
                icon: const Icon(Icons.my_location_outlined),
                label: Text(
                  _fetchingPostingLocation
                      ? 'Fetching current location...'
                      : 'Fetch current location',
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: widget.homeVillageMohallaController,
              decoration: const InputDecoration(labelText: 'Home Village / Mohalla'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: widget.homeGaliNoController,
              decoration: const InputDecoration(labelText: 'Home Gali No'),
            ),
            const SizedBox(height: 8),
            _buildSelectionField(
              widget.homePoliceStationController,
              'Home Police Station',
              hint: 'Tap to choose station',
              onTap: () => _pickFromList(
                title: 'Select Home Police Station',
                options: _homeStationOptions,
                controller: widget.homePoliceStationController,
                allowCustomValue: true,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: widget.homeTehsilController,
              decoration: const InputDecoration(labelText: 'Home Tehsil'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: widget.homeVillageLocationController,
              decoration: const InputDecoration(labelText: 'Home Village Location'),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: widget.saving
                  ? null
                  : () async {
                      final success = await widget.onSave();
                      if (success && context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
              icon: const Icon(Icons.save_outlined),
              label: Text(widget.saving ? 'Saving...' : 'Submit Update Request'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF5A6B74),
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(
              value.isEmpty ? '-' : value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
