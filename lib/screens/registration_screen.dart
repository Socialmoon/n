import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../models/member.dart';
import '../services/auth_service.dart';
import '../services/location_suggestion_service.dart';
import '../services/member_repository.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({
    required this.repository,
    required this.authService,
    super.key,
  });

  final MemberRepository repository;
  final AuthService authService;

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  static const List<String> _steps = <String>[
    'Identity',
    'Posting',
    'Documents',
    'Review',
  ];

  final PageController _pageController = PageController();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _mpinController = TextEditingController();
  final _referenceController = TextEditingController();
  final _homeDistrictController = TextEditingController();
  final _postingDistrictController = TextEditingController();
  final _postingLocationController = TextEditingController();
  DateTime? _appointmentDate;
  XFile? _selfie;
  XFile? _idCardPhoto;
  Member? _referenceMember;
  int _currentStep = 0;
  bool _submitting = false;
  final LocationSuggestionService _locationSuggestions =
      LocationSuggestionService();
  List<String> _homeDistrictSuggestions = <String>[];
  List<String> _postingDistrictSuggestions = <String>[];
  List<String> _postingStationSuggestions = <String>[];
  Timer? _homeDistrictDebounce;
  Timer? _postingDistrictDebounce;
  Timer? _postingStationDebounce;
  int _homeDistrictRequest = 0;
  int _postingDistrictRequest = 0;
  int _postingStationRequest = 0;

  @override
  void dispose() {
    _homeDistrictDebounce?.cancel();
    _postingDistrictDebounce?.cancel();
    _postingStationDebounce?.cancel();
    _pageController.dispose();
    _nameController.dispose();
    _mobileController.dispose();
    _mpinController.dispose();
    _referenceController.dispose();
    _homeDistrictController.dispose();
    _postingDistrictController.dispose();
    _postingLocationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0xFFEEF4F7), Color(0xFFF7F1E7)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: <Widget>[
              _buildHeroHeader(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildStepStrip(),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: <Widget>[
                    _buildIdentityStep(),
                    _buildPostingStep(),
                    _buildDocumentsStep(),
                    _buildReviewStep(),
                  ],
                ),
              ),
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroHeader() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: <Color>[
            Color(0xFF123C56),
            Color(0xFF2B6E78),
            Color(0xFFE0B36A)
          ],
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(
              color: Color(0x22000000), blurRadius: 24, offset: Offset(0, 10)),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'New Member Registration',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Complete the registration in guided phases with posting details and document capture.',
            style: TextStyle(color: Colors.white70, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildStepStrip() {
    return Row(
      children: List<Widget>.generate(_steps.length, (int index) {
        final active = index == _currentStep;
        final complete = index < _currentStep;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index == _steps.length - 1 ? 0 : 8),
            child: Column(
              children: <Widget>[
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  height: 12,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: complete
                        ? const Color(0xFF2B6E78)
                        : active
                            ? const Color(0xFFE0B36A)
                            : const Color(0xFFD7E0E5),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _steps[index],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: active
                        ? const Color(0xFF123C56)
                        : const Color(0xFF5A6B74),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildIdentityStep() {
    return _buildStepPage(
      title: 'Identity and referral',
      subtitle: 'Enter the member identity and confirm the referring member.',
      child: Column(
        children: <Widget>[
          _buildTextField(_nameController, 'Full name'),
          _buildTextField(
            _mobileController,
            'Mobile number',
            keyboardType: TextInputType.phone,
            maxLength: 10,
            digitsOnly: true,
          ),
          _buildTextField(
            _mpinController,
            'Create 6 digit M-PIN',
            keyboardType: TextInputType.number,
            maxLength: 6,
            digitsOnly: true,
          ),
          TextFormField(
            controller: _referenceController,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: const InputDecoration(
              labelText: 'Reference member mobile number',
            ),
            onChanged: (value) {
              setState(() {
                _referenceMember = widget.repository.findByMobile(value.trim());
              });
            },
          ),
          if (_referenceMember != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 6),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF4EBD8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: <Widget>[
                  const CircleAvatar(
                    backgroundColor: Color(0xFF123C56),
                    foregroundColor: Colors.white,
                    child: Icon(Icons.verified_user_outlined),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          _referenceMember!.name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          '${_referenceMember!.role} • ${_referenceMember!.postingLocation}',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPostingStep() {
    return _buildStepPage(
      title: 'Posting details',
      subtitle:
          'Capture the service information that will appear in the directory.',
      child: Column(
        children: <Widget>[
          _buildTextField(
            _homeDistrictController,
            'Home district',
            onChanged: _onHomeDistrictChanged,
            onTap: () => _loadHomeDistrictSuggestions(_homeDistrictController.text),
          ),
          _buildSuggestionChips(
            suggestions: _homeDistrictSuggestions,
            onSelected: (district) {
              setState(() {
                _homeDistrictController.text = district;
                _homeDistrictSuggestions = <String>[];
              });
            },
          ),
          _buildTextField(
            _postingDistrictController,
            'Posting district',
            onChanged: _onPostingDistrictChanged,
            onTap: () => _loadPostingDistrictSuggestions(_postingDistrictController.text),
          ),
          _buildSuggestionChips(
            suggestions: _postingDistrictSuggestions,
            onSelected: (district) {
              setState(() {
                _postingDistrictController.text = district;
                _postingDistrictSuggestions = <String>[];
              });
              _onPostingLocationChanged(_postingLocationController.text);
            },
          ),
          _buildTextField(
            _postingLocationController,
            'Posting location / Police station',
            onChanged: _onPostingLocationChanged,
            onTap: () => _loadPostingStationSuggestions(_postingLocationController.text),
          ),
          _buildSuggestionChips(
            suggestions: _postingStationSuggestions,
            onSelected: (station) {
              setState(() {
                _postingLocationController.text = station;
                _postingStationSuggestions = <String>[];
              });
            },
          ),
          OutlinedButton.icon(
            onPressed: _pickAppointmentDate,
            icon: const Icon(Icons.event_outlined),
            label: Text(
              _appointmentDate == null
                  ? 'Select appointment date'
                  : 'Appointment: ${_appointmentDate!.day}/${_appointmentDate!.month}/${_appointmentDate!.year}',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsStep() {
    return _buildStepPage(
      title: 'Documents and selfie',
      subtitle:
          'Capture the required ID proof and selfie for the member profile.',
      child: Column(
        children: <Widget>[
          _buildUploadTile(
            title: 'Selfie photo',
            subtitle: 'Use camera capture for live verification.',
            icon: Icons.camera_alt_outlined,
            onTap: _pickSelfie,
          ),
          if (_selfie != null) _buildImagePreview(_selfie!),
          const SizedBox(height: 12),
          _buildUploadTile(
            title: 'ID card photo',
            subtitle: 'Upload the member identification card image.',
            icon: Icons.badge_outlined,
            onTap: _pickIdCardPhoto,
          ),
          if (_idCardPhoto != null) _buildImagePreview(_idCardPhoto!),
        ],
      ),
    );
  }

  Widget _buildReviewStep() {
    return _buildStepPage(
      title: 'Review and submit',
      subtitle:
          'Check the registration summary before creating the member profile.',
      child: Column(
        children: <Widget>[
          _buildSummaryRow('Full name', _nameController.text.trim()),
          _buildSummaryRow('Mobile', _mobileController.text.trim()),
          _buildSummaryRow(
            'Reference',
            _referenceMember?.name ?? _referenceController.text.trim(),
          ),
          _buildSummaryRow(
              'Home district', _homeDistrictController.text.trim()),
          _buildSummaryRow(
              'Posting district', _postingDistrictController.text.trim()),
          _buildSummaryRow(
              'Posting location', _postingLocationController.text.trim()),
          _buildSummaryRow(
            'Appointment date',
            _appointmentDate == null
                ? 'Not selected'
                : '${_appointmentDate!.day}/${_appointmentDate!.month}/${_appointmentDate!.year}',
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF4EBD8),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Registration remains pending until admin approval. Once approved, sign in with the M-PIN set above.',
              style: TextStyle(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepPage({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const <BoxShadow>[
            BoxShadow(
                color: Color(0x14000000),
                blurRadius: 20,
                offset: Offset(0, 10)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(subtitle,
                style: const TextStyle(color: Color(0xFF5A6B74), height: 1.4)),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildUploadTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFD5DEE3)),
          color: const Color(0xFFF9FBFC),
        ),
        child: Row(
          children: <Widget>[
            CircleAvatar(
              backgroundColor: const Color(0xFF123C56),
              foregroundColor: Colors.white,
              child: Icon(icon),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: const TextStyle(color: Color(0xFF5A6B74))),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview(XFile file) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: FutureBuilder<Uint8List>(
          future: file.readAsBytes(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Image.memory(
                snapshot.data!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              );
            }
            if (snapshot.hasError) {
              return Container(
                height: 180,
                width: double.infinity,
                color: const Color(0xFFF3F5F7),
                alignment: Alignment.center,
                child: const Text('Preview unavailable'),
              );
            }
            return const SizedBox(
              height: 180,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 120,
            child:
                Text(label, style: const TextStyle(color: Color(0xFF5A6B74))),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
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
      padding: const EdgeInsets.only(bottom: 8),
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

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Row(
        children: <Widget>[
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _submitting ? null : _previousStep,
                child: const Text('Back'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: _submitting ? null : _handlePrimaryAction,
              child: Text(_currentStep == _steps.length - 1
                  ? (_submitting ? 'Registering...' : 'Submit registration')
                  : 'Continue'),
            ),
          ),
        ],
      ),
    );
  }

  TextFormField _buildTextField(
    TextEditingController controller,
    String label, {
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    bool digitsOnly = false,
    ValueChanged<String>? onChanged,
    VoidCallback? onTap,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      inputFormatters: digitsOnly
          ? <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly]
          : null,
      onChanged: onChanged,
      onTap: onTap,
      decoration: InputDecoration(labelText: label),
    );
  }

  Future<void> _pickAppointmentDate() async {
    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime(1980),
      lastDate: DateTime.now(),
      initialDate: _appointmentDate ?? DateTime.now(),
    );
    if (selected != null) {
      setState(() {
        _appointmentDate = selected;
      });
    }
  }

  Future<void> _pickSelfie() async {
    final picker = ImagePicker();
    final file =
        await picker.pickImage(source: ImageSource.camera, imageQuality: 65);
    if (file != null) {
      setState(() {
        _selfie = file;
      });
    }
  }

  Future<void> _pickIdCardPhoto() async {
    final picker = ImagePicker();
    final file =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (file != null) {
      setState(() {
        _idCardPhoto = file;
      });
    }
  }

  Future<void> _handlePrimaryAction() async {
    if (_currentStep == 0) {
      if (!_validateIdentityStep()) {
        return;
      }
      // OTP flow disabled: proceed directly to posting details.
      await _goToStep(1);
      return;
    }

    if (_currentStep == 1) {
      if (!await _validatePostingStep()) {
        return;
      }
      await _goToStep(2);
      return;
    }

    if (_currentStep == 2) {
      if (!_validateDocumentsStep()) {
        return;
      }
      await _goToStep(3);
      return;
    }

    await _submit();
  }

  Future<void> _goToStep(int step) async {
    setState(() {
      _currentStep = step;
    });
    await _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _previousStep() async {
    if (_currentStep == 0) {
      return;
    }
    await _goToStep(_currentStep - 1);
  }

  bool _validateIdentityStep() {
    final name = _nameController.text.trim();
    final mobile = _mobileController.text.trim();
    final mpin = _mpinController.text.trim();
    final reference = _referenceController.text.trim();
    if (name.isEmpty || mobile.isEmpty || reference.isEmpty || mpin.isEmpty) {
      _showMessage(
          'Enter full name, mobile number, M-PIN and reference mobile number.');
      return false;
    }
    if (mobile.length != 10 || reference.length != 10) {
      _showMessage('Mobile numbers must be 10 digits.');
      return false;
    }
    if (mpin.length != 6) {
      _showMessage('M-PIN must be exactly 6 digits.');
      return false;
    }
    if (mobile == reference) {
      _showMessage('Reference mobile must be different from member mobile.');
      return false;
    }
    if (widget.repository.findByMobile(mobile) != null) {
      _showMessage('Mobile number already registered.');
      return false;
    }
    if (_referenceMember == null) {
      _showMessage('Reference member could not be verified.');
      return false;
    }
    return true;
  }

  Future<bool> _validatePostingStep() async {
    final homeDistrict = _homeDistrictController.text.trim();
    final postingDistrict = _postingDistrictController.text.trim();
    final postingStation = _postingLocationController.text.trim();

    if (_homeDistrictController.text.trim().isEmpty ||
        _postingDistrictController.text.trim().isEmpty ||
        _postingLocationController.text.trim().isEmpty) {
      _showMessage('Complete all posting details.');
      return false;
    }

    final homeDistrictValid =
        await _locationSuggestions.isKnownDistrict(homeDistrict);
    if (!homeDistrictValid) {
      _showMessage('Choose a valid UP home district from suggestions.');
      return false;
    }

    final postingDistrictValid =
        await _locationSuggestions.isKnownDistrict(postingDistrict);
    if (!postingDistrictValid) {
      _showMessage('Choose a valid UP posting district from suggestions.');
      return false;
    }

    final stationValid = await _locationSuggestions.isKnownStation(
      station: postingStation,
      district: postingDistrict,
    );
    if (!stationValid) {
      _showMessage('Choose a valid police station from suggestions.');
      return false;
    }

    if (_appointmentDate == null) {
      _showMessage('Select the appointment date.');
      return false;
    }
    return true;
  }

  bool _validateDocumentsStep() {
    if (_selfie == null) {
      _showMessage('Upload selfie to continue.');
      return false;
    }
    if (_idCardPhoto == null) {
      _showMessage('Upload ID card photo to continue.');
      return false;
    }
    return true;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submit() async {
    final postingValid = await _validatePostingStep();
    if (!_validateIdentityStep() || !postingValid || !_validateDocumentsStep()) {
      return;
    }

    setState(() {
      _submitting = true;
    });

    final now = DateTime.now();
    final mobile = _mobileController.text.trim();
    final member = Member(
      id: now.microsecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      mobileNumber: mobile,
      userId: 'u_$mobile',
      passwordHash: widget.authService.hashPassword(mobile),
      mpin: _mpinController.text.trim(),
      referenceMobileNumber: _referenceController.text.trim(),
      referenceMemberName: _referenceMember?.name,
      selfiePath: _selfie?.path,
      idCardPhotoPath: _idCardPhoto?.path,
      homeDistrict: _homeDistrictController.text.trim(),
      postingDistrict: _postingDistrictController.text.trim(),
      postingLocation: _postingLocationController.text.trim(),
      appointmentDate: _appointmentDate!,
      role: 'Member',
      lastUpdated: now,
      passwordUpdatedAt: now,
      isApproved: false,
    );
    await widget.repository.saveMember(member);

    if (!mounted) {
      return;
    }
    setState(() {
      _submitting = false;
    });
    Navigator.of(context).pop(member);
  }

  void _onHomeDistrictChanged(String value) {
    _homeDistrictDebounce?.cancel();
    _homeDistrictDebounce = Timer(const Duration(milliseconds: 350), () {
      _loadHomeDistrictSuggestions(value);
    });
  }

  void _onPostingDistrictChanged(String value) {
    _postingDistrictDebounce?.cancel();
    _postingDistrictDebounce = Timer(const Duration(milliseconds: 350), () {
      _loadPostingDistrictSuggestions(value);
    });
    _onPostingLocationChanged(_postingLocationController.text);
  }

  void _onPostingLocationChanged(String value) {
    _postingStationDebounce?.cancel();
    _postingStationDebounce = Timer(const Duration(milliseconds: 350), () {
      _loadPostingStationSuggestions(value);
    });
  }

  Future<void> _loadHomeDistrictSuggestions(String query) async {
    final request = ++_homeDistrictRequest;
    final suggestions = await _locationSuggestions.suggestDistricts(query);
    if (!mounted || request != _homeDistrictRequest) {
      return;
    }
    setState(() {
      _homeDistrictSuggestions = suggestions;
    });
  }

  Future<void> _loadPostingDistrictSuggestions(String query) async {
    final request = ++_postingDistrictRequest;
    final suggestions = await _locationSuggestions.suggestDistricts(query);
    if (!mounted || request != _postingDistrictRequest) {
      return;
    }
    setState(() {
      _postingDistrictSuggestions = suggestions;
    });
  }

  Future<void> _loadPostingStationSuggestions(String query) async {
    final request = ++_postingStationRequest;
    final suggestions = await _locationSuggestions.suggestPoliceStations(
      query: query,
      district: _postingDistrictController.text,
    );
    if (!mounted || request != _postingStationRequest) {
      return;
    }
    setState(() {
      _postingStationSuggestions = suggestions;
    });
  }
}
