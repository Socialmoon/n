// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:local_auth/local_auth.dart';

import '../models/member.dart';
import '../services/auth_service.dart';
import '../services/email_otp_service.dart';
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
    'Verify Email',
    'Home Details',
    'Posting Details',
    'Service Details',
    'Documents',
    'Review',
  ];

  final PageController _pageController = PageController();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _emailOtpController = TextEditingController();
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
  final _homeDistrictController = TextEditingController();
  final _postingDistrictController = TextEditingController();
  final _postingLocationController = TextEditingController();
  final _homeVillageMohallaController = TextEditingController();
  final _homeGaliNoController = TextEditingController();
  final _homePostOfficeController = TextEditingController();
  final _homePoliceStationController = TextEditingController();
  final _homeTehsilController = TextEditingController();
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
  final EmailOtpService _emailOtpService = EmailOtpService();
  bool _biometricSupported = false;
  bool _biometricVerified = false;
  bool _emailVerified = false;
  bool _emailOtpSent = false;
  bool _sendingEmailOtp = false;
  bool _verifyingEmailOtp = false;
  bool _showOtpSendButton = false;
  bool _checkingBiometric = false;
  bool _capturingPostingLocation = false;
  bool _uploadPostingGpsLater = false;
  bool _officialNameEditedByUser = false;
  Timer? _otpResendTimer;
  int _otpResendSeconds = 0;
  final Map<String, GlobalKey> _fieldKeys = <String, GlobalKey>{};
  final Set<String> _invalidFieldIds = <String>{};

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
    'Others',
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
    _emailController.dispose();
    _emailOtpController.dispose();
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
    _homeDistrictController.dispose();
    _postingDistrictController.dispose();
    _postingLocationController.dispose();
    _homeVillageMohallaController.dispose();
    _homeGaliNoController.dispose();
    _homePostOfficeController.dispose();
    _homePoliceStationController.dispose();
    _homeTehsilController.dispose();
    _otpResendTimer?.cancel();
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
          bottom: false,
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
                    _buildEmailVerificationStep(),
                    _buildHomeDetailsStep(),
                    _buildPostingDetailsStep(),
                    _buildServiceDetailsStep(),
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
    final progress = (_currentStep + 1) / _steps.length;
    return Column(
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: const Color(0xFFE0DDD5),
            valueColor: AlwaysStoppedAnimation<Color>(_ink),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Step ${_currentStep + 1} of ${_steps.length}: ${_steps[_currentStep]}',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF5A6B74),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildIdentityStep() {
    return _buildStepPage(
      title: 'Identity and referral',
      subtitle: 'Enter the member identity and confirm the referring member.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Identity Fields Section
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F5ED),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE8DCC8)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Personal Information',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  _nameController,
                  'Full name',
                  isRequired: true,
                  onChanged: _syncOfficialNameFromIdentity,
                ),
                _buildTextField(
                  _emailController,
                  'Email address',
                  isRequired: true,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (_) {
                    if (_emailVerified || _emailOtpSent || _emailOtpController.text.isNotEmpty) {
                      setState(() {
                        _emailVerified = false;
                        _emailOtpSent = false;
                        _showOtpSendButton = false;
                        _emailOtpController.clear();
                      });
                    }
                  },
                ),
                _buildTextField(
                  _mobileController,
                  'Mobile number',
                  isRequired: true,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  digitsOnly: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Security Section
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4F8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFDDE5ED)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Security',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  _mpinController,
                  'Create 6 digit M-PIN',
                  isRequired: true,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  digitsOnly: true,
                ),
                const SizedBox(height: 8),
                _buildFingerprintOption(),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Reference Member Section
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F5EE),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEDD9BC)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Referring Member',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _referenceController,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: _fieldDecoration(
                    'Reference member mobile number',
                    isRequired: true,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _referenceMember = widget.repository.findByMobile(value.trim());
                    });
                  },
                ),
                if (_referenceMember != null) ...<Widget>[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1E7D3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE0CEAA)),
                    ),
                    child: Row(
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: _ink,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.verified_user_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                _referenceMember!.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: _ink,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_referenceMember!.role} • ${_referenceMember!.postingLocation}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6B7580),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailVerificationStep() {
    final bool canResend = _otpResendSeconds == 0 && !_sendingEmailOtp;
    
    return _buildStepPage(
      title: 'Verify your email',
      subtitle: 'We will send a one-time passcode to your email address.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4F8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFDDE5ED)),
            ),
            child: Row(
              children: <Widget>[
                const Icon(Icons.email_outlined, color: _ink, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Email address',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7580),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _emailController.text.trim(),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _emailVerified
                  ? const Color(0xFFE8F5ED)
                  : (_sendingEmailOtp ? const Color(0xFFF5F3EE) : const Color(0xFFFDF4E3)),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _emailVerified
                    ? const Color(0xFF9CCDB0)
                    : (_sendingEmailOtp ? const Color(0xFFE8D5B5) : const Color(0xFFE0D0AE)),
              ),
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  _emailVerified ? Icons.verified : Icons.info_outlined,
                  color: _emailVerified ? const Color(0xFF2E7D32) : const Color(0xFF825A0F),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _emailVerified
                        ? '✓ Email verified successfully'
                        : (_sendingEmailOtp ? 'Sending OTP...' : 'OTP will be sent to your email'),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: _emailVerified ? const Color(0xFF2E7D32) : const Color(0xFF5A4A23),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _emailOtpController,
            keyboardType: TextInputType.number,
            maxLength: 6,
            enabled: _emailOtpSent && !_verifyingEmailOtp && !_emailVerified,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
            ],
            onChanged: (value) {
              final otp = value.trim();
              if (!_emailOtpSent || _emailVerified || _verifyingEmailOtp) {
                return;
              }
              if (otp.length == 6) {
                unawaited(_verifyRegistrationEmail());
              }
            },
            decoration: InputDecoration(
              labelText: 'Enter OTP',
              hintText: '000000',
              prefixIcon: const Icon(Icons.lock_outline),
              helperText: _emailOtpSent && !_emailVerified 
                  ? 'Check your email for the 6-digit code'
                  : null,
            ),
          ),
          if (_sendingEmailOtp || !_emailOtpSent) const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (!_emailVerified)
                  if (_showOtpSendButton || _emailOtpSent)
                  FilledButton.icon(
                    onPressed: canResend ? _sendRegistrationEmailOtp : null,
                    icon: _sendingEmailOtp
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.send_outlined),
                    label: Text(
                      _sendingEmailOtp
                          ? 'Sending OTP...'
                          : (_emailOtpSent && _otpResendSeconds > 0
                              ? 'Resend in ${_otpResendSeconds}s'
                              : (_emailOtpSent ? 'Resend OTP' : 'Send OTP')),
                    ),
                  ),
                if (_emailOtpSent && !_emailVerified && _verifyingEmailOtp)
                  const Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Verifying OTP...'),
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

  Widget _buildHomeDetailsStep() {
    return _buildStepPage(
      title: 'Home details',
      subtitle: 'Fill your home address and station details.',
      child: Column(
        children: <Widget>[
          _buildChunkCard(
            title: 'Home details',
            subtitle: 'You can type your own state, district and station if not listed.',
            initiallyExpanded: true,
            children: <Widget>[
              _buildTextField(_homeStateController, 'Home State'),
              _buildSelectionField(
                _homeDistrictController,
                'Home District',
                isRequired: true,
                hint: 'Tap to choose from district list',
                onTap: () => _pickFromList(
                  title: 'Select Home District',
                  options: _allDistrictOptions,
                  controller: _homeDistrictController,
                  allowCustomValue: true,
                  onSelected: (_) {
                    unawaited(_loadHomeStationOptions());
                  },
                ),
              ),
              _buildTextField(_homeTehsilController, 'Home Tehsil', isRequired: true),
              _buildSelectionField(
                _homePoliceStationController,
                'Home Police Station',
                isRequired: true,
                hint: 'Tap to choose station',
                onTap: () => _pickFromList(
                  title: 'Select Home Police Station',
                  options: _allHomeStationOptions,
                  controller: _homePoliceStationController,
                  allowCustomValue: true,
                ),
              ),
              _buildTextField(_homeVillageMohallaController, 'Village / Mohalla', isRequired: true),
              _buildTextField(_homeGaliNoController, 'Gali No.', isRequired: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPostingDetailsStep() {
    return _buildStepPage(
      title: 'Posting details',
      subtitle: 'Provide your current district and posting station details.',
      child: Column(
        children: <Widget>[
          _buildChunkCard(
            title: 'Current posting details',
            subtitle:
                'Upload only police station (or near station) location for accurate member map.',
            initiallyExpanded: true,
            children: <Widget>[
              _buildTextField(_postingStateController, 'Posting State', readOnly: true),
              _buildSelectionField(
                _postingDistrictController,
                'Posting District',
                isRequired: true,
                hint: 'Tap to choose district',
                onTap: () => _pickFromList(
                  title: 'Select Posting District',
                  options: _allDistrictOptions,
                  controller: _postingDistrictController,
                  allowCustomValue: true,
                  onSelected: (_) {
                    unawaited(_loadPostingStationOptions());
                  },
                ),
              ),
              _buildSelectionField(
                _postingLocationController,
                'Posting Police Station',
                isRequired: true,
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
              _buildTextField(
                _postingPlaceLocationController,
                'Posting Place Location (Auto-fetched GPS)',
                isRequired: !_uploadPostingGpsLater,
                readOnly: true,
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                value: _uploadPostingGpsLater,
                onChanged: (value) {
                  setState(() {
                    _uploadPostingGpsLater = value ?? false;
                  });
                },
                title: const Text('Upload posting GPS later'),
                subtitle: const Text(
                  'You can submit now and update posting place location from profile later.',
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _capturingPostingLocation ? null : _capturePostingLocation,
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
        ],
      ),
    );
  }

  Widget _buildServiceDetailsStep() {
    return _buildStepPage(
      title: 'Service details',
      subtitle: 'These details are used in member cards and filters.',
      child: Column(
        children: <Widget>[
          _buildChunkCard(
            title: 'Service profile details',
            subtitle: 'These details will be used in member cards and filters.',
            initiallyExpanded: true,
            children: <Widget>[
              _buildDropdownField(
                _departmentController,
                'Sub Department',
                _subDepartments,
                isRequired: true,
              ),
              _buildDropdownField(_postRankController, 'Rank', _rankOptions, isRequired: true),
              if (_postRankController.text == 'Other')
                _buildTextField(_customRankController, 'Enter rank name'),
              _buildTextField(
                _officialNameController,
                'Official Name',
                isRequired: true,
                onChanged: _markOfficialNameEdited,
              ),
              _buildDropdownField(_batchYearController, 'Batch Year', _batchYears(), isRequired: true),
              _buildDropdownField(_genderController, 'Gender', _genderOptions, isRequired: true),
              _buildDropdownField(
                _maritalStatusController,
                'Marital Status',
                _maritalStatusOptions,
                isRequired: true,
              ),
              _buildDropdownField(
                _postingCategoryController,
                'Posting Category',
                _postingCategories,
                isRequired: true,
              ),
              _buildDropdownField(
                _postingWorkAsController,
                'Posting Work As',
                _postingWorkOptions,
                isRequired: true,
              ),
              _buildTextField(
                _whatsappController,
                'Whatsapp Number',
                isRequired: true,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                digitsOnly: true,
              ),
              _buildTextField(
                _callingNumberController,
                'Calling Contact No.',
                isRequired: true,
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
          _buildSummaryRow('Email', _emailController.text.trim()),
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
            _buildSummaryRow(
              'Village / Mohalla', _homeVillageMohallaController.text.trim()),
            _buildSummaryRow('Gali No.', _homeGaliNoController.text.trim()),
            _buildSummaryRow('Posting State', _postingStateController.text.trim()),
            _buildSummaryRow(
              'Posting District', _postingDistrictController.text.trim()),
            _buildSummaryRow(
              'Posting Police Station', _postingLocationController.text.trim()),
            _buildSummaryRow(
              'Posting GPS',
              _postingPlaceLocationController.text.trim().isEmpty
                  ? (_uploadPostingGpsLater
                      ? 'Will upload later'
                      : 'Not captured')
                  : 'Captured',
            ),
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
    final bottomPadding = safeBottom > 0 ? safeBottom + 8 : 16.0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.fromLTRB(20, 10, 20, bottomPadding),
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
    String? fieldId,
    bool isRequired = false,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    bool digitsOnly = false,
    bool readOnly = false,
    ValueChanged<String>? onChanged,
    VoidCallback? onTap,
  }) {
    final id = fieldId ?? label;
    return TextFormField(
      key: _fieldKey(id),
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      textInputAction: TextInputAction.next,
      maxLength: maxLength,
      inputFormatters: digitsOnly
          ? <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly]
          : null,
      onChanged: (value) {
        if (value.trim().isNotEmpty) {
          _clearFieldError(id);
        }
        onChanged?.call(value);
      },
      onTap: onTap,
      decoration: _fieldDecoration(
        label,
        isRequired: isRequired,
        hasError: _invalidFieldIds.contains(id),
      ),
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
    String? fieldId,
    bool isRequired = false,
    required Future<void> Function() onTap,
    String? hint,
  }) {
    final id = fieldId ?? label;
    return GestureDetector(
      key: _fieldKey(id),
      onTap: () async {
        await onTap();
        if (controller.text.trim().isNotEmpty) {
          _clearFieldError(id);
        }
      },
      child: AbsorbPointer(
        child: TextFormField(
          controller: controller,
          decoration: _fieldDecoration(label, isRequired: isRequired).copyWith(
            hintText: hint,
            suffixIcon: const Icon(Icons.arrow_drop_down_rounded),
            errorText: _invalidFieldIds.contains(id) ? 'Please check this field.' : null,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField(
    TextEditingController controller,
    String label,
    List<String> options,
    {String? fieldId, bool isRequired = false,}
  ) {
    final id = fieldId ?? label;
    final current = controller.text.trim();
    final selected = options.contains(current) ? current : null;
    return Padding(
      key: _fieldKey(id),
      padding: const EdgeInsets.only(bottom: 8),
      child: DropdownButtonFormField<String>(
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
            _clearFieldError(id);
          });
        },
        decoration: _fieldDecoration(
          label,
          isRequired: isRequired,
          hasError: _invalidFieldIds.contains(id),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(
    String label, {
    bool isRequired = false,
    bool hasError = false,
  }) {
    final labelText = isRequired ? '$label *' : label;
    return InputDecoration(
      labelText: labelText,
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
      errorText: hasError ? 'Please check this field.' : null,
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.4),
      ),
      counterText: '',
    );
  }

  GlobalKey _fieldKey(String fieldId) {
    return _fieldKeys.putIfAbsent(fieldId, () => GlobalKey());
  }

  void _clearFieldError(String fieldId) {
    if (!_invalidFieldIds.contains(fieldId)) {
      return;
    }
    setState(() {
      _invalidFieldIds.remove(fieldId);
    });
  }

  Future<void> _markInvalidFields(
    List<String> fieldIds,
    String firstMessage,
    {bool showMessage = true, bool scroll = true}
  ) async {
    setState(() {
      _invalidFieldIds
        ..clear()
        ..addAll(fieldIds);
    });
    if (showMessage) {
      _showMessage(firstMessage);
    }
    if (fieldIds.isEmpty || !scroll) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (!mounted) {
      return;
    }
    final context = _fieldKeys[fieldIds.first]?.currentContext;
    if (context != null) {
      await Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 250),
        alignment: 0.18,
      );
    }
  }

  void _syncOfficialNameFromIdentity(String value) {
    final fullName = value.trim();
    if (_officialNameEditedByUser && _officialNameController.text.trim().isNotEmpty) {
      return;
    }
    _officialNameController.value = TextEditingValue(
      text: fullName,
      selection: TextSelection.collapsed(offset: fullName.length),
    );
  }

  void _markOfficialNameEdited(String value) {
    _officialNameEditedByUser = value.trim().isNotEmpty;
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
      if (!await _validateIdentityStep()) {
        return;
      }
      final unique = await _ensureIdentityNotDuplicateInCloud();
      if (!unique) {
        return;
      }
      await _goToStep(1);
      return;
    }

    if (_currentStep == 1) {
      if (!_emailVerified) {
        _showMessage('Please verify your email OTP before continuing.');
        return;
      }
      await _goToStep(2);
      return;
    }

    if (_currentStep == 2) {
      if (!await _validateHomeStep()) {
        return;
      }
      await _goToStep(3);
      return;
    }

    if (_currentStep == 3) {
      if (!await _validatePostingStep()) {
        return;
      }
      await _goToStep(4);
      return;
    }

    if (_currentStep == 4) {
      if (!await _validateServiceStep()) {
        return;
      }
      await _goToStep(5);
      return;
    }

    if (_currentStep == 5) {
      if (!await _validateDocumentsStep()) {
        return;
      }
      await _goToStep(6);
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

    // First visit: auto-send OTP. Manual button appears only on send failure.
    if (step == 1 && !_emailVerified && !_emailOtpSent && !_sendingEmailOtp) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      if (mounted) {
        await _sendRegistrationEmailOtp();
      }
    }
  }

  Future<void> _previousStep() async {
    if (_currentStep == 0) {
      return;
    }
    await _goToStep(_currentStep - 1);
  }

  Future<bool> _validateIdentityStep({bool showFeedback = true}) async {
    final name = _nameController.text.trim();
    final mobile = _mobileController.text.trim();
    final mpin = _mpinController.text.trim();
    final email = _emailController.text.trim();
    final reference = _referenceController.text.trim();
    if (name.isEmpty || mobile.isEmpty || email.isEmpty || reference.isEmpty || mpin.isEmpty) {
      await _markInvalidFields(
        <String>[
          if (name.isEmpty) 'Full name',
          if (email.isEmpty) 'Email address',
          if (mobile.isEmpty) 'Mobile number',
          if (mpin.isEmpty) 'Create 6 digit M-PIN',
          if (reference.isEmpty) 'Reference member mobile number',
        ],
        'Enter full name, mobile number, email, M-PIN and reference mobile number.',
        showMessage: showFeedback,
        scroll: showFeedback,
      );
      return false;
    }
    if (!_namePattern.hasMatch(name)) {
      await _markInvalidFields(
        <String>['Full name'],
        'Enter a valid full name (letters and spaces only).',
        showMessage: showFeedback,
        scroll: showFeedback,
      );
      return false;
    }
    if (!_mobilePattern.hasMatch(mobile) || !_mobilePattern.hasMatch(reference)) {
      await _markInvalidFields(
        <String>[
          if (!_mobilePattern.hasMatch(mobile)) 'Mobile number',
          if (!_mobilePattern.hasMatch(reference)) 'Reference member mobile number',
        ],
        'Mobile numbers must be 10 digits.',
        showMessage: showFeedback,
        scroll: showFeedback,
      );
      return false;
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(email)) {
      await _markInvalidFields(
        <String>['Email address'],
        'Enter a valid email address.',
        showMessage: showFeedback,
        scroll: showFeedback,
      );
      return false;
    }
    if (mpin.length != 6 || !RegExp(r'^[0-9]{6}$').hasMatch(mpin)) {
      await _markInvalidFields(
        <String>['Create 6 digit M-PIN'],
        'M-PIN must be exactly 6 digits.',
        showMessage: showFeedback,
        scroll: showFeedback,
      );
      return false;
    }
    if (mobile == reference) {
      await _markInvalidFields(
        <String>['Reference member mobile number'],
        'Reference mobile must be different from member mobile.',
        showMessage: showFeedback,
        scroll: showFeedback,
      );
      return false;
    }
    if (widget.repository.findByMobile(mobile) != null) {
      await _markInvalidFields(
        <String>['Mobile number'],
        'Mobile number already registered.',
        showMessage: showFeedback,
        scroll: showFeedback,
      );
      return false;
    }
    if (widget.repository.findByEmail(email) != null) {
      await _markInvalidFields(
        <String>['Email address'],
        'Email already registered.',
        showMessage: showFeedback,
        scroll: showFeedback,
      );
      return false;
    }
    if (_referenceMember == null) {
      await _markInvalidFields(
        <String>['Reference member mobile number'],
        'Reference member could not be verified.',
        showMessage: showFeedback,
        scroll: showFeedback,
      );
      return false;
    }
    return true;
  }

  Future<bool> _ensureIdentityNotDuplicateInCloud() async {
    final mobile = _mobileController.text.trim();
    final email = _emailController.text.trim().toLowerCase();

    final byMobile = await widget.repository.fetchByMobileFromCloud(mobile);
    if (byMobile != null) {
      _showMessage('Mobile number already registered in system.');
      return false;
    }

    final byEmail = await widget.repository.fetchByEmailFromCloud(email);
    if (byEmail != null) {
      _showMessage('Email already registered in system.');
      return false;
    }
    return true;
  }

  Future<bool> _verifyRegistrationEmail() async {
    if (_emailVerified) {
      return true;
    }

    if (!_emailOtpSent) {
      await _markInvalidFields(<String>['Enter OTP'], 'Please send OTP first.');
      return false;
    }

    final enteredOtp = _emailOtpController.text.trim();
    if (enteredOtp.length != 6) {
      await _markInvalidFields(<String>['Enter OTP'], 'Enter valid 6 digit OTP.');
      return false;
    }

    final email = _emailController.text.trim();
    setState(() {
      _verifyingEmailOtp = true;
    });

    final verified = await _emailOtpService.verifyOtp(
      email: email,
      otp: enteredOtp,
    );

    if (!mounted) {
      return false;
    }

    setState(() {
      _verifyingEmailOtp = false;
    });

    if (!verified) {
      await _markInvalidFields(<String>['Enter OTP'], 'Invalid or expired email OTP.');
      return false;
    }

    setState(() {
      _emailVerified = true;
    });
    _showMessage('Email verified successfully.');
    return true;
  }

  Future<void> _sendRegistrationEmailOtp() async {
    final email = _emailController.text.trim();
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(email)) {
      _showMessage('Enter a valid email address first.');
      return;
    }

    setState(() {
      _sendingEmailOtp = true;
    });

    try {
      final dispatch = await _emailOtpService.sendVerificationOtp(
        email,
        purpose: EmailOtpPurpose.registration,
        memberName: _nameController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      if (!dispatch.success) {
        setState(() {
          _sendingEmailOtp = false;
          _showOtpSendButton = true;
        });
        _showMessage(dispatch.error ?? 'Unable to send email OTP.');
        return;
      }

      // Start resend countdown timer
      _otpResendTimer?.cancel();
      setState(() {
        _sendingEmailOtp = false;
        _emailOtpSent = true;
        _otpResendSeconds = 60;
        _showOtpSendButton = false;
      });

      _otpResendTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) {
          _otpResendTimer?.cancel();
          return;
        }
        setState(() {
          if (_otpResendSeconds > 0) {
            _otpResendSeconds--;
          } else {
            _otpResendTimer?.cancel();
          }
        });
      });

      _showMessage('OTP sent to $email');
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _sendingEmailOtp = false;
        _showOtpSendButton = true;
      });
      _showMessage('Unable to send email OTP right now. Please try again.');
    }
  }

  Future<bool> _validateHomeStep({bool showFeedback = true}) async {
    final homeDistrict = _homeDistrictController.text.trim();
    final homeVillageMohalla = _homeVillageMohallaController.text.trim();
    final homeGaliNo = _homeGaliNoController.text.trim();
    final homePoliceStation = _homePoliceStationController.text.trim();
    final homeTehsil = _homeTehsilController.text.trim();

    if (homeDistrict.isEmpty ||
        homeVillageMohalla.isEmpty ||
        homeGaliNo.isEmpty ||
        homePoliceStation.isEmpty ||
        homeTehsil.isEmpty) {
      await _markInvalidFields(
        <String>[
          if (homeDistrict.isEmpty) 'Home District',
          if (homeVillageMohalla.isEmpty) 'Village / Mohalla',
          if (homeGaliNo.isEmpty) 'Gali No.',
          if (homePoliceStation.isEmpty) 'Home Police Station',
          if (homeTehsil.isEmpty) 'Home Tehsil',
        ],
        'Complete all home details.',
        showMessage: showFeedback,
        scroll: showFeedback,
      );
      return false;
    }

    if (homeDistrict.length < 2) {
      await _markInvalidFields(
        <String>['Home District'],
        'Enter a valid home district.',
        showMessage: showFeedback,
        scroll: showFeedback,
      );
      return false;
    }

    return true;
  }

  Future<bool> _validatePostingStep({bool showFeedback = true}) async {
    final postingDistrict = _postingDistrictController.text.trim();
    final postingStation = _postingLocationController.text.trim();
    final postingGps = _postingPlaceLocationController.text.trim();

    if (postingDistrict.isEmpty || postingStation.isEmpty) {
      await _markInvalidFields(
        <String>[
          if (postingDistrict.isEmpty) 'Posting District',
          if (postingStation.isEmpty) 'Posting Police Station',
        ],
        'Complete all posting details.',
        showMessage: showFeedback,
        scroll: showFeedback,
      );
      return false;
    }

    if (postingDistrict.length < 2) {
      await _markInvalidFields(
        <String>['Posting District'],
        'Enter a valid posting district.',
        showMessage: showFeedback,
        scroll: showFeedback,
      );
      return false;
    }

    if (!_isAcceptableStationValue(postingStation)) {
      await _markInvalidFields(
        <String>['Posting Police Station'],
        'Enter a valid police station name.',
        showMessage: showFeedback,
        scroll: showFeedback,
      );
      return false;
    }

    if (postingGps.isEmpty && !_uploadPostingGpsLater) {
      await _markInvalidFields(
        <String>['Posting Place Location (Auto-fetched GPS)'],
        'Please fetch posting GPS location or choose Upload posting GPS later.',
        showMessage: showFeedback,
        scroll: showFeedback,
      );
      return false;
    }

    return true;
  }

  Future<bool> _validateServiceStep({bool showFeedback = true}) async {

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

    if (department.isEmpty ||
        postRank.isEmpty ||
        officialName.isEmpty ||
        batchYear.isEmpty ||
        gender.isEmpty ||
        maritalStatus.isEmpty ||
        postingCategory.isEmpty ||
        postingWorkAs.isEmpty ||
        whatsapp.isEmpty ||
        callingContact.isEmpty) {
      await _markInvalidFields(
        <String>[
          if (department.isEmpty) 'Sub Department',
          if (postRank.isEmpty) 'Rank',
          if (officialName.isEmpty) 'Official Name',
          if (batchYear.isEmpty) 'Batch Year',
          if (gender.isEmpty) 'Gender',
          if (maritalStatus.isEmpty) 'Marital Status',
          if (postingCategory.isEmpty) 'Posting Category',
          if (postingWorkAs.isEmpty) 'Posting Work As',
          if (whatsapp.isEmpty) 'Whatsapp Number',
          if (callingContact.isEmpty) 'Calling Contact No.',
        ],
        'Complete all posting details.',
        showMessage: showFeedback,
        scroll: showFeedback,
      );
      return false;
    }

    if (postRank == 'Other' && customRank.isEmpty) {
      await _markInvalidFields(
        <String>['Enter rank name'],
        'Please enter rank when you select Other.',
        showMessage: showFeedback,
        scroll: showFeedback,
      );
      return false;
    }

    if (!_namePattern.hasMatch(officialName)) {
      await _markInvalidFields(
        <String>['Official Name'],
        'Enter a valid official name.',
        showMessage: showFeedback,
        scroll: showFeedback,
      );
      return false;
    }

    final currentYear = DateTime.now().year;
    final batch = int.tryParse(batchYear);
    if (!_yearPattern.hasMatch(batchYear) ||
        batch == null ||
        batch < 1970 ||
        batch > currentYear) {
      await _markInvalidFields(
        <String>['Batch Year'],
        'Enter a valid batch year.',
        showMessage: showFeedback,
        scroll: showFeedback,
      );
      return false;
    }

    if (!_mobilePattern.hasMatch(whatsapp) ||
        !_mobilePattern.hasMatch(callingContact)) {
      await _markInvalidFields(
        <String>[
          if (!_mobilePattern.hasMatch(whatsapp)) 'Whatsapp Number',
          if (!_mobilePattern.hasMatch(callingContact)) 'Calling Contact No.',
        ],
        'Complete all posting details with valid phone numbers.',
        showMessage: showFeedback,
        scroll: showFeedback,
      );
      return false;
    }

    return true;
  }

  bool _isAcceptableStationValue(String value) {
    final trimmed = value.trim();
    if (trimmed.length < 3) {
      return false;
    }
    return RegExp(r"^[A-Za-z0-9 .,'()/-]{3,}$").hasMatch(trimmed);
  }

  Future<bool> _validateDocumentsStep({bool showFeedback = true}) async {
    if (_selfie == null) {
      await _markInvalidFields(
        <String>['Selfie photo'],
        'Upload selfie to continue.',
        showMessage: showFeedback,
        scroll: showFeedback,
      );
      return false;
    }
    return true;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submit() async {
    if (!await _validateIdentityStep(showFeedback: false)) {
      await _goToStep(0);
      await _validateIdentityStep();
      return;
    }
    if (!_emailVerified) {
      await _goToStep(1);
      _showMessage('Please verify your email before submitting registration.');
      return;
    }
    if (!await _validateHomeStep(showFeedback: false)) {
      await _goToStep(2);
      await _validateHomeStep();
      return;
    }
    if (!await _validatePostingStep(showFeedback: false)) {
      await _goToStep(3);
      await _validatePostingStep();
      return;
    }
    if (!await _validateServiceStep(showFeedback: false)) {
      await _goToStep(4);
      await _validateServiceStep();
      return;
    }
    if (!await _validateDocumentsStep(showFeedback: false)) {
      await _goToStep(5);
      await _validateDocumentsStep();
      return;
    }

    final unique = await _ensureIdentityNotDuplicateInCloud();
    if (!unique) {
      await _goToStep(0);
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
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
          email: _emailController.text.trim(),
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
        pendingUpdatePayload: jsonEncode(<String, dynamic>{
          'biometricEnabled': _biometricVerified,
        }),
        homeVillageMohalla: _homeVillageMohallaController.text.trim(),
        homeGaliNo: _homeGaliNoController.text.trim(),
        homePostOffice: '',
        homePoliceStation: _homePoliceStationController.text.trim(),
        homeTehsil: _homeTehsilController.text.trim(),
        homeVillageLocation: '',
        appointmentDate: now,
        role: 'Member',
        lastUpdated: now,
        passwordUpdatedAt: now,
        isApproved: false,
      );
      final saved = await widget.repository.saveMember(member);

      if (!saved) {
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
      Navigator.of(context).pop(member);
    } catch (error) {
      _showMessage('Registration failed due to invalid or incomplete data: $error');
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
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
    // Generate all years from current year down to 1970 (includes current year)
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
        _uploadPostingGpsLater = false;
      });
      _showMessage('Posting location captured.');
    } catch (_) {
      _showMessage('Unable to capture location right now. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _capturingPostingLocation = false;
        });
      }
    }
  }

}
