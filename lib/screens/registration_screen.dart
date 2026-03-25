import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:local_auth/local_auth.dart';

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
  static const Color _ink = Color(0xFF1E2A36);
  static const Color _accent = Color(0xFFB08A53);
  static const Color _panel = Color(0xFFFCFAF5);
  static const Color _border = Color(0xFFE1D8C8);

  static const List<String> _steps = <String>[
    'Identity',
    'Details',
    'Documents',
    'Review',
  ];

  final PageController _pageController = PageController();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _mpinController = TextEditingController();
  final _referenceController = TextEditingController();
  final _departmentController = TextEditingController();
  final _postRankController = TextEditingController();
  final _customRankController = TextEditingController();
  final _genderController = TextEditingController();
  final _maritalStatusController = TextEditingController();
  final _postingCategoryController = TextEditingController();
  final _postingWorkAsController = TextEditingController();
  final _homeStateController = TextEditingController(text: 'Uttar Pradesh');
  final _postingStateController = TextEditingController(text: 'Uttar Pradesh');
  final _officialNameController = TextEditingController();
  final _batchYearController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _callingNumberController = TextEditingController();
  final _postingPlaceLocationController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  final _homeDistrictController = TextEditingController();
  final _postingDistrictController = TextEditingController();
  final _postingLocationController = TextEditingController();
  final _homeVillageMohallaController = TextEditingController();
  final _homeGaliNoController = TextEditingController();
  final _homePostOfficeController = TextEditingController();
  final _homePoliceStationController = TextEditingController();
  final _homeTehsilController = TextEditingController();
  final _homeVillageLocationController = TextEditingController();
  XFile? _selfie;
  XFile? _idCardPhoto;
  Member? _referenceMember;
  int _currentStep = 0;
  bool _submitting = false;
  final LocationSuggestionService _locationSuggestions =
      LocationSuggestionService();
  List<String> _allDistrictOptions = <String>[];
  List<String> _allHomeStationOptions = <String>[];
  List<String> _allPostingStationOptions = <String>[];
  final LocalAuthentication _localAuthentication = LocalAuthentication();
  bool _biometricSupported = false;
  bool _biometricVerified = false;
  bool _checkingBiometric = false;
  bool _capturingPostingLocation = false;
  bool _willUploadPostingLocationLater = false;

  static const List<String> _subDepartments = <String>[
    'Civil Police',
    'P.A.C',
    'Fire Service',
    'Jail Warden',
    'Armed Police',
    'UPSSF',
    'GRP',
    'Dial 112',
    'LIU',
    'Radio Department',
    'Others',
  ];

  static const List<String> _rankOptions = <String>[
    'Constable',
    'HC',
    'Computer Operator',
    'ASI',
    'SI',
    'Inspector',
    'Other',
  ];

  static const List<String> _genderOptions = <String>[
    'Male',
    'Female',
    'Other',
  ];

  static const List<String> _maritalStatusOptions = <String>[
    'Single',
    'Married',
    'Divorced',
    'Widowed',
  ];

  static const List<String> _postingCategories = <String>[
    'Reserve Police Line',
    'Circle Police Office',
    'Police Station',
    'Fire Station',
    'District Police Office/Branch',
    'Other Police Office/Branch',
    'Battalion',
    'Range Police Office',
    'Zone Police Office',
    'Police Head Quarter Office',
    'District Jail',
  ];

  static const List<String> _postingWorkOptions = <String>[
    'Field Work',
    'Office Work',
    'Court Work',
    'N/A',
  ];

  static final RegExp _namePattern = RegExp(r"^[A-Za-z][A-Za-z .'-]{1,59}$");
  static final RegExp _mobilePattern = RegExp(r'^[0-9]{10}$');
  static final RegExp _yearPattern = RegExp(r'^[0-9]{4}$');

  @override
  void initState() {
    super.initState();
    _checkBiometricSupport();
    unawaited(_primeFormOptions());
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _mobileController.dispose();
    _mpinController.dispose();
    _referenceController.dispose();
    _departmentController.dispose();
    _postRankController.dispose();
    _customRankController.dispose();
    _genderController.dispose();
    _maritalStatusController.dispose();
    _postingCategoryController.dispose();
    _postingWorkAsController.dispose();
    _homeStateController.dispose();
    _postingStateController.dispose();
    _officialNameController.dispose();
    _batchYearController.dispose();
    _whatsappController.dispose();
    _callingNumberController.dispose();
    _postingPlaceLocationController.dispose();
    _emergencyContactController.dispose();
    _homeDistrictController.dispose();
    _postingDistrictController.dispose();
    _postingLocationController.dispose();
    _homeVillageMohallaController.dispose();
    _homeGaliNoController.dispose();
    _homePostOfficeController.dispose();
    _homePoliceStationController.dispose();
    _homeTehsilController.dispose();
    _homeVillageLocationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0xFFF3EEE2), Color(0xFFE8ECF1)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: <Widget>[
              _buildScreenHeader(keyboardOpen),
              Padding(
                padding: EdgeInsets.fromLTRB(20, keyboardOpen ? 8 : 10, 20, 0),
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

  Widget _buildScreenHeader(bool keyboardOpen) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      height: keyboardOpen ? 0 : 66,
      margin: EdgeInsets.fromLTRB(20, keyboardOpen ? 0 : 8, 20, 0),
      child: keyboardOpen
          ? const SizedBox.shrink()
          : Row(
              children: <Widget>[
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _ink,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.verified_user_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Member Registration',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: _ink,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Complete details carefully for quick approval',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF5B6470),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStepStrip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F5EB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Row(
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
                  height: 10,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: complete
                        ? _ink
                        : active
                            ? _accent
                            : const Color(0xFFD5D0C3),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _steps[index],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: active
                        ? _ink
                        : const Color(0xFF5A6B74),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
      ),
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
          const SizedBox(height: 4),
          _buildFingerprintOption(),
          TextFormField(
            controller: _referenceController,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: _fieldDecoration('Reference member mobile number'),
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
                color: const Color(0xFFF1E7D3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE0CEAA)),
              ),
              child: Row(
                children: <Widget>[
                  const CircleAvatar(
                    backgroundColor: _ink,
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
      title: 'Service, home and posting details',
      subtitle:
          'Fill details in chunks. Start with home details, then current posting.',
      child: Column(
        children: <Widget>[
          _buildChunkCard(
            title: '1) Home details',
            subtitle: 'For now state is fixed to Uttar Pradesh.',
            initiallyExpanded: true,
            children: <Widget>[
              _buildTextField(_homeStateController, 'Home State', readOnly: true),
              _buildSelectionField(
                _homeDistrictController,
                'Home District',
                hint: 'Tap to choose from district list',
                onTap: () => _pickFromList(
                  title: 'Select Home District',
                  options: _allDistrictOptions,
                  controller: _homeDistrictController,
                  onSelected: (_) {
                    unawaited(_loadHomeStationOptions());
                  },
                ),
              ),
              _buildTextField(_homeTehsilController, 'Home Tehsil'),
              _buildSelectionField(
                _homePoliceStationController,
                'Home Police Station',
                hint: 'Tap to choose station',
                onTap: () => _pickFromList(
                  title: 'Select Home Police Station',
                  options: _allHomeStationOptions,
                  controller: _homePoliceStationController,
                  allowCustomValue: true,
                ),
              ),
              _buildTextField(_homePostOfficeController, 'Home Post Office'),
              _buildTextField(_homeVillageMohallaController, 'Village / Mohalla'),
              _buildTextField(_homeGaliNoController, 'Gali No.'),
            ],
          ),
          const SizedBox(height: 8),
          _buildChunkCard(
            title: '2) Current posting details',
            subtitle:
                'Upload only police station (or near station) location for accurate member map.',
            children: <Widget>[
              _buildTextField(_postingStateController, 'Posting State', readOnly: true),
              _buildSelectionField(
                _postingDistrictController,
                'Posting District',
                hint: 'Tap to choose district',
                onTap: () => _pickFromList(
                  title: 'Select Posting District',
                  options: _allDistrictOptions,
                  controller: _postingDistrictController,
                  onSelected: (_) {
                    unawaited(_loadPostingStationOptions());
                  },
                ),
              ),
              _buildSelectionField(
                _postingLocationController,
                'Posting Police Station',
                hint: 'Tap to choose police station',
                onTap: () => _pickFromList(
                  title: 'Select Posting Police Station',
                  options: _allPostingStationOptions,
                  controller: _postingLocationController,
                  allowCustomValue: true,
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Please upload location of your police station or very near to it.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF5A6B74)),
                  ),
                ),
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('I am away from station now, I will upload location later'),
                subtitle: const Text(
                  'You can submit registration now and update posting location later from profile.',
                ),
                value: _willUploadPostingLocationLater,
                onChanged: (value) {
                  setState(() {
                    _willUploadPostingLocationLater = value;
                    if (value) {
                      _postingPlaceLocationController.clear();
                    }
                  });
                },
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _willUploadPostingLocationLater
                      ? null
                      : _capturingPostingLocation
                          ? null
                          : _capturePostingLocation,
                  icon: const Icon(Icons.my_location_outlined),
                  label: Text(
                    _capturingPostingLocation
                        ? 'Capturing location...'
                        : 'Use current GPS as posting location',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildChunkCard(
            title: '3) Service profile details',
            subtitle: 'These details will be used in member cards and filters.',
            children: <Widget>[
              _buildDropdownField(
                _departmentController,
                'Sub Department',
                _subDepartments,
              ),
              _buildDropdownField(_postRankController, 'Rank', _rankOptions),
              if (_postRankController.text == 'Other')
                _buildTextField(_customRankController, 'Enter rank name'),
              _buildTextField(_officialNameController, 'Official Name'),
              _buildDropdownField(_batchYearController, 'Batch Year', _batchYears()),
              _buildDropdownField(_genderController, 'Gender', _genderOptions),
              _buildDropdownField(
                _maritalStatusController,
                'Marital Status',
                _maritalStatusOptions,
              ),
              _buildDropdownField(
                _postingCategoryController,
                'Posting Category',
                _postingCategories,
              ),
              _buildDropdownField(
                _postingWorkAsController,
                'Posting Work As',
                _postingWorkOptions,
              ),
              _buildTextField(
                _whatsappController,
                'Whatsapp Number',
                keyboardType: TextInputType.phone,
                maxLength: 10,
                digitsOnly: true,
              ),
              _buildTextField(
                _callingNumberController,
                'Calling Contact No.',
                keyboardType: TextInputType.phone,
                maxLength: 10,
                digitsOnly: true,
              ),
              _buildTextField(
                _emergencyContactController,
                'Emergency Contact',
                keyboardType: TextInputType.phone,
                maxLength: 10,
                digitsOnly: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsStep() {
    return _buildStepPage(
      title: 'Documents and selfie',
      subtitle:
          'Selfie is required. ID card upload is optional but recommended.',
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
            subtitle: 'Optional: upload member identification card image.',
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
            'Fingerprint setup',
            _biometricVerified ? 'Verified on this device' : 'Not verified',
          ),
          _buildSummaryRow(
            'Reference',
            _referenceMember?.name ?? _referenceController.text.trim(),
          ),
            _buildSummaryRow('Home State', _homeStateController.text.trim()),
            _buildSummaryRow('Home District', _homeDistrictController.text.trim()),
            _buildSummaryRow('Home Tehsil', _homeTehsilController.text.trim()),
            _buildSummaryRow(
              'Home Police Station', _homePoliceStationController.text.trim()),
            _buildSummaryRow('Post Office', _homePostOfficeController.text.trim()),
            _buildSummaryRow(
              'Village / Mohalla', _homeVillageMohallaController.text.trim()),
            _buildSummaryRow('Gali No.', _homeGaliNoController.text.trim()),
            _buildSummaryRow('Posting State', _postingStateController.text.trim()),
            _buildSummaryRow(
              'Posting District', _postingDistrictController.text.trim()),
            _buildSummaryRow(
              'Posting Police Station', _postingLocationController.text.trim()),
            _buildSummaryRow('Sub Department', _departmentController.text.trim()),
            _buildSummaryRow(
            'Rank',
            _postRankController.text.trim() == 'Other'
              ? _customRankController.text.trim()
              : _postRankController.text.trim(),
            ),
            _buildSummaryRow('Official Name', _officialNameController.text.trim()),
            _buildSummaryRow('Batch Year', _batchYearController.text.trim()),
            _buildSummaryRow('Gender', _genderController.text.trim()),
            _buildSummaryRow('Marital Status', _maritalStatusController.text.trim()),
            _buildSummaryRow(
              'Posting Category', _postingCategoryController.text.trim()),
            _buildSummaryRow('Posting Work As', _postingWorkAsController.text.trim()),
            _buildSummaryRow('Whatsapp', _whatsappController.text.trim()),
            _buildSummaryRow('Calling Contact', _callingNumberController.text.trim()),
            _buildSummaryRow('Emergency Contact', _emergencyContactController.text.trim()),
            _buildSummaryRow(
              'Posting location upload plan',
              _willUploadPostingLocationLater
                  ? 'Will upload later (away from station now)'
                  : 'Uploaded now',
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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.fromLTRB(20, 14, 20, bottomInset + 110),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        decoration: BoxDecoration(
          color: _panel,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _border),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x18000000),
              blurRadius: 14,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: _ink,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(color: Color(0xFF5A6B74), height: 1.4),
            ),
            const SizedBox(height: 14),
            const Divider(
              height: 1,
              thickness: 1,
              color: _border,
            ),
            const SizedBox(height: 18),
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
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
          color: Colors.white,
        ),
        child: Row(
          children: <Widget>[
            CircleAvatar(
              backgroundColor: _ink,
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
                Text(label, style: const TextStyle(color: Color(0xFF5A6B74), fontWeight: FontWeight.w600)),
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

  Widget _buildBottomBar() {
    final safeBottom = MediaQuery.of(context).viewPadding.bottom;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: safeBottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
        decoration: const BoxDecoration(
          color: Color(0xFFFFFCF6),
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
          border: Border(top: BorderSide(color: _border)),
        ),
        child: Row(
          children: <Widget>[
            if (_currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _ink,
                    side: const BorderSide(color: _border),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: _submitting ? null : _previousStep,
                  child: const Text('Back'),
                ),
              ),
            if (_currentStep > 0) const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _ink,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: _submitting ? null : _handlePrimaryAction,
                child: Text(_currentStep == _steps.length - 1
                    ? (_submitting ? 'Registering...' : 'Submit registration')
                    : 'Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFingerprintOption() {
    if (!_biometricSupported) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F4EB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border),
        ),
        child: const Row(
          children: <Widget>[
            Icon(Icons.fingerprint_outlined, color: Color(0xFF5A6B74)),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Fingerprint option is not available on this device.',
                style: TextStyle(color: Color(0xFF5A6B74)),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _biometricVerified ? const Color(0xFFE8F5ED) : const Color(0xFFF4EBD8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _biometricVerified ? const Color(0xFF9CCDB0) : const Color(0xFFE0D0AE),
        ),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            _biometricVerified ? Icons.verified_outlined : Icons.fingerprint,
            color: _ink,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _biometricVerified
                  ? 'Fingerprint verified. You can use biometric login after registration.'
                  : 'Optional: verify fingerprint while setting your M-PIN.',
              style: const TextStyle(color: _ink),
            ),
          ),
          const SizedBox(width: 10),
          TextButton(
            onPressed: _checkingBiometric ? null : _verifyFingerprint,
            child: Text(_checkingBiometric ? 'Checking...' : (_biometricVerified ? 'Re-check' : 'Verify')),
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
    bool readOnly = false,
    ValueChanged<String>? onChanged,
    VoidCallback? onTap,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      textInputAction: TextInputAction.next,
      maxLength: maxLength,
      inputFormatters: digitsOnly
          ? <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly]
          : null,
      onChanged: onChanged,
      onTap: onTap,
      decoration: _fieldDecoration(label),
    );
  }

  Widget _buildChunkCard({
    required String title,
    required String subtitle,
    required List<Widget> children,
    bool initiallyExpanded = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        initiallyExpanded: initiallyExpanded,
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700, color: _ink),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: Color(0xFF5A6B74)),
        ),
        children: children,
      ),
    );
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
        child: TextFormField(
          controller: controller,
          decoration: _fieldDecoration(label).copyWith(
            hintText: hint,
            suffixIcon: const Icon(Icons.arrow_drop_down_rounded),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField(
    TextEditingController controller,
    String label,
    List<String> options,
  ) {
    final current = controller.text.trim();
    final selected = options.contains(current) ? current : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DropdownButtonFormField<String>(
        key: ValueKey<String>('${label}_${controller.text}'),
        initialValue: selected,
        isExpanded: true,
        items: options
            .map(
              (item) => DropdownMenuItem<String>(
                value: item,
                child: Text(item),
              ),
            )
            .toList(),
        onChanged: (value) {
          setState(() {
            controller.text = value ?? '';
            if (label == 'Rank' && controller.text != 'Other') {
              _customRankController.clear();
            }
          });
        },
        decoration: _fieldDecoration(label),
      ),
    );
  }

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      floatingLabelStyle: const TextStyle(color: _ink, fontWeight: FontWeight.w600),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _accent, width: 1.2),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _border),
      ),
      counterText: '',
    );
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

  Future<void> _checkBiometricSupport() async {
    try {
      final canCheck = await _localAuthentication.canCheckBiometrics;
      final isSupported = await _localAuthentication.isDeviceSupported();
      final available = await _localAuthentication.getAvailableBiometrics();
      if (!mounted) {
        return;
      }
      setState(() {
        _biometricSupported = (canCheck || isSupported) && available.isNotEmpty;
      });
    } on PlatformException {
      if (!mounted) {
        return;
      }
      setState(() {
        _biometricSupported = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _biometricSupported = false;
      });
    }
  }

  Future<void> _verifyFingerprint() async {
    if (!_biometricSupported) {
      _showMessage('Fingerprint is not available on this device.');
      return;
    }

    setState(() {
      _checkingBiometric = true;
    });

    try {
      final authenticated = await _localAuthentication.authenticate(
        localizedReason: 'Verify fingerprint for quick login after registration',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _biometricVerified = authenticated;
      });
      _showMessage(
        authenticated
            ? 'Fingerprint verified successfully.'
            : 'Fingerprint verification was cancelled.',
      );
    } on PlatformException {
      if (!mounted) {
        return;
      }
      _showMessage('Fingerprint verification is unavailable on this device.');
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showMessage('Unable to verify fingerprint right now.');
    } finally {
      if (mounted) {
        setState(() {
          _checkingBiometric = false;
        });
      }
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
    if (!_namePattern.hasMatch(name)) {
      _showMessage('Enter a valid full name (letters and spaces only).');
      return false;
    }
    if (!_mobilePattern.hasMatch(mobile) || !_mobilePattern.hasMatch(reference)) {
      _showMessage('Mobile numbers must be 10 digits.');
      return false;
    }
    if (mpin.length != 6 || !RegExp(r'^[0-9]{6}$').hasMatch(mpin)) {
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

    final department = _departmentController.text.trim();
    final postRank = _postRankController.text.trim();
    final customRank = _customRankController.text.trim();
    final officialName = _officialNameController.text.trim();
    final batchYear = _batchYearController.text.trim();
    final gender = _genderController.text.trim();
    final maritalStatus = _maritalStatusController.text.trim();
    final postingCategory = _postingCategoryController.text.trim();
    final postingWorkAs = _postingWorkAsController.text.trim();
    final whatsapp = _whatsappController.text.trim();
    final callingContact = _callingNumberController.text.trim();
    final emergencyContact = _emergencyContactController.text.trim();
    final homeVillageMohalla = _homeVillageMohallaController.text.trim();
    final homeGaliNo = _homeGaliNoController.text.trim();
    final homePostOffice = _homePostOfficeController.text.trim();
    final homePoliceStation = _homePoliceStationController.text.trim();
    final homeTehsil = _homeTehsilController.text.trim();

    if (department.isEmpty ||
        postRank.isEmpty ||
        officialName.isEmpty ||
        batchYear.isEmpty ||
        gender.isEmpty ||
        maritalStatus.isEmpty ||
        postingCategory.isEmpty ||
        postingWorkAs.isEmpty ||
        whatsapp.isEmpty ||
        callingContact.isEmpty ||
        emergencyContact.isEmpty) {
      _showMessage('Complete all posting details.');
      return false;
    }

    if (postRank == 'Other' && customRank.isEmpty) {
      _showMessage('Please enter rank when you select Other.');
      return false;
    }

    if (!_namePattern.hasMatch(officialName)) {
      _showMessage('Enter a valid official name.');
      return false;
    }

    final currentYear = DateTime.now().year;
    final batch = int.tryParse(batchYear);
    if (!_yearPattern.hasMatch(batchYear) ||
        batch == null ||
        batch < 1970 ||
        batch > currentYear) {
      _showMessage('Enter a valid batch year.');
      return false;
    }

    if (!_mobilePattern.hasMatch(whatsapp) ||
        !_mobilePattern.hasMatch(callingContact) ||
        !_mobilePattern.hasMatch(emergencyContact)) {
      _showMessage('Complete all posting details with valid phone numbers.');
      return false;
    }

    if (homeVillageMohalla.isEmpty ||
        homeGaliNo.isEmpty ||
        homePostOffice.isEmpty ||
        homePoliceStation.isEmpty ||
        homeTehsil.isEmpty) {
      _showMessage('Complete all home district details.');
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

    return true;
  }

  bool _validateDocumentsStep() {
    if (_selfie == null) {
      _showMessage('Upload selfie to continue.');
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

    final selfieBytes = await _selfie!.readAsBytes();
    final mediaService = widget.repository.cloudService;
    final now = DateTime.now();
    final baseName = now.microsecondsSinceEpoch;
    final selfieUrl = await mediaService.uploadImageBytes(
      bytes: selfieBytes,
      folder: 'member-docs',
      fileName: 'selfie_$baseName.jpg',
    );
    String? idCardUrl;
    if (_idCardPhoto != null) {
      final idCardBytes = await _idCardPhoto!.readAsBytes();
      idCardUrl = await mediaService.uploadImageBytes(
        bytes: idCardBytes,
        folder: 'member-docs',
        fileName: 'id_card_$baseName.jpg',
      );
    }

    if (selfieUrl == null || (_idCardPhoto != null && idCardUrl == null)) {
      if (!mounted) {
        return;
      }
      setState(() {
        _submitting = false;
      });
      final uploadError = mediaService.lastUploadError;
      final message = (uploadError == null || uploadError.isEmpty)
          ? 'Unable to upload documents to cloud. Please retry.'
          : 'Unable to upload documents to cloud: $uploadError';
      _showMessage(message);
      return;
    }

    final mobile = _mobileController.text.trim();
    final effectiveRank = _postRankController.text.trim() == 'Other'
      ? _customRankController.text.trim()
      : _postRankController.text.trim();
    final member = Member(
      id: now.microsecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      mobileNumber: mobile,
      userId: 'u_$mobile',
      passwordHash: widget.authService.hashPassword(mobile),
      mpin: _mpinController.text.trim(),
      referenceMobileNumber: _referenceController.text.trim(),
      referenceMemberName: _referenceMember?.name,
      selfiePath: selfieUrl,
      idCardPhotoPath: idCardUrl,
      homeDistrict: _homeDistrictController.text.trim(),
      homeState: _homeStateController.text.trim(),
      postingDistrict: _postingDistrictController.text.trim(),
      postingState: _postingStateController.text.trim(),
      postingLocation: _postingLocationController.text.trim(),
      department: _departmentController.text.trim(),
      postRank: effectiveRank,
      officialName: _officialNameController.text.trim(),
      batchYear: _batchYearController.text.trim(),
      gender: _genderController.text.trim(),
      maritalStatus: _maritalStatusController.text.trim(),
      postingCategory: _postingCategoryController.text.trim(),
      postingWorkAs: _postingWorkAsController.text.trim(),
      whatsappNumber: _whatsappController.text.trim(),
      callingContactNumber: _callingNumberController.text.trim(),
      postingPlaceLocation: _postingPlaceLocationController.text.trim(),
      emergencyContact: _emergencyContactController.text.trim(),
      homeVillageMohalla: _homeVillageMohallaController.text.trim(),
      homeGaliNo: _homeGaliNoController.text.trim(),
      homePostOffice: _homePostOfficeController.text.trim(),
      homePoliceStation: _homePoliceStationController.text.trim(),
      homeTehsil: _homeTehsilController.text.trim(),
      homeVillageLocation: _homeVillageLocationController.text.trim(),
      appointmentDate: now,
      role: 'Member',
      lastUpdated: now,
      passwordUpdatedAt: now,
      isApproved: false,
    );
    final saved = await widget.repository.saveMember(member);

    if (!saved) {
      if (!mounted) {
        return;
      }
      setState(() {
        _submitting = false;
      });
      final cloudError = mediaService.lastWriteError;
      final message = (cloudError == null || cloudError.isEmpty)
          ? 'Unable to create registration in cloud. Please retry.'
          : 'Unable to create registration in cloud: $cloudError';
      _showMessage(message);
      return;
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _submitting = false;
    });
    Navigator.of(context).pop(member);
  }

  Future<void> _primeFormOptions() async {
    final districts = await _locationSuggestions.allDistricts();
    if (!mounted) {
      return;
    }
    setState(() {
      _allDistrictOptions = districts;
    });
    await _loadHomeStationOptions();
    await _loadPostingStationOptions();
  }

  Future<void> _loadHomeStationOptions() async {
    final stations = await _locationSuggestions.allPoliceStations(
      district: _homeDistrictController.text,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _allHomeStationOptions = stations;
    });
  }

  Future<void> _loadPostingStationOptions() async {
    final stations = await _locationSuggestions.allPoliceStations(
      district: _postingDistrictController.text,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _allPostingStationOptions = stations;
    });
  }

  List<String> _batchYears() {
    final currentYear = DateTime.now().year;
    return List<String>.generate(
      currentYear - 1969,
      (index) => (currentYear - index).toString(),
    );
  }

  Future<void> _pickFromList({
    required String title,
    required List<String> options,
    required TextEditingController controller,
    bool allowCustomValue = false,
    ValueChanged<String>? onSelected,
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
                    .where(
                      (item) => item.toLowerCase().contains(query.toLowerCase()),
                    )
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
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: searchController,
                      decoration: _fieldDecoration('Search').copyWith(
                        suffixIcon: const Icon(Icons.search),
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
                          ? Center(
                              child: Text(
                                allowCustomValue
                                    ? 'No matches. You can type and save a custom value.'
                                    : 'No matches found.',
                              ),
                            )
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
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.tonal(
                          onPressed: () => Navigator.of(context)
                              .pop(searchController.text.trim()),
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

  Future<void> _capturePostingLocation() async {
    setState(() {
      _capturingPostingLocation = true;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showMessage('Location service is disabled on this device.');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showMessage('Allow location permission to capture posting location.');
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final link =
          'https://www.google.com/maps/search/?api=1&query=${position.latitude},${position.longitude}';
      setState(() {
        _postingPlaceLocationController.text = link;
      });
      _showMessage('Posting location captured.');
    } catch (_) {
      _showMessage('Unable to capture location. You can paste map link manually.');
    } finally {
      if (mounted) {
        setState(() {
          _capturingPostingLocation = false;
        });
      }
    }
  }

}
